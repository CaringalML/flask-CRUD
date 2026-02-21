output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "provisioning_model" {
  description = "Provisioning model used"
  value       = "On-Demand (No ALB) - Flask + Nginx via EC2 Public IP on Port 80"
}

output "asg_name" {
  description = "Auto Scaling Group name"
  value       = aws_autoscaling_group.ecs.name
}