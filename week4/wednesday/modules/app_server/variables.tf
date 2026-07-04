variable "name" {
  description = "Logical server name used to derive resource Name tags and the security group name (e.g. api, payments, logs)"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for this server"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Deployment environment: staging or production"
  type        = string

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}

variable "ami_id" {
  description = "AMI ID to launch the instance from"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair to attach to the instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance into"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID the security group belongs to"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the server (your IP, not 0.0.0.0/0)"
  type        = string
}
