# =============================================================================
# GRAFANA OUTPUTS FOR MANUAL DASHBOARD CONFIGURATION
# =============================================================================

output "lambda_function_names" {
  description = "Lambda function names for dashboard configuration"
  value = {
    secrets_function     = aws_lambda_function.secrets_function.function_name
    acknowledge_function = aws_lambda_function.acknowledge_function.function_name
    qrcode_function      = aws_lambda_function.qrcode_generator_function.function_name
  }
}

output "grafana_datasource_uid" {
  description = "Grafana CloudWatch datasource UID for dashboard configuration"
  value       = grafana_data_source.cloudwatch.uid
}

output "grafana_dashboard_instructions" {
  description = "Instructions for creating dashboards manually"
  value = <<-EOT
    To create dashboards manually in Grafana:
    
    1. Go to Dashboards → New → New Dashboard
    2. Add Panel → Add Visualization
    3. Select CloudWatch as datasource
    4. Use these function names:
       - Secrets Function: ${aws_lambda_function.secrets_function.function_name}
       - Acknowledge Function: ${aws_lambda_function.acknowledge_function.function_name}
       - QR Code Function: ${aws_lambda_function.qrcode_generator_function.function_name}
    
    5. Recommended metrics:
       - AWS/Lambda Invocations
       - AWS/Lambda Errors
       - AWS/Lambda Duration
       - AWS/Lambda Throttles
       - AWS/Lambda ConcurrentExecutions
    
    6. Set dimensions: FunctionName = [function_name]
  EOT
}
