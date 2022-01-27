output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.kubeadm-node.*.arn
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value = "${join(",", aws_instance.kubeadm-node.*.public_ip)}\n"
}
output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value = "${join(",", aws_instance.kubeadm-node.*.private_ip)}"
}


output "ssh_to_master" {
  value = "ssh -i ${var.private_key_location} ubuntu@${element((aws_instance.kubeadm-node.*.public_ip),0)}"
}

output "ssh_to_worker1" {
  value = "ssh -i ${var.private_key_location} ubuntu@${element((aws_instance.kubeadm-node.*.public_ip),1)}"
}

output "ssh_to_worker2" {
  value = "ssh -i ${var.private_key_location} ubuntu@${element((aws_instance.kubeadm-node.*.public_ip),2)}"
}