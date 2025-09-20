# S3 Bucket for storing provisioning files
resource "aws_s3_bucket" "grafana_provisioning" {
  bucket = "${local.name_prefix}-grafana-provisioning-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "${local.name_prefix}-grafana-provisioning"
    Environment = var.environment
    Project     = var.project_name
    Service     = "monitoring"
  }
}

# Random string for bucket suffix
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Upload provisioning files to S3
resource "aws_s3_object" "grafana_dashboards" {
  for_each = fileset("${path.module}/grafana-provisioning", "**/*")
  
  bucket = aws_s3_bucket.grafana_provisioning.id
  key    = each.value
  source = "${path.module}/grafana-provisioning/${each.value}"
  etag   = filemd5("${path.module}/grafana-provisioning/${each.value}")
}