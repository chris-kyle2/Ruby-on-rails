output "master_public_ip" {
  description = "Public IP address of the Kubernetes master node"
  value       = aws_instance.k8s_master.public_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the Kubernetes worker nodes"
  value       = aws_instance.k8s_workers[*].public_ip
}


output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.k8s_nodes.id
} 