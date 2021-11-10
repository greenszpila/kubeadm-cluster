output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.kubeadm-node.*.arn
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  #value       = aws_instance.kubeadm-node[count.index].public_ip
  value = "${join(",", aws_instance.kubeadm-node.*.public_ip)}"
}

output "ssh_to_master" {
  value = "ssh -i ${var.ami_key_pair_name}.pem ubuntu@${element((aws_instance.kubeadm-node.*.public_ip),0)}"
}

output "ssh_to_worker1" {
  value = "ssh -i ${var.ami_key_pair_name}.pem ubuntu@${element((aws_instance.kubeadm-node.*.public_ip),1)}"
}

output "ssh_to_worker2" {
  value = "ssh -i ${var.ami_key_pair_name}.pem ubuntu@${element((aws_instance.kubeadm-node.*.public_ip),2)}"
}