resource "aws_ecs_task_definition" "main" {
  family                   = var.project_name
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name      = "${var.project_name}-app"
      image     = var.flask_app_image
      essential = true
      portMappings = [{
        containerPort = var.flask_container_port
        hostPort      = 5000
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "flask-app"
        }
      }
    },
    {
      name      = "${var.project_name}-nginx"
      image     = var.nginx_image
      essential = true
      portMappings = [{
        containerPort = var.nginx_container_port
        hostPort      = 80
        protocol      = "tcp"
      }]
      links = ["${var.project_name}-app:flask_crud_app"]
      dependsOn = [{
        containerName = "${var.project_name}-app"
        condition     = "START"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
}