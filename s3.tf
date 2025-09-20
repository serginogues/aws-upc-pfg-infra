# S3 bucket for QRs
resource "aws_s3_bucket" "qrcodes-bucket" {
  bucket = "${local.name_prefix}-qrcodes-bucket-${var.account_name}"
  force_destroy = true
}

# S3 Bucket Notification to Lambda
resource "aws_s3_bucket_notification" "qr_code_upload_notification" {
  bucket = aws_s3_bucket.qrcodes-bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.send_qrcode_upload_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "qrcodes/"
  }

  depends_on = [aws_lambda_permission.allow_s3_invoke_lambda]
}
