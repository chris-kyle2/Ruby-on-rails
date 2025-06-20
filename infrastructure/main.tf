terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
resource "tls_private_key" "devops_kp" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content              = tls_private_key.devops_kp.private_key_pem
  filename             = "/Users/adarshpandey/Desktop/makerble/infrastructure/devops-kp.pem"
  file_permission      = "0600"
}

resource "aws_key_pair" "devops_kp" {
  key_name   = "devops-kp"
  public_key = tls_private_key.devops_kp.public_key_openssh
}

resource "aws_security_group" "k8s_nodes" {
  name        = "k8s-nodes-sg"
  description = "Security group for Kubernetes nodes"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-nodes-sg"
  }
}

# EC2 Instance for K8s Master
resource "aws_instance" "k8s_master" {
  ami           = var.ami_id
  instance_type = var.master_instance_type
  key_name      = aws_key_pair.devops_kp.key_name

  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]

  root_block_device {
    volume_size = 20
  }
  tags = {
    Name = "k8s-master"
    Role = "master"
  }

}

# EC2 Instances for K8s Workers
resource "aws_instance" "k8s_workers" {
  count         = var.worker_count
  ami           = var.ami_id
  instance_type = var.worker_instance_type
  key_name      = aws_key_pair.devops_kp.key_name

  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]

  root_block_device {
    volume_size = 10
  }

 tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
} 
resource "aws_security_group_rule" "ssh_rule" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_nodes.id
}
