# 1. Fetch the latest ECS-optimized Amazon Linux 2023 ARM64 AMI
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/arm64/recommended/image_id"
}

# 2. Launch Template (The blueprint for your On-Demand server)
resource "aws_launch_template" "ecs" {
  name_prefix   = "${var.project_name}-ecs-lt-"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t4g.micro" # FIX: Defining type here fixes the ASG error

  iam_instance_profile {
    name = aws_iam_instance_profile.ecs_instance_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true # Required for direct access in bridge mode
    security_groups             = [aws_security_group.ecs_instances.id]
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${var.project_name} >> /etc/ecs/ecs.config
    echo ECS_ENABLE_TASK_IAM_ROLE=true >> /etc/ecs/ecs.config
  EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${var.project_name}-on-demand-host" }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 3. Auto Scaling Group (Simplified for 1 Stable On-Demand Instance)
resource "aws_autoscaling_group" "ecs" {
  name                = "${var.project_name}-ecs-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  
  # Locked to 1 because bridge mode without ALB cannot scale horizontally
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.ecs.id
    version = "$Latest"
  }

  # Protects instance from being killed while tasks are running
  protect_from_scale_in = true 

  depends_on = [aws_internet_gateway.main]

  lifecycle {
    ignore_changes        = [desired_capacity]
    create_before_destroy = true
  }
}

# 4. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.project_name
}

# 5. Capacity Provider (Used for Auto-healing only)
resource "aws_ecs_capacity_provider" "self_managed" {
  name = "${var.project_name}-on-demand-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "ENABLED"
    managed_draining               = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100 # Maintain 1:1 task-to-instance ratio
      maximum_scaling_step_size = 1
      minimum_scaling_step_size = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name       = aws_ecs_cluster.main.name
  capacity_providers = [aws_ecs_capacity_provider.self_managed.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.self_managed.name
    base              = 1 # Always ensure 1 On-Demand instance is used
    weight            = 1
  }
}