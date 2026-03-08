# ─── IAM Role for AWS Backup ──────────────────────────────────────────────────

resource "aws_iam_role" "backup" {
  name = "${var.app_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "backup.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.app_name}-backup-role"
  }
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_iam_role_policy_attachment" "backup_restore" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
}

# ─── Backup Vault ─────────────────────────────────────────────────────────────
# Stores all recovery points. Encrypted at rest.

resource "aws_backup_vault" "postgres" {
  name = "${var.app_name}-postgres-vault"

  tags = {
    Name = "${var.app_name}-postgres-vault"
  }
}

# ─── Backup Plan ──────────────────────────────────────────────────────────────

resource "aws_backup_plan" "postgres" {
  name = "${var.app_name}-postgres-backup-plan"

  rule {
    rule_name         = "hourly-backups"
    target_vault_name = aws_backup_vault.postgres.name
    schedule          = "cron(0 * * * ? *)"   # every hour on the hour

    # Keep only the last 2 days of hourly backups (48 recovery points)
    lifecycle {
      delete_after = 2
    }

    recovery_point_tags = {
      Name = "${var.app_name}-postgres-backup"
    }
  }

  rule {
    rule_name         = "daily-backups"
    target_vault_name = aws_backup_vault.postgres.name
    schedule          = "cron(0 2 * * ? *)"   # every day at 2am UTC

    # Keep daily backups for 7 days
    lifecycle {
      delete_after = 7
    }

    recovery_point_tags = {
      Name = "${var.app_name}-postgres-daily-backup"
    }
  }

  tags = {
    Name = "${var.app_name}-postgres-backup-plan"
  }
}

# ─── Backup Selection ─────────────────────────────────────────────────────────
# Targets the PostgreSQL EBS volume by its resource ARN.

resource "aws_backup_selection" "postgres" {
  name         = "${var.app_name}-postgres-ebs"
  plan_id      = aws_backup_plan.postgres.id
  iam_role_arn = aws_iam_role.backup.arn

  resources = [
    aws_ebs_volume.postgres.arn
  ]
}
