# Outputs
#TODO
# output "api_gateway_url" {
#   value = aws_apigatewayv2_api.demo_http.api_endpoint
# }

output "dynamodb_table_name" {
  value = aws_dynamodb_table.secrets.name
}

output "qr_bucket_name" {
  value = aws_s3_bucket.qrcodes-bucket.bucket
}

output "secrets_journal_queue_url" {
  value = aws_sqs_queue.secrets_journal.url
}

output "qr_code_queue_url" {
  value = aws_sqs_queue.qr_code_queue.url
}