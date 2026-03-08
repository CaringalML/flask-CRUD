output "public_ip" {
  description = "Elastic IP — point your domain A record here"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "Flask app URL"
  value       = "http://${aws_eip.app.public_ip}"
}

output "pgadmin_url" {
  description = "pgAdmin web UI URL"
  value       = "http://${aws_eip.app.public_ip}:${var.pgadmin_port}"
}

output "ssh_command" {
  description = "SSH into the instance"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_eip.app.public_ip}"
}

output "bootstrap_log" {
  description = "Check first boot log"
  value       = "sudo cat /var/log/user_data.log"
}

output "view_logs" {
  description = "Tail all container logs"
  value       = "cd /app && docker-compose logs -f"
}

output "postgres_logs" {
  description = "Tail PostgreSQL container logs only"
  value       = "docker logs -f postgres"
}

output "backup_vault_arn" {
  description = "AWS Backup vault ARN for the PostgreSQL EBS volume"
  value       = aws_backup_vault.postgres.arn
}
