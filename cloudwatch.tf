# =============================================================================
# CLOUDWATCH LOG GROUPS
# =============================================================================

# Define Lambda functions for monitoring
locals {
  lambda_functions = {
    secrets_function = aws_lambda_function.secrets_function
    acknowledge_function = aws_lambda_function.acknowledge_function
    qrcode_generator_function = aws_lambda_function.qrcode_generator_function
  }
}

# CloudWatch Log Groups for each Lambda function
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/${each.value.function_name}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${local.name_prefix}-${each.key}-logs"
    Environment = var.environment
    Project     = var.app-name
    Service     = "lambda"
  }
}

# =============================================================================
# SNS TOPIC FOR ALERTS
# =============================================================================

# SNS Topic for alerts
resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts-secrets-api"

  tags = {
    Name        = "${local.name_prefix}-alerts-secrets-api"
    Environment = var.environment
    Project     = var.app-name
    Service     = "monitoring"
  }
}

# SNS Topic subscription (email)
resource "aws_sns_topic_subscription" "email_alerts" {
  count     = var.alert_email != "" ? 1 : 0
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# =============================================================================
# CLOUDWATCH ALARMS
# =============================================================================

# Error alarms for each Lambda function
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = local.lambda_functions

  alarm_name          = "${local.name_prefix}-${each.key}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300" # 5 minutes
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors lambda errors for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = {
    Name        = "${local.name_prefix}-${each.key}-errors"
    Environment = var.environment
    Project     = var.app-name
    Service     = "monitoring"
    AlarmType   = "errors"
  }
}

# Duration alarms for each Lambda function
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  for_each = local.lambda_functions

  alarm_name          = "${local.name_prefix}-${each.key}-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300" # 5 minutes
  statistic           = "Average"
  threshold           = var.duration_threshold_ms
  alarm_description   = "This metric monitors lambda duration for ${each.key}"
  alarm_actions       = [aws_sns_topic.alerts.arn]
  ok_actions          = [aws_sns_topic.alerts.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value.function_name
  }

  tags = {
    Name        = "${local.name_prefix}-${each.key}-duration"
    Environment = var.environment
    Project     = var.app-name
    Service     = "monitoring"
    AlarmType   = "duration"
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "sns_topic_arn" {
  description = "ARN of the SNS topic for alerts"
  value       = aws_sns_topic.alerts.arn
}

output "log_groups" {
  description = "Map of Lambda function names to their CloudWatch log group names"
  value = {
    for key, log_group in aws_cloudwatch_log_group.lambda_logs : key => log_group.name
  }
}

output "alarm_names" {
  description = "Map of Lambda function names to their alarm names"
  value = {
    for key, function in local.lambda_functions : key => {
      errors_alarm   = aws_cloudwatch_metric_alarm.lambda_errors[key].alarm_name
      duration_alarm = aws_cloudwatch_metric_alarm.lambda_duration[key].alarm_name
    }
  }
}
