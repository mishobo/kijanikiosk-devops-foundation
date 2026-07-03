variable "aws_region" {
  description = "AWS region to deploy infrastructure into"
  type        = string
  default     = "eu-west-1"    # Frankfurt - closest to Nairobi with EC2 free tier
}

variable "instance_type" {
  description = "EC2 instance type for KijaniKiosk application servers"
  type        = string
  default     = "t3.micro"
}

variable "environment" {
  description = "Deployment environment: staging or production"
  type        = string
  default     = "staging"

  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Environment must be staging or production."
  }
}

variable "ssh_key_name" {
  description = "Name of the SSH key pair to attach to instances"
  type        = string
  # No default: this must be provided explicitly per environment
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the API server (your IP, not 0.0.0.0/0)"
  type        = string
  # No default: this must be provided explicitly per environment
}