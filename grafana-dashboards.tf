# =============================================================================
# GRAFANA DASHBOARDS - CORRECTED STRUCTURE
# =============================================================================

# Lambda Monitoring Dashboard
resource "grafana_dashboard" "lambda_monitoring" {
  depends_on = [grafana_data_source.cloudwatch]
  
  config_json = jsonencode({
    id                    = null
    title                 = "AWS Lambda Monitoring - ${local.name_prefix}"
    tags                  = ["lambda", "aws", "monitoring"]
    timezone              = "browser"
    refresh               = "30s"
    time                  = {
      from = "now-1h"
      to   = "now"
    }
    panels = [
      # Panel 1: Invocations
      {
        id       = 1
        title    = "Lambda Invocations"
        type     = "graph"
        gridPos  = {
          h = 8
          w = 12
          x = 0
          y = 0
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/Lambda"
            metricName   = "Invocations"
            dimensions   = {
              FunctionName = aws_lambda_function.secrets_function.function_name
            }
            statistic    = "Sum"
            refId        = "A"
            datasource   = {
              type = "cloudwatch"
              uid  = grafana_data_source.cloudwatch.uid
            }
          }
        ]
        yAxes = [
          {
            label = "Invocations"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
      },
      # Panel 2: Errors
      {
        id       = 2
        title    = "Lambda Errors"
        type     = "graph"
        gridPos  = {
          h = 8
          w = 12
          x = 12
          y = 0
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/Lambda"
            metricName   = "Errors"
            dimensions   = {
              FunctionName = aws_lambda_function.secrets_function.function_name
            }
            statistic    = "Sum"
            refId        = "A"
            datasource   = {
              type = "cloudwatch"
              uid  = grafana_data_source.cloudwatch.uid
            }
          }
        ]
        yAxes = [
          {
            label = "Errors"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
      },
      # Panel 3: Duration
      {
        id       = 3
        title    = "Lambda Duration"
        type     = "graph"
        gridPos  = {
          h = 8
          w = 24
          x = 0
          y = 8
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/Lambda"
            metricName   = "Duration"
            dimensions   = {
              FunctionName = aws_lambda_function.secrets_function.function_name
            }
            statistic    = "Average"
            refId        = "A"
            datasource   = {
              type = "cloudwatch"
              uid  = grafana_data_source.cloudwatch.uid
            }
          }
        ]
        yAxes = [
          {
            label = "Duration (ms)"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
      }
    ]
  })
}

# Dashboard for Acknowledge Function
resource "grafana_dashboard" "acknowledge_monitoring" {
  depends_on = [grafana_data_source.cloudwatch]
  
  config_json = jsonencode({
    id                    = null
    title                 = "Acknowledge Function Monitoring"
    tags                  = ["lambda", "aws", "acknowledge"]
    timezone              = "browser"
    refresh               = "30s"
    time                  = {
      from = "now-1h"
      to   = "now"
    }
    panels = [
      {
        id       = 1
        title    = "Acknowledge Function Metrics"
        type     = "graph"
        gridPos  = {
          h = 8
          w = 24
          x = 0
          y = 0
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/Lambda"
            metricName   = "Invocations"
            dimensions   = {
              FunctionName = aws_lambda_function.acknowledge_function.function_name
            }
            statistic    = "Sum"
            refId        = "A"
            datasource   = {
              type = "cloudwatch"
              uid  = grafana_data_source.cloudwatch.uid
            }
          },
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/Lambda"
            metricName   = "Errors"
            dimensions   = {
              FunctionName = aws_lambda_function.acknowledge_function.function_name
            }
            statistic    = "Sum"
            refId        = "B"
            datasource   = {
              type = "cloudwatch"
              uid  = grafana_data_source.cloudwatch.uid
            }
          }
        ]
        yAxes = [
          {
            label = "Count"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
      }
    ]
  })
}

# Dashboard for QR Code Generator Function
resource "grafana_dashboard" "qrcode_monitoring" {
  depends_on = [grafana_data_source.cloudwatch]
  
  config_json = jsonencode({
    id                    = null
    title                 = "QR Code Generator Function Monitoring"
    tags                  = ["lambda", "aws", "qrcode"]
    timezone              = "browser"
    refresh               = "30s"
    time                  = {
      from = "now-1h"
      to   = "now"
    }
    panels = [
      {
        id       = 1
        title    = "QR Code Generator Metrics"
        type     = "graph"
        gridPos  = {
          h = 8
          w = 24
          x = 0
          y = 0
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/Lambda"
            metricName   = "Invocations"
            dimensions   = {
              FunctionName = aws_lambda_function.qrcode_generator_function.function_name
            }
            statistic    = "Sum"
            refId        = "A"
            datasource   = {
              type = "cloudwatch"
              uid  = grafana_data_source.cloudwatch.uid
            }
          },
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/Lambda"
            metricName   = "Duration"
            dimensions   = {
              FunctionName = aws_lambda_function.qrcode_generator_function.function_name
            }
            statistic    = "Average"
            refId        = "B"
            datasource   = {
              type = "cloudwatch"
              uid  = grafana_data_source.cloudwatch.uid
            }
          }
        ]
        yAxes = [
          {
            label = "Count / Duration (ms)"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
      }
    ]
  })
}
