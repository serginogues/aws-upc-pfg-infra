#!/bin/bash

# Script to download provisioning files from S3
set -e

echo "Starting Grafana provisioning files download..."

# Create provisioning directory
mkdir -p /etc/grafana/provisioning

# Download files from S3
echo "Downloading files from S3 bucket: ${S3_BUCKET}"
aws s3 sync s3://${S3_BUCKET}/ /etc/grafana/provisioning/ --region us-east-1

# Set proper permissions
chown -R 472:472 /etc/grafana/provisioning
chmod -R 755 /etc/grafana/provisioning

echo "Provisioning files downloaded successfully"
ls -la /etc/grafana/provisioning/
