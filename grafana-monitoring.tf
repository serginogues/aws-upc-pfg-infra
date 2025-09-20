# CloudWatch Log Group for ECS
resource "aws_cloudwatch_log_group" "grafana_ecs" {
  name              = "/ecs/${local.name_prefix}-grafana"
  retention_in_days = 7

  tags = {
    Name        = "${local.name_prefix}-grafana-ecs-logs"
    Environment = var.environment
    Project     = var.project_name
    Service     = "monitoring"
  }
}

# CloudWatch Alarms for ECS Service
resource "aws_cloudwatch_metric_alarm" "grafana_ecs_cpu_high" {
  alarm_name          = "${local.name_prefix}-grafana-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS CPU utilization"
  alarm_actions       = []

  dimensions = {
    ServiceName = aws_ecs_service.grafana.name
    ClusterName = aws_ecs_cluster.grafana.name
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-ecs-cpu-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_metric_alarm" "grafana_ecs_memory_high" {
  alarm_name          = "${local.name_prefix}-grafana-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors ECS memory utilization"
  alarm_actions       = []

  dimensions = {
    ServiceName = aws_ecs_service.grafana.name
    ClusterName = aws_ecs_cluster.grafana.name
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-ecs-memory-alarm"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "grafana_ecs" {
  dashboard_name = "${local.name_prefix}-grafana-ecs-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_service.grafana.name, "ClusterName", aws_ecs_cluster.grafana.name],
            [".", "MemoryUtilization", ".", ".", ".", "."]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Grafana ECS Metrics"
          period  = 300
        }
      }
    ]
  })

}
