#!/bin/bash

# Grafana EC2 User Data Script
# This script installs and configures Grafana on Amazon Linux 2

set -e

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install Grafana using Docker with AWS access
docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=${grafana_admin_password} \
  -e GF_SECURITY_ALLOW_EMBEDDING=true \
  -e GF_AUTH_ANONYMOUS_ENABLED=false \
  -e GF_SERVER_ROOT_URL=http://localhost:3000 \
  -e GF_PATHS_PROVISIONING=/etc/grafana/provisioning \
  -e GF_DATABASE_TYPE=sqlite3 \
  -e GF_DATABASE_PATH=/var/lib/grafana/grafana.db \
  -e GF_INSTALL_PLUGINS=grafana-piechart-panel,grafana-clock-panel \
  -e AWS_REGION=us-east-1 \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -v grafana-data:/var/lib/grafana \
  -v grafana-provisioning:/etc/grafana/provisioning \
  --network host \
  grafana/grafana:latest

# Wait for Grafana to start
sleep 30

# Create provisioning directories
docker exec grafana mkdir -p /etc/grafana/provisioning/dashboards
docker exec grafana mkdir -p /etc/grafana/provisioning/datasources

# Download provisioning files from S3
aws s3 cp s3://${s3_bucket_name}/dashboards/lambda-monitoring.json /tmp/lambda-monitoring.json --region us-east-1
aws s3 cp s3://${s3_bucket_name}/dashboards/dynamodb-monitoring.json /tmp/dynamodb-monitoring.json --region us-east-1
aws s3 cp s3://${s3_bucket_name}/dashboards/dashboards.yml /tmp/dashboards.yml --region us-east-1
aws s3 cp s3://${s3_bucket_name}/datasources/cloudwatch.yml /tmp/cloudwatch.yml --region us-east-1

# Copy files to Grafana container
docker cp /tmp/lambda-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dynamodb-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dashboards.yml grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/cloudwatch.yml grafana:/etc/grafana/provisioning/datasources/

# Set proper permissions
docker exec grafana chown -R 472:472 /etc/grafana/provisioning

# Restart Grafana to apply changes
docker restart grafana

# Clean up
rm -f /tmp/*.json /tmp/*.yml awscliv2.zip
rm -rf ./aws

# Log completion
echo "Grafana installation and configuration completed successfully!" >> /var/log/grafana-setup.log
