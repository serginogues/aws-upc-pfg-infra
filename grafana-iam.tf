# =============================================================================
# IAM USER FOR GRAFANA
# =============================================================================

# IAM User for Grafana
resource "aws_iam_user" "grafana_user" {
  name = "${local.name_prefix}-grafana-user"
  path = "/"

  tags = {
    Name        = "${local.name_prefix}-grafana-user"
    Environment = var.environment
    Project     = var.app-name
    Service     = "monitoring"
  }
}

# IAM Policy for Grafana CloudWatch access
resource "aws_iam_policy" "grafana_user_cloudwatch" {
  name        = "${local.name_prefix}-grafana-user-cloudwatch"
  description = "Policy for Grafana user to access CloudWatch metrics and logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:DescribeAlarms",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-grafana-user-cloudwatch-policy"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "grafana_user_cloudwatch" {
  user       = aws_iam_user.grafana_user.name
  policy_arn = aws_iam_policy.grafana_user_cloudwatch.arn
}

# Create access keys for Grafana user
resource "aws_iam_access_key" "grafana_user" {
  user = aws_iam_user.grafana_user.name
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "grafana_user_access_key_id" {
  description = "Access Key ID for Grafana user"
  value       = aws_iam_access_key.grafana_user.id
  sensitive   = true
}

output "grafana_user_secret_access_key" {
  description = "Secret Access Key for Grafana user"
  value       = aws_iam_access_key.grafana_user.secret
  sensitive   = true
}

output "grafana_user_credentials" {
  description = "Grafana user credentials for datasource configuration"
  value = {
    access_key_id     = aws_iam_access_key.grafana_user.id
    secret_access_key = aws_iam_access_key.grafana_user.secret
  }
  sensitive = true
}
