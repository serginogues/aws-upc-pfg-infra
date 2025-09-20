#!/bin/bash
# Create directories
mkdir -p /etc/grafana/provisioning/dashboards
mkdir -p /etc/grafana/provisioning/datasources

# Copy files (these will be provided via stdin)
cat > /etc/grafana/provisioning/dashboards/lambda-monitoring.json << 'LAMBDA_EOF'
{
  "id": null,
  "title": "AWS Lambda Monitoring",
  "tags": ["lambda", "aws", "monitoring"],
  "timezone": "browser",
  "refresh": "30s",
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "panels": [
    {
      "id": 1,
      "title": "Lambda Invocations",
      "type": "timeseries",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "targets": [
        {
          "refId": "A",
          "datasource": {
            "type": "cloudwatch",
            "uid": "cloudwatch"
          },
          "namespace": "AWS/Lambda",
          "metricName": "Invocations",
          "dimensions": {
            "FunctionName": "aws-upc-pfg-infra-dev-secrets_function"
          },
          "statistic": "Sum",
          "period": "300"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "vis": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      }
    },
    {
      "id": 2,
      "title": "Lambda Errors",
      "type": "timeseries",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "targets": [
        {
          "refId": "A",
          "datasource": {
            "type": "cloudwatch",
            "uid": "cloudwatch"
          },
          "namespace": "AWS/Lambda",
          "metricName": "Errors",
          "dimensions": {
            "FunctionName": "aws-upc-pfg-infra-dev-secrets_function"
          },
          "statistic": "Sum",
          "period": "300"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "vis": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      }
    },
    {
      "id": 3,
      "title": "Lambda Duration",
      "type": "timeseries",
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "targets": [
        {
          "refId": "A",
          "datasource": {
            "type": "cloudwatch",
            "uid": "cloudwatch"
          },
          "namespace": "AWS/Lambda",
          "metricName": "Duration",
          "dimensions": {
            "FunctionName": "aws-upc-pfg-infra-dev-secrets_function"
          },
          "statistic": "Average",
          "period": "300"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "vis": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "ms"
        },
        "overrides": []
      },
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      }
    }
  ],
  "templating": {
    "list": []
  },
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "liveNow": false,
  "schemaVersion": 30,
  "style": "dark",
  "tags": ["lambda", "aws", "monitoring"],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "browser",
  "title": "AWS Lambda Monitoring",
  "uid": "lambda-monitoring",
  "version": 0,
  "weekStart": ""
}LAMBDA_EOF

cat > /etc/grafana/provisioning/dashboards/dynamodb-monitoring.json << 'DYNAMODB_EOF'
{
  "id": null,
  "title": "DynamoDB Monitoring",
  "tags": ["dynamodb", "aws", "monitoring"],
  "timezone": "browser",
  "refresh": "30s",
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "panels": [
    {
      "id": 1,
      "title": "DynamoDB Read Capacity",
      "type": "timeseries",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 0,
        "y": 0
      },
      "targets": [
        {
          "refId": "A",
          "datasource": {
            "type": "cloudwatch",
            "uid": "cloudwatch"
          },
          "namespace": "AWS/DynamoDB",
          "metricName": "ConsumedReadCapacityUnits",
          "dimensions": {
            "TableName": "aws-upc-pfg-infra-dev-secrets"
          },
          "statistic": "Sum",
          "period": "300"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "vis": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      }
    },
    {
      "id": 2,
      "title": "DynamoDB Write Capacity",
      "type": "timeseries",
      "gridPos": {
        "h": 8,
        "w": 12,
        "x": 12,
        "y": 0
      },
      "targets": [
        {
          "refId": "A",
          "datasource": {
            "type": "cloudwatch",
            "uid": "cloudwatch"
          },
          "namespace": "AWS/DynamoDB",
          "metricName": "ConsumedWriteCapacityUnits",
          "dimensions": {
            "TableName": "aws-upc-pfg-infra-dev-secrets"
          },
          "statistic": "Sum",
          "period": "300"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "vis": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      }
    },
    {
      "id": 3,
      "title": "DynamoDB Item Count",
      "type": "timeseries",
      "gridPos": {
        "h": 8,
        "w": 24,
        "x": 0,
        "y": 8
      },
      "targets": [
        {
          "refId": "A",
          "datasource": {
            "type": "cloudwatch",
            "uid": "cloudwatch"
          },
          "namespace": "AWS/DynamoDB",
          "metricName": "ItemCount",
          "dimensions": {
            "TableName": "aws-upc-pfg-infra-dev-secrets"
          },
          "statistic": "Average",
          "period": "300"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "color": {
            "mode": "palette-classic"
          },
          "custom": {
            "axisLabel": "",
            "axisPlacement": "auto",
            "barAlignment": 0,
            "drawStyle": "line",
            "fillOpacity": 0,
            "gradientMode": "none",
            "hideFrom": {
              "legend": false,
              "tooltip": false,
              "vis": false
            },
            "lineInterpolation": "linear",
            "lineWidth": 1,
            "pointSize": 5,
            "scaleDistribution": {
              "type": "linear"
            },
            "showPoints": "auto",
            "spanNulls": false,
            "stacking": {
              "group": "A",
              "mode": "none"
            },
            "thresholdsStyle": {
              "mode": "off"
            }
          },
          "mappings": [],
          "thresholds": {
            "mode": "absolute",
            "steps": [
              {
                "color": "green",
                "value": null
              },
              {
                "color": "red",
                "value": 80
              }
            ]
          },
          "unit": "short"
        },
        "overrides": []
      },
      "options": {
        "legend": {
          "calcs": [],
          "displayMode": "list",
          "placement": "bottom"
        },
        "tooltip": {
          "mode": "single"
        }
      }
    }
  ],
  "templating": {
    "list": []
  },
  "annotations": {
    "list": [
      {
        "builtIn": 1,
        "datasource": {
          "type": "grafana",
          "uid": "-- Grafana --"
        },
        "enable": true,
        "hide": true,
        "iconColor": "rgba(0, 211, 255, 1)",
        "name": "Annotations & Alerts",
        "type": "dashboard"
      }
    ]
  },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 0,
  "links": [],
  "liveNow": false,
  "schemaVersion": 30,
  "style": "dark",
  "tags": ["dynamodb", "aws", "monitoring"],
  "templating": {
    "list": []
  },
  "time": {
    "from": "now-1h",
    "to": "now"
  },
  "timepicker": {},
  "timezone": "browser",
  "title": "DynamoDB Monitoring",
  "uid": "dynamodb-monitoring",
  "version": 0,
  "weekStart": ""
}DYNAMODB_EOF

cat > /etc/grafana/provisioning/dashboards/dashboards.yml << 'DASHBOARDS_EOF'
apiVersion: 1

providers:
  - name: 'default'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
DASHBOARDS_EOF

cat > /etc/grafana/provisioning/datasources/cloudwatch.yml << 'DATASOURCE_EOF'
apiVersion: 1

datasources:
  - name: CloudWatch
    type: cloudwatch
    access: proxy
    url: ""
    jsonData:
      authType: default
      defaultRegion: us-east-1
    isDefault: true
    editable: true
    uid: cloudwatch
DATASOURCE_EOF

# Set permissions
chown -R 472:472 /etc/grafana/provisioning
chmod -R 755 /etc/grafana/provisioning

echo "✅ Files copied successfully"
ls -la /etc/grafana/provisioning/dashboards/
ls -la /etc/grafana/provisioning/datasources/
