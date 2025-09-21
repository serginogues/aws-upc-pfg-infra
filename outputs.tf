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

# Grafana outputs
output "grafana_public_ip" {
  description = "Public IP address of the Grafana instance"
  value       = aws_instance.grafana.public_ip
}

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_instance.grafana.public_ip}:3000"
}

output "grafana_info" {
  description = "Grafana access information"
  value = {
    url = "http://${aws_instance.grafana.public_ip}:3000"
    username = "admin"
    password = "admin (change after first login)"
    dashboards = [
      "Lambda Functions Monitoring",
      "DynamoDB Monitoring", 
      "SQS Queues Monitoring"
    ]
    note = "Dashboards may take 2-3 minutes to load after instance creation"
  }
}
