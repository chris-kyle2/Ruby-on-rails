output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value = aws_instance.bastion_host.public_ip
}

output "master_private_ip" {
  value = aws_instance.k8s_master.private_ip
}

output "worker_private_ips" {
  value = [for i in aws_instance.k8s_workers : "${i.tags.Name}-${i.private_ip}"]
}
