# S3 bucket for QRs
resource "aws_s3_bucket" "qrcodes-bucket" {
  bucket = "${local.name_prefix}-qrcodes-bucket-${var.account_name}"
  force_destroy = true
}

