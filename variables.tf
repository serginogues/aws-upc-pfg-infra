variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
  default     = "dev"
}

variable "app-name" {
  description = "Name of the application"
  type        = string
  default     = "aws-upc-pfg-infra"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "aws-upc-pfg-infra"
}

variable "region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "us-east-1"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  type        = string
  description = "Name of the AWS account"
}

# Monitoring variables
variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "alert_email" {
  description = "Email address for SNS notifications"
  type        = string
  default     = ""
}

variable "duration_threshold_ms" {
  description = "Duration threshold in milliseconds for Lambda alarms"
  type        = number
  default     = 1000
}

# Grafana variables
variable "grafana_instance_type" {
  description = "EC2 instance type for Grafana"
  type        = string
  default     = "t3.micro"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "admin123"
  sensitive   = true
}


# Note: allowed_cidr_blocks not used in private subnet deployment

locals {
  name_prefix = "${var.app-name}-${var.environment}"
}
