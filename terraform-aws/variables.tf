variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "app_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "salon-booking"
}

variable "docker_image" {
  description = "Flask app Docker Hub image"
  type        = string
  default     = "rencecaringal000/flask-crud:latest"
}

variable "flask_env" {
  description = "FLASK_ENV value"
  type        = string
  default     = "production"
}

variable "flask_secret_key" {
  description = "Flask SECRET_KEY — set in terraform.tfvars, never commit"
  type        = string
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "Path to local SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ssh_allowed_cidr" {
  description = "CIDR allowed to SSH. Restrict to your IP e.g. 1.2.3.4/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type — t4g.micro recommended for PostgreSQL"
  type        = string
  default     = "t4g.micro"
}

variable "db_volume_size_gb" {
  description = "EBS volume size in GB for PostgreSQL data"
  type        = number
  default     = 10
}

# ─── PostgreSQL credentials ───────────────────────────────────────────────────

variable "postgres_db" {
  description = "PostgreSQL database name"
  type        = string
  default     = "flask_crud"
}

variable "postgres_user" {
  description = "PostgreSQL username"
  type        = string
  default     = "flask_user"
}

variable "postgres_password" {
  description = "PostgreSQL password — set in terraform.tfvars, never commit"
  type        = string
  sensitive   = true
}

# ─── pgAdmin credentials ──────────────────────────────────────────────────────

variable "pgadmin_email" {
  description = "pgAdmin login email"
  type        = string
  default     = "admin@salon.com"
}

variable "pgadmin_password" {
  description = "pgAdmin login password — set in terraform.tfvars, never commit"
  type        = string
  sensitive   = true
}

variable "pgadmin_port" {
  description = "Host port for pgAdmin web UI"
  type        = number
  default     = 5050
}
