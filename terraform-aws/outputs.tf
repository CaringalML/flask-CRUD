output "public_ip" {
  description = "Elastic IP — point your domain A record here when ready"
  value       = aws_eip.app.public_ip
}

output "app_url" {
  description = "App URL"
  value       = "http://${aws_eip.app.public_ip}"
}

output "ssh_command" {
  description = "SSH into the instance"
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_eip.app.public_ip}"
}

output "view_logs" {
  description = "SSH in then run this to tail app logs"
  value       = "cd /app && docker-compose logs -f"
}

output "bootstrap_log" {
  description = "SSH in then run this to check the boot log"
  value       = "sudo cat /var/log/user_data.log"
}
