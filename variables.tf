variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  description = "Account name for resource naming"
  type        = string
}

variable "grafana_ip" {
  description = "Grafana instance IP address"
  type        = string
}

variable "grafana_password" {
  description = "Grafana admin password"
  type        = string
  sensitive   = true
}

variable "lambda_function_name" {
  description = "Lambda function name for monitoring"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for monitoring"
  type        = string
}