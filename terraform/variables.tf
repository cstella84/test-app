variable "app_name" {
  description = "Name of the application"
  type        = string
}

variable "app_type" {
  description = "Application framework type"
  type        = string
  default     = "nextjs"
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the instance"
  type        = string
}

variable "ssh_private_key" {
  description = "Private SSH key for accessing the instance"
  type        = string
  sensitive   = true
}