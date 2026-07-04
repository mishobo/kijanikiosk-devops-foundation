terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
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
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-resolute-26.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "kk_api" {
  name        = "kijanikiosk-api-${var.environment}"
  description = "Allow SSH from an allow-listed IP only"

  ingress {
    description = "SSH from allow-listed IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "kijanikiosk-api-${var.environment}", Environment = var.environment, Owner = "amina" }
}

resource "aws_instance" "kk_api" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.kk_api.id]
  tags                   = { Name = "kijanikiosk-api-${var.environment}", Environment = var.environment, Owner = "amina" }
}

resource "null_resource" "kijanikiosk_api" {
  triggers = { instance_id = aws_instance.kk_api.id }

  connection {
    type        = "ssh"
    host        = aws_instance.kk_api.public_ip
    user        = "ubuntu"
    private_key = file(pathexpand("~/.ssh/aws-moringa.pem"))
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Connected to kijanikiosk-api (${var.environment})'",
      "uname -a"
    ]
  }
}