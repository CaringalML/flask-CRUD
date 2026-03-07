variable "aws_region" {
  description = "AWS region — ap-south-1 (Mumbai) is cheapest for t4g"
  type        = string
  default     = "ap-south-1"
}

variable "app_name" {
  description = "Name prefix for all AWS resources"
  type        = string
  default     = "salon-booking"
}

variable "instance_type" {
  description = "EC2 instance type (must be ARM64/Graviton)"
  type        = string
  default     = "t4g.nano"
}

variable "docker_image" {
  description = "Docker Hub image to deploy (must be ARM64)"
  type        = string
  default     = "rencecaringal000/flask-crud:latest"
}

variable "flask_env" {
  description = "FLASK_ENV value inside the container"
  type        = string
  default     = "production"
}

variable "flask_secret_key" {
  description = "Flask SECRET_KEY — set in terraform.tfvars, never commit"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to your local SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH. Restrict to your IP e.g. 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "db_volume_size_gb" {
  description = "EBS volume size in GB for SQLite database persistence"
  type        = number
  default     = 5
}
