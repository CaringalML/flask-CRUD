# ─── EBS Volume (persists SQLite across instance terminations) ────────────────

resource "aws_ebs_volume" "db" {
  availability_zone = "${var.aws_region}a"
  size              = var.db_volume_size_gb
  type              = "gp3"
  encrypted         = true

  lifecycle {
    prevent_destroy = false   # Protects SQLite data from accidental terraform destroy
  }

  tags = {
    Name = "${var.app_name}-db"
  }
}

resource "aws_volume_attachment" "db" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.db.id
  instance_id  = aws_instance.app.id
  force_detach = true
}
