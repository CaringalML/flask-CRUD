# ─── IAM Role for EC2 → CloudWatch ───────────────────────────────────────────

resource "aws_iam_role" "ec2_cloudwatch" {
  name = "${var.app_name}-ec2-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = {
    Name = "${var.app_name}-ec2-cloudwatch-role"
  }
}

# ─── Attach AWS managed CloudWatch agent policy ────────────────────────────────

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.ec2_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# ─── Instance Profile (attaches IAM role to EC2) ─────────────────────────────

resource "aws_iam_instance_profile" "ec2_cloudwatch" {
  name = "${var.app_name}-ec2-cloudwatch-profile"
  role = aws_iam_role.ec2_cloudwatch.name
}

# ─── CloudWatch Log Groups ────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.app_name}/app"
  retention_in_days = 7   # auto-delete logs older than 7 days

  tags = {
    Name = "${var.app_name}-app-logs"
  }
}

resource "aws_cloudwatch_log_group" "nginx" {
  name              = "/${var.app_name}/nginx"
  retention_in_days = 7

  tags = {
    Name = "${var.app_name}-nginx-logs"
  }
}

resource "aws_cloudwatch_log_group" "bootstrap" {
  name              = "/${var.app_name}/bootstrap"
  retention_in_days = 7

  tags = {
    Name = "${var.app_name}-bootstrap-logs"
  }
}
