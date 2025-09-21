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
