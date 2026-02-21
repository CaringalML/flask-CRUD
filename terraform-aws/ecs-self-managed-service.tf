resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.self_managed.name
    base              = 1 # Ensure at least 1 task is always running on On-Demand 
    weight            = 1
  }

  # Remains NO load_balancer block for direct public access [cite: 53]

  deployment_minimum_healthy_percent = 0 
  deployment_maximum_percent         = 200

  depends_on = [
    aws_iam_role_policy_attachment.ecs_task_execution_role_policy,
    aws_ecs_cluster_capacity_providers.main,
    aws_internet_gateway.main 
  ]
}