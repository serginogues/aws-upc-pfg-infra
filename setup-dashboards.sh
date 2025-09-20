#!/bin/bash
set -e

echo "🚀 Setting up Grafana dashboards..."

# Install AWS CLI
apk add --no-cache curl unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Create directories
mkdir -p /etc/grafana/provisioning/dashboards
mkdir -p /etc/grafana/provisioning/datasources

# Download files from S3
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/lambda-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dynamodb-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/ --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/datasources/cloudwatch.yml /etc/grafana/provisioning/datasources/ --region us-east-1

# Set permissions
chown -R 472:472 /etc/grafana/provisioning
chmod -R 755 /etc/grafana/provisioning

echo "✅ Dashboards setup completed"
ls -la /etc/grafana/provisioning/dashboards/
ls -la /etc/grafana/provisioning/datasources/
