terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Optional cloud path (see environment-setup.md): remote backend is AWS S3
  # with native state locking (use_lockfile, Terraform 1.10+), so no DynamoDB
  # lock table is required. The primary/Multipass path in this course uses a
  # local MinIO backend instead, which does not support native locking - see
  # hardening-decisions.md for how that limitation is addressed in production.
  backend "s3" {
    bucket       = "kijanikiosk-tfstate-493627063797-ap-south-1"
    key          = "week4/friday/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "default" {
  default = true
}

locals {
  servers = {
    api = {
      instance_type = var.instance_type
    }
    payments = {
      instance_type = var.instance_type
    }
    logs = {
      # t3.micro is the smallest free-tier-eligible type for our x86_64 AMI
      # (t4g.micro is smaller but requires an arm64 AMI).
      instance_type = var.instance_type
    }
  }
}

module "app_servers" {
  source   = "./modules/app_server"
  for_each = local.servers

  name             = each.key
  instance_type    = each.value.instance_type
  environment      = var.environment
  ami_id           = data.aws_ami.ubuntu.id
  key_name         = var.ssh_key_name
  subnet_id        = var.subnet_id
  vpc_id           = data.aws_vpc.default.id
  allowed_ssh_cidr = var.allowed_ssh_cidr
}
