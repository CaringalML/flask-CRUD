# ─── App Security Group (HTTP + HTTPS + SSH) ─────────────────────────────────

resource "aws_security_group" "app" {
  name        = "${var.app_name}-app-sg"
  description = "Allow HTTP and SSH inbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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

  tags = {
    Name = "${var.app_name}-app-sg"
  }
}

# ─── pgAdmin Security Group (restricted port) ─────────────────────────────────
# pgAdmin is exposed on port 5050 — restrict to your IP in production

resource "aws_security_group" "pgadmin" {
  name        = "${var.app_name}-pgadmin-sg"
  description = "Allow pgAdmin web UI access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "pgAdmin UI"
    from_port   = var.pgadmin_port
    to_port     = var.pgadmin_port
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr] # Restrict to your IP — same as SSH
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-pgadmin-sg"
  }
}

# ─── PostgreSQL Security Group (internal only) ────────────────────────────────
# PostgreSQL is NOT exposed to the internet — only accessible from the app SG

resource "aws_security_group" "postgres" {
  name        = "${var.app_name}-postgres-sg"
  description = "Allow PostgreSQL access from app only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-postgres-sg"
  }
}
