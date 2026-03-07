# ─── IAM Role for CloudWatch Agent ───────────────────────────────────────────

resource "aws_iam_role" "cloudwatch" {
  name = "${var.app_name}-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.app_name}-cloudwatch-role"
  }
}

resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "cloudwatch" {
  name = "${var.app_name}-cloudwatch-profile"
  role = aws_iam_role.cloudwatch.name
}

# ─── CloudWatch Log Groups ────────────────────────────────────────────────────

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.app_name}/app"
  retention_in_days = 7

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
