# Outputs
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

output "api_gateway_url" {
  value = "https://${aws_api_gateway_rest_api.secrets_api.id}.execute-api.${var.region}.amazonaws.com/${var.environment}"
}

output "grafana_private_ip" {
  value = aws_instance.grafana.private_ip
}

output "grafana_admin_password" {
  value = var.grafana_password != "" ? var.grafana_password : random_password.grafana_password.result
  sensitive = true
}
