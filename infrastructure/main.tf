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
resource "aws_vpc" "rails_app_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "rails-app-vpc"
  }
}
resource "aws_subnet" "rails_app_subnet" {
  for_each                = var.subnets
  vpc_id                  = aws_vpc.rails_app_vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.az
  map_public_ip_on_launch = each.value.map_public_ip

  tags = {
    Name = each.key
  }
}


resource "aws_security_group" "k8s_nodes" {
  name        = "k8s-nodes-sg"
  description = "Security group for Kubernetes nodes"
  vpc_id      = aws_vpc.rails_app_vpc.id

  ingress {
    description = "Allow all internal traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }
  ingress {
    description              = "Allow SSH access to private nodes from Bastion host"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    security_groups          = [aws_security_group.ssh_sg.id]
  }
   ingress {
    description              = "Allow port range on master node"
    from_port                = 30000
    to_port                  = 32767
    protocol                 = "tcp"
    security_groups          = [aws_security_group.ssh_sg.id]
  }
    ingress {
    description              = "Allow Kube API access to private nodes from Bastion host"
    from_port                = 6443
    to_port                  = 6443
    protocol                 = "tcp"
    security_groups          = [aws_security_group.ssh_sg.id]
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
  subnet_id = aws_subnet.rails_app_subnet["private-master-subnet"].id

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
  subnet_id = aws_subnet.rails_app_subnet["private-worker-subnet"].id
  vpc_security_group_ids = [aws_security_group.k8s_nodes.id]
  associate_public_ip_address = false

 root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }


 tags = {
    Name = "k8s-worker-${count.index + 1}"
    Role = "worker"
  }
} 
resource "aws_instance" "bastion_host" {
  ami = var.ami_id
  instance_type = "t3.medium"
  key_name = aws_key_pair.devops_kp.key_name
  subnet_id = aws_subnet.rails_app_subnet["public-subnet"].id
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  associate_public_ip_address = true
  root_block_device {
    volume_size = 15
    volume_type = "gp3"
  }
  tags = {
    Name = "bastion-host"
  }
}
resource "aws_security_group" "ssh_sg" {
  name = "ssh-sg"
  description = "Allow SSH access"
  vpc_id = aws_vpc.rails_app_vpc.id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "ssh-sg"
  }
}


resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.rails_app_vpc.id

  tags = {
    Name = "rails-app-igw"
  }
}
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "rails-app-nat-eip"
  }
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.rails_app_subnet["public-subnet"].id

  tags = {
    Name = "rails-app-nat-gateway"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.rails_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rails-app-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.rails_app_subnet["public-subnet"].id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.rails_app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "rails-app-private-rt"
  }
}

resource "aws_route_table_association" "private_master_assoc" {
  subnet_id      = aws_subnet.rails_app_subnet["private-master-subnet"].id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_worker_assoc" {
  subnet_id      = aws_subnet.rails_app_subnet["private-worker-subnet"].id
  route_table_id = aws_route_table.private_rt.id
}
