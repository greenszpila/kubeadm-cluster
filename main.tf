# tf script to deploy K8s kubeadm cluster including:
# three ec2 instances, security groups, ansible inventory file and executing two ansible playbooks.

# generate random pet string used for naming uniquely aws resources such as security groups and the ec2 instances. This is to avoid using the same security group and the ec2 instance names.
resource "random_pet" "security-group" {}

# definie basic security riles to allow kubernetes traffic
resource "aws_security_group" "kubernetes-traffic" {
  name = "${random_pet.security-group.id}-kubernetes-traffic"
  description = "Allow Kubernetes,HTTP, HTTPS and SSH traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Kubernetes"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow incoming traffic from the Pods of the cluster"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.244.0.0/16"]
  }

  ingress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    self        = true
    description = "Allow incoming traffic from cluster nodes"
  }

  tags = {
    Name = "kubeadm"
  }
}

# search for latest oficcial ubuntu image, this helps to make it easier when deploying instances in other regions
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
  
# deploy three or more (depending on count value) ec2 instances, one master and two worker nodes
resource "aws_instance" "kubeadm-node" {
  count = 3
  key_name = var.ami_key_pair_name
  tags = {
    Name = "kubeadm-node-${random_pet.security-group.id}-${count.index}"
         }
  ami           = data.aws_ami.ubuntu.id
                  # "ami-0b9064170e32bde34" # ubuntu 18.04 in us-east-2
                  # "ami-0943382e114f188e8" #        18.04 in eu-west-1
  instance_type = var.ec2_instance_type

  
# remote-exec to run the commands on all instances, it configures the network settings.
# this option could also be uses to configure the cluster instead of ansible plabooks.
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file(var.private_key_location)}"
      host = "${self.public_ip}"
      timeout     = "2m"
    }
    inline = [
    "sudo apt update",
    "echo \"net.bridge.bridge-nf-call-iptables=1\" | sudo tee -a /etc/sysctl.conf",
    "sudo modprobe br_netfilter",
    "sudo sysctl -p",
    ]
  }

  vpc_security_group_ids = [
    aws_security_group.kubernetes-traffic.id
  ]

}
# create Ansible inventory hosts file 
resource "local_file" "ansible_inventory" {
 
  filename              = "./hosts"
  file_permission       = "0664"
  directory_permission  = "0755"
  content               = <<-EOT
    [kubemaster]
    master ansible_host=${element((aws_instance.kubeadm-node.*.public_ip),0)}
    [kubeworkers]
    ${element((aws_instance.kubeadm-node.*.public_ip),1)}
    ${element((aws_instance.kubeadm-node.*.public_ip),2)}
    [all:vars]
    ansible_ssh_common_args='-o StrictHostKeyChecking=no'
  EOT
}

# null resource to run the ansible playbooks to configure the kubeadm cluster
resource "null_resource" "kubeadm-node"  {

triggers = {
    cluster_instance_ids = join(",", aws_instance.kubeadm-node.*.id)
  }
  connection {
    host = element(aws_instance.kubeadm-node.*.public_ip, 0)
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i hosts --user=ubuntu --private-key ${var.private_key_location} kube-install.yml"
  }
  provisioner "local-exec" {
    command = "ansible-playbook  -i hosts --user=ubuntu --private-key ${var.private_key_location} setup-cluster.yml"
  }
}