#!/bin/bash
set -e

# Update system
apt update -y

# Install Docker and git
apt install -y docker.io git curl jq

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu

# Create Grafana directories
mkdir -p /opt/grafana/data
mkdir -p /opt/grafana/dashboards
mkdir -p /opt/grafana/provisioning/datasources
mkdir -p /opt/grafana/provisioning/dashboards

# Set permissions for Grafana user (472:0)
chown -R 472:0 /opt/grafana

# Create CloudWatch datasource configuration
cat > /opt/grafana/provisioning/datasources/cloudwatch.yml << 'EOF'
apiVersion: 1

datasources:
  - name: CloudWatch
    type: cloudwatch
    access: proxy
    jsonData:
      authType: credentials
      defaultRegion: ${region}
    isDefault: true
EOF

# Create dashboards provisioning configuration
cat > /opt/grafana/provisioning/dashboards/dashboards.yml << 'EOF'
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
      path: /var/lib/grafana/provisioning-dashboards
EOF

# Download dashboards from S3 to the correct Grafana directory
echo "Downloading dashboards from S3..."

# Create the directory that Grafana will monitor
mkdir -p /opt/grafana/provisioning-dashboards

# Download dashboard files to the provisioning directory
curl -s "https://${dashboard_bucket}.s3.amazonaws.com/lambda-dashboard.json" -o /opt/grafana/provisioning-dashboards/lambda-dashboard.json
curl -s "https://${dashboard_bucket}.s3.amazonaws.com/dynamodb-dashboard.json" -o /opt/grafana/provisioning-dashboards/dynamodb-dashboard.json  
curl -s "https://${dashboard_bucket}.s3.amazonaws.com/sqs-dashboard.json" -o /opt/grafana/provisioning-dashboards/sqs-dashboard.json

# Fix permissions for dashboard files
chown -R 472:0 /opt/grafana/provisioning-dashboards/

echo "Dashboard files downloaded and permissions set"

# Start Grafana container with proper environment variables
docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -v /opt/grafana/data:/var/lib/grafana \
  -v /opt/grafana/provisioning-dashboards:/var/lib/grafana/provisioning-dashboards \
  -v /opt/grafana/provisioning:/etc/grafana/provisioning \
  -e GF_SECURITY_ADMIN_PASSWORD=admin \
  -e GF_SECURITY_ADMIN_USER=admin \
  -e GF_INSTALL_PLUGINS=grafana-clock-panel \
  grafana/grafana:latest

# Wait for Grafana to start and provision dashboards
echo "Waiting for Grafana to start and load dashboards..."
sleep 45

# Verify Grafana is running and dashboards are loaded
echo "Verifying Grafana startup..."
docker ps | grep grafana > /dev/null && echo "✓ Grafana container is running"

# Test API and dashboards
sleep 15
DASHBOARDS=$(curl -s http://admin:admin@localhost:3000/api/search?type=dash-db | jq -r '.[].title' 2>/dev/null)
if [ -n "$DASHBOARDS" ]; then
    echo "✓ Dashboards loaded successfully:"
    echo "$DASHBOARDS"
else
    echo "⚠ Dashboards may still be loading..."
fi

echo "Grafana setup completed!"
echo "Access Grafana at http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo "Default credentials: admin/admin"
echo "Check /var/log/cloud-init-output.log for detailed logs"