# ─── EBS Volume for PostgreSQL data ──────────────────────────────────────────
# Persists database across instance terminations and redeployments.
# Attached at /dev/xvdf → mounted to /data/postgres inside the instance.

resource "aws_ebs_volume" "postgres" {
  availability_zone = "${var.aws_region}a"
  size              = var.db_volume_size_gb
  type              = "gp3"
  encrypted         = true

  # Prevents accidental deletion of client data via terraform destroy
  lifecycle {
    prevent_destroy = true
  }

  tags = {
    Name = "${var.app_name}-postgres-data"
  }
}

resource "aws_volume_attachment" "postgres" {
  device_name  = "/dev/xvdf"
  volume_id    = aws_ebs_volume.postgres.id
  instance_id  = aws_instance.app.id
  force_detach = true
}
