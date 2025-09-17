# =============================================================================
# GRAFANA CONFIGURATION WITH IAM USER CREDENTIALS
# =============================================================================

# Wait for Grafana to be ready
resource "time_sleep" "wait_for_grafana" {
  depends_on = [aws_instance.grafana]
  
  create_duration = "5m"
}

# CloudWatch Datasource with IAM user credentials
resource "grafana_data_source" "cloudwatch" {
  depends_on = [time_sleep.wait_for_grafana]
  
  type = "cloudwatch"
  name = "CloudWatch"
  
  json_data_encoded = jsonencode({
    authType     = "keys"
    defaultRegion = var.region
    accessKey     = aws_iam_access_key.grafana_user.id
    secretKey     = aws_iam_access_key.grafana_user.secret
  })
  
  url = "https://monitoring.${var.region}.amazonaws.com"
  
  is_default = true
}

# =============================================================================
# OUTPUTS FOR MANUAL CONFIGURATION
# =============================================================================

output "grafana_cloudwatch_credentials" {
  description = "Credentials for CloudWatch datasource configuration"
  value = {
    access_key_id     = aws_iam_access_key.grafana_user.id
    secret_access_key = aws_iam_access_key.grafana_user.secret
    region           = var.region
  }
  sensitive = true
}

output "grafana_manual_setup_instructions" {
  description = "Instructions for manual CloudWatch datasource setup"
  value = <<-EOT
    If automatic datasource creation fails, configure manually:
    
    1. Go to Configuration → Data Sources → Add data source → CloudWatch
    2. Set Authentication Provider to "Keys"
    3. Access Key ID: [use grafana_cloudwatch_credentials output]
    4. Secret Access Key: [use grafana_cloudwatch_credentials output]
    5. Default Region: ${var.region}
    6. Click "Save & Test"
  EOT
  sensitive = true
}