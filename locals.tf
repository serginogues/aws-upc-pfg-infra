# Local values
locals {
  name_prefix = "${var.app-name}-infra-${var.environment}"
  
  common_tags = {
    Environment = var.environment
    Project     = var.app-name
    Owner       = var.account_name
  }
}
