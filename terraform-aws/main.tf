terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = var.aws_region
}

# ─── Latest Amazon Linux 2023 ARM64 AMI ──────────────────────────────────────

data "aws_ami" "al2023_arm" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-arm64"]
  }
  filter {
    name   = "architecture"
    values = ["arm64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ─── Security Group ───────────────────────────────────────────────────────────

resource "aws_security_group" "app_sg" {
  name        = "${var.app_name}-sg"
  description = "Allow HTTP and SSH"

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-sg" }
}

# ─── SSH Key Pair ─────────────────────────────────────────────────────────────

resource "aws_key_pair" "app_key" {
  key_name   = "${var.app_name}-key"
  public_key = file(var.ssh_public_key_path)
}

# ─── EBS Volume (persists SQLite across deploys) ──────────────────────────────

resource "aws_ebs_volume" "db" {
  availability_zone = "${var.aws_region}a"
  size              = var.db_volume_size_gb
  type              = "gp3"
  encrypted         = true

  # IMPORTANT: prevent accidental deletion of client data
  lifecycle {
    prevent_destroy = true
  }

  tags = { Name = "${var.app_name}-db" }
}

resource "aws_volume_attachment" "db" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.db.id
  instance_id  = aws_instance.app.id
  force_detach = true
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023_arm.id
  instance_type          = "t4g.nano"
  key_name               = aws_key_pair.app_key.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  availability_zone      = "${var.aws_region}a"

  maintenance_options {
    auto_recovery = "default"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
  }

  user_data = templatefile("${path.module}/user_data.sh", {
    docker_image   = var.docker_image
    flask_env      = var.flask_env
    secret_key     = var.flask_secret_key
    db_mount_point = "/data"
    db_device      = "/dev/xvdf"
  })

  # Recreate instance when user_data changes (e.g. new image tag)
  user_data_replace_on_change = true

  tags = { Name = var.app_name }
}

# ─── Elastic IP ───────────────────────────────────────────────────────────────

resource "aws_eip" "app" {
  instance   = aws_instance.app.id
  domain     = "vpc"
  depends_on = [aws_instance.app]

  tags = { Name = "${var.app_name}-eip" }
}
