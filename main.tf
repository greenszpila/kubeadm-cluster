/*resource random_pet security-group {
  length    = length
  prefix    = ""
  separator = ""

  keepers = {
    id = value
  }
}
*/

locals {
  ssh_user         = "ubuntu"
  key_name         = "kriss"
  private_key_path = "~/coding/kriss.pem"
}
resource "random_pet" "security-group" {}


resource "aws_security_group" "remote-allow" {
  name = "${random_pet.security-group.id}-allow"
  //name        = "remote-allow-security-group"
  description = "Allow HTTP, HTTPS and SSH traffic"

/*
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
  */
  ingress {
    description = "All"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform"
  }
}


data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    #values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}
output "ip" {
  value = "${join(",", aws_instance.kubeadm-node.*.public_ip)}" 
  }
  
resource "null_resource" "ConfigureAnsibleLabelVariable" {
  
  provisioner "local-exec" {
    command = "echo [kubemaster] >> hosts"
  }
  
}

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

  

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key = "${file(var.private_key_location)}"
      #private_key = "${file("~/coding/kriss.pem")}"
      #host     = aws_instance.kubeadm-node[count.index].public_ip
      #host     = "${aws_instance.kubeadm-node[count.index].public_ip}"
      #host = element(aws_instance.kubeadm-node.*.public_ip, count.index)
      #host     = "${element(aws_instance.kubeadm-node.*.public_ip, count.index)}"
      host = "${self.public_ip}"
      #host = aws_instance.kubeadm-node.*.arn
      #host     = aws_instance.kubeadm-node.public_ip
      timeout     = "2m"
    }
    inline = [
    "sudo apt update",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
    "sudo add-apt-repository	\"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
    "curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -",
    "cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list",
    "deb https://apt.kubernetes.io/ kubernetes-xenial main",
    "EOF",
    "sudo apt update",
    #"sudo apt-get install -y docker-ce=5:19.03.12~3-0~ubuntu-bionic kubelet=1.19.4-00 kubeadm=1.19.4-00 kubectl=1.19.4-00",
    "sudo apt-get install -y docker-ce=5:19.03.12~3-0~ubuntu-bionic kubelet=1.19.4-00 kubeadm=1.19.4-00",
    #"sudo apt-mark hold docker-ce kubelet kubeadm kubectl",
    "sudo apt-mark hold docker-ce kubelet kubeadm",
    "echo \"net.bridge.bridge-nf-call-iptables=1\" | sudo tee -a /etc/sysctl.conf",
    # modprobe br_netfilter optional to fix "sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file or directory"
    "sudo modprobe br_netfilter",
    "sudo sysctl -p",
    ]
  }


  #tags = {
  #  Name = "krs-tf-nr1"
  #}

  vpc_security_group_ids = [
    aws_security_group.remote-allow.id
  ]

}

resource "null_resource" "kubeadm-node"  {

triggers = {
    cluster_instance_ids = join(",", aws_instance.kubeadm-node.*.id)
  }
  connection {
    host = element(aws_instance.kubeadm-node.*.public_ip, 0)
  }

  provisioner "local-exec" {
    command = "echo master ansible_host=${element((aws_instance.kubeadm-node.*.public_ip),0)} >> hosts"
  }
  provisioner "local-exec" {
    command = "echo [kubeworkers] >> hosts"
  }
  provisioner "local-exec" {
    command = "echo ${element((aws_instance.kubeadm-node.*.public_ip),1)} >> hosts"
  }
  provisioner "local-exec" {
    command = "echo ${element((aws_instance.kubeadm-node.*.public_ip),2)} >> hosts"
  }  

  provisioner "local-exec" {
    #command = "ansible all -m shell -a 'sudo apt update; sudo apt-get install -y docker-ce=5:19.03.12~3-0~ubuntu-bionic kubelet=1.19.4-00 kubeadm=1.19.4-00 kubectl=1.19.4-00'"
    #command = "ansible-playbook  -i ${element((aws_instance.kubeadm-node.*.public_ip),0)}, --private-key ${local.private_key_path} setup-cluster.yml"
    command = "ansible-playbook  -i hosts --user=ubuntu --private-key ${local.private_key_path} setup-cluster.yml"
  }

}