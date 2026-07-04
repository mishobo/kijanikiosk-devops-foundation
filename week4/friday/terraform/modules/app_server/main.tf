resource "aws_instance" "this" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name        = "kijanikiosk-${var.name}-${var.environment}"
    Service     = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "app" {
  name        = "kijanikiosk-${var.name}-${var.environment}"
  description = "Allow SSH from an allow-listed IP only"
  vpc_id      = var.vpc_id

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

  tags = {
    Name        = "kijanikiosk-${var.name}-${var.environment}"
    Service     = var.name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
