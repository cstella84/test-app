terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

# Retrieve the latest AMI ID for our hardened image
data "aws_ami" "hardened_ami" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["hardened-base-*"]
  }
  
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Create VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"
  
  name = "${var.app_name}-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["${var.aws_region}a", "${var.aws_region}b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true
  
  tags = {
    Terraform   = "true"
    Environment = var.environment
    Application = var.app_name
  }
}

# Security groups
resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Security group for ${var.app_name} application"
  vpc_id      = module.vpc.vpc_id
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, this should be restricted
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name        = "${var.app_name}-sg"
    Environment = var.environment
  }
}

# EC2 Instance
resource "aws_instance" "app_server" {
  ami                    = data.aws_ami.hardened_ami.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = var.key_name
  
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }
  
  tags = {
    Name        = "${var.app_name}-server"
    Environment = var.environment
    Application = var.app_name
    AppType     = var.app_type
  }
  
  # This provisioner will execute the appropriate Ansible playbook
  provisioner "local-exec" {
    command = <<-EOT
      ansible-playbook \
        -i '${self.public_ip},' \
        -e "app_name=${var.app_name} app_type=${var.app_type} node_version=18 server_name=${self.public_ip}" \
        ../ansible/deploy.yml
    EOT
  }
}

# Elastic IP for the instance
resource "aws_eip" "app_eip" {
  instance = aws_instance.app_server.id
  domain   = "vpc"
  
  tags = {
    Name        = "${var.app_name}-eip"
    Environment = var.environment
  }
}

# Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.app_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.app_eip.public_ip
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.app_eip.public_ip}"
}