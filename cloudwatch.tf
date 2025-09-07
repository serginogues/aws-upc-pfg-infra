# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.send_qrcode_email_notification_function.function_name}"
  retention_in_days = 14
}