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

variable "region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "us-east-1"
}

variable "account_name" {
  type        = string
  description = "Name of the AWS account"
}

variable "sender_email" {
  type        = string
  description = "Email to use as sender"
}

locals {
  name_prefix = "${var.app-name}-${var.environment}"
}
