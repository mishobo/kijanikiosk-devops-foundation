variable "aws_region" {
  description = "AWS region to deploy infrastructure into"
  type        = string
  default     = "ap-south-1" # Mumbai - closest to Nairobi with EC2 free tier
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

variable "subnet_id" {
  description = "Subnet ID to launch application servers into (pinned so the pre-existing api instance is not force-replaced during the module refactor)"
  type        = string
  default     = "subnet-038fa4e0117c92a82"
}
