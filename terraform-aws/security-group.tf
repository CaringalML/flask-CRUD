# Security Group for EC2 Instances (Direct Public Access)
resource "aws_security_group" "ecs_instances" {
  name        = "${var.project_name}-ecs-inst-sg"
  description = "Allow direct HTTP traffic to ECS instances"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}