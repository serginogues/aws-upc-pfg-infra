# S3 bucket for QRs
resource "aws_s3_bucket" "qrcodes-bucket" {
  bucket = "${local.name_prefix}-qrcodes-bucket-${var.account_name}"
  force_destroy = true
}

# S3 bucket for Grafana dashboards and provisioning
resource "aws_s3_bucket" "grafana-dashboards-bucket" {
  bucket = "${local.name_prefix}-grafana-dashboards-${var.account_name}"
  force_destroy = true

  tags = {
    Name        = "${local.name_prefix}-grafana-dashboards"
    Environment = var.environment
    Project     = var.app-name
    Service     = "monitoring"
  }
}

