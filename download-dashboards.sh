#!/bin/bash

# Script to download Grafana dashboards from S3
# This script runs inside the Grafana container

set -e

echo "🚀 Starting dashboard download process..."

# Create provisioning directories
mkdir -p /etc/grafana/provisioning/dashboards
mkdir -p /etc/grafana/provisioning/datasources

# Download dashboards from S3
echo "📥 Downloading dashboards from S3..."

# Download Lambda monitoring dashboard
echo "  - Downloading Lambda monitoring dashboard..."
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/lambda-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1

# Download DynamoDB monitoring dashboard
echo "  - Downloading DynamoDB monitoring dashboard..."
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dynamodb-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1

# Download dashboards configuration
echo "  - Downloading dashboards configuration..."
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/ --region us-east-1

# Download CloudWatch datasource configuration
echo "  - Downloading CloudWatch datasource configuration..."
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/datasources/cloudwatch.yml /etc/grafana/provisioning/datasources/ --region us-east-1

# Set proper permissions
echo "🔐 Setting permissions..."
chown -R 472:472 /etc/grafana/provisioning
chmod -R 755 /etc/grafana/provisioning

# List downloaded files
echo "📋 Downloaded files:"
ls -la /etc/grafana/provisioning/dashboards/
ls -la /etc/grafana/provisioning/datasources/

echo "✅ Dashboard download completed successfully!"
echo "🔄 Restarting Grafana to load new configuration..."

# Send SIGHUP to Grafana to reload configuration
pkill -HUP grafana-server || echo "⚠️  Could not send SIGHUP to Grafana, manual restart may be needed"

echo "🎉 Process completed!"
