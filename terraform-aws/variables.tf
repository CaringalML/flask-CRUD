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

variable "instance_type" {
  description = "EC2 instance type — t4g.nano is sufficient, no local DB"
  type        = string
  default     = "t4g.nano"
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

# ─── Supabase credentials ─────────────────────────────────────────────────────

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_key" {
  description = "Supabase API key (anon or service role)"
  type        = string
  sensitive   = true
}

variable "database_url" {
  description = "Full PostgreSQL connection string for Supabase e.g. postgresql://postgres:password@db.xxx.supabase.co:5432/postgres"
  type        = string
  sensitive   = true
}

variable "supabase_anon_key" {
  description = "Supabase anon (public) key — used by the browser for Realtime websocket subscriptions"
  type        = string
  sensitive   = true
}
