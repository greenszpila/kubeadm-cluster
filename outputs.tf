output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.kubeadm-node.*.arn
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  #value       = aws_instance.kubeadm-node[count.index].public_ip
  value = "${join(",", aws_instance.kubeadm-node.*.public_ip)}"
}
