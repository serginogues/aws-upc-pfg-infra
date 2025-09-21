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
  default     = ""
}

variable "grafana_password" {
  description = "Grafana admin password (leave empty for auto-generated)"
  type        = string
  sensitive   = true
  default     = ""
}
