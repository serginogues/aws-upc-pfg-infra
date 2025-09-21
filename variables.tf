variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
}

# Grafana variables removed

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "app-name" {
  description = "Application name"
  type        = string
  default     = "aws-upc-pfg"
}

variable "log_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 14
}

variable "duration_threshold_ms" {
  description = "Lambda duration threshold in milliseconds for alerts"
  type        = number
  default     = 30000
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana (change after first login)"
  type        = string
  default     = "admin"
  sensitive   = true
}

variable "sender_email" {
  type        = string
  description = "Email to use as sender"
}

locals {
  name_prefix = "${var.app-name}-${var.environment}"
}
