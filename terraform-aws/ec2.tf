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

# ─── SSH Key Pair ─────────────────────────────────────────────────────────────

resource "aws_key_pair" "app" {
  key_name   = "${var.app_name}-key"
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# ─── EC2 Instance ─────────────────────────────────────────────────────────────

resource "aws_instance" "app" {
  ami                    = data.aws_ami.al2023_arm.id
  instance_type          = "t4g.nano"
  key_name               = aws_key_pair.app.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]
  availability_zone      = "${var.aws_region}a"

  maintenance_options {
    auto_recovery = "default"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
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

  user_data_replace_on_change = true

  tags = {
    Name = var.app_name
  }
}

# ─── Elastic IP ───────────────────────────────────────────────────────────────

resource "aws_eip" "app" {
  instance   = aws_instance.app.id
  domain     = "vpc"
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "${var.app_name}-eip"
  }
}
