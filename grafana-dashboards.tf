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
        type     = "timeseries"
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
        type     = "timeseries"
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
        type     = "timeseries"
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

# DynamoDB Monitoring Dashboard
resource "grafana_dashboard" "dynamodb_monitoring" {
  depends_on = [grafana_data_source.cloudwatch]
  
  config_json = jsonencode({
    id                    = null
    title                 = "DynamoDB Monitoring - ${local.name_prefix}"
    tags                  = ["dynamodb", "aws", "database", "monitoring"]
    timezone              = "browser"
    refresh               = "30s"
    time                  = {
      from = "now-1h"
      to   = "now"
    }
    panels = [
      # Panel 1: Item Count
      {
        id       = 1
        title    = "DynamoDB Item Count"
        type     = "timeseries"
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
            namespace    = "AWS/DynamoDB"
            metricName   = "ItemCount"
            dimensions   = {
              TableName = aws_dynamodb_table.secrets.name
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
            label = "Item Count"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "palette-classic"
            }
            custom = {
              axisLabel = ""
              axisPlacement = "auto"
              barAlignment = 0
              drawStyle = "line"
              fillOpacity = 0
              gradientMode = "none"
              hideFrom = {
                legend = false
                tooltip = false
                vis = false
              }
              lineInterpolation = "linear"
              lineWidth = 1
              pointSize = 5
              scaleDistribution = {
                type = "linear"
              }
              showPoints = "auto"
              spanNulls = false
              stacking = {
                group = "A"
                mode = "none"
              }
              thresholdsStyle = {
                mode = "off"
              }
            }
            mappings = []
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                },
                {
                  color = "red"
                  value = 80
                }
              ]
            }
            unit = "short"
          }
        }
      },
      # Panel 2: Consumed Read Capacity Units
      {
        id       = 2
        title    = "Consumed Read Capacity Units"
        type     = "timeseries"
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
            namespace    = "AWS/DynamoDB"
            metricName   = "ConsumedReadCapacityUnits"
            dimensions   = {
              TableName = aws_dynamodb_table.secrets.name
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
            label = "Read Capacity Units"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
      },
      # Panel 3: Consumed Write Capacity Units
      {
        id       = 3
        title    = "Consumed Write Capacity Units"
        type     = "timeseries"
        gridPos  = {
          h = 8
          w = 12
          x = 0
          y = 8
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/DynamoDB"
            metricName   = "ConsumedWriteCapacityUnits"
            dimensions   = {
              TableName = aws_dynamodb_table.secrets.name
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
            label = "Write Capacity Units"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
      },
      # Panel 4: Throttled Requests
      {
        id       = 4
        title    = "Throttled Requests"
        type     = "timeseries"
        gridPos  = {
          h = 8
          w = 12
          x = 12
          y = 8
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/DynamoDB"
            metricName   = "ThrottledRequests"
            dimensions   = {
              TableName = aws_dynamodb_table.secrets.name
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
            label = "Throttled Requests"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                },
                {
                  color = "yellow"
                  value = 1
                },
                {
                  color = "red"
                  value = 10
                }
              ]
            }
          }
        }
      },
      # Panel 5: User Errors
      {
        id       = 5
        title    = "User Errors"
        type     = "timeseries"
        gridPos  = {
          h = 8
          w = 12
          x = 0
          y = 16
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/DynamoDB"
            metricName   = "UserErrors"
            dimensions   = {
              TableName = aws_dynamodb_table.secrets.name
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
            label = "User Errors"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                },
                {
                  color = "red"
                  value = 1
                }
              ]
            }
          }
        }
      },
      # Panel 6: System Errors
      {
        id       = 6
        title    = "System Errors"
        type     = "timeseries"
        gridPos  = {
          h = 8
          w = 12
          x = 12
          y = 16
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/DynamoDB"
            metricName   = "SystemErrors"
            dimensions   = {
              TableName = aws_dynamodb_table.secrets.name
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
            label = "System Errors"
            min   = 0
          }
        ]
        xAxis = {
          show = true
        }
        fieldConfig = {
          defaults = {
            color = {
              mode = "thresholds"
            }
            thresholds = {
              mode = "absolute"
              steps = [
                {
                  color = "green"
                  value = null
                },
                {
                  color = "red"
                  value = 1
                }
              ]
            }
          }
        }
      },
      # Panel 7: Successful Request Latency
      {
        id       = 7
        title    = "Successful Request Latency"
        type     = "timeseries"
        gridPos  = {
          h = 8
          w = 24
          x = 0
          y = 24
        }
        targets = [
          {
            region       = var.region
            queryMode    = "Metrics"
            namespace    = "AWS/DynamoDB"
            metricName   = "SuccessfulRequestLatency"
            dimensions   = {
              TableName = aws_dynamodb_table.secrets.name
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
            label = "Latency (ms)"
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
