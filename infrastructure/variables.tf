variable "aws_region" {
  description = "AWS region to deploy the infrastructure"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances (Ubuntu 22.04 LTS)"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for Kubernetes master node"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for Kubernetes worker nodes"
  type        = string
  default     = "t3.small"
}



variable "worker_count" {
  description = "Number of worker nodes to create"
  type        = number
  default     = 2
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}