# Grafana Folders
resource "grafana_folder" "aws_monitoring" {
  title = "AWS Monitoring"
}

resource "grafana_folder" "lambda_monitoring" {
  title = "Lambda Monitoring"
}

resource "grafana_folder" "dynamodb_monitoring" {
  title = "DynamoDB Monitoring"
}

# CloudWatch Datasource
resource "grafana_data_source" "cloudwatch" {
  type = "cloudwatch"
  name = "CloudWatch"
  url  = "https://monitoring.${var.region}.amazonaws.com"
  
  json_data_encoded = jsonencode({
    defaultRegion = var.region
    authType      = "keys"
    assumeRoleArn = ""
  })
  
  is_default = true
}

# Lambda Dashboard
resource "grafana_dashboard" "lambda_monitoring" {
  folder = grafana_folder.lambda_monitoring.id
  config_json = templatefile("${path.module}/dashboards/lambda-monitoring.json", {
    function_name = "aws-upc-pfg-secrets-function-${var.account_name}"
    region        = var.region
  })
}

# DynamoDB Dashboard
resource "grafana_dashboard" "dynamodb_monitoring" {
  folder = grafana_folder.dynamodb_monitoring.id
  config_json = templatefile("${path.module}/dashboards/dynamodb-monitoring.json", {
    table_name = "aws-upc-pfg-secrets-${var.account_name}"
    region     = var.region
  })
}