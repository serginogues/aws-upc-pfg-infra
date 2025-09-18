#!/bin/bash

# Update system
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create Grafana directory
mkdir -p /opt/grafana
cd /opt/grafana

# Create docker-compose.yml for Grafana
cat > docker-compose.yml << 'EOF'
version: '3.8'
services:
  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=${grafana_admin_password}
      - GF_INSTALL_PLUGINS=grafana-clock-panel,grafana-simple-json-datasource,grafana-piechart-panel
      - GF_AWS_ALLOWED_AUTH_PROVIDERS=default,keys,credentials
      - GF_AWS_DEFAULT_REGION=${region}
    volumes:
      - grafana-storage:/var/lib/grafana
      - ./provisioning:/etc/grafana/provisioning
    networks:
      - grafana-network
volumes:
  grafana-storage:
networks:
  grafana-network:
    driver: bridge
EOF

# Create provisioning directories
mkdir -p provisioning/datasources provisioning/dashboards

# Create dashboard provisioning configuration
cat > provisioning/dashboards/dashboard-config.yaml << 'EOF'
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
EOF

# Generate CloudWatch datasource
cat > provisioning/datasources/cloudwatch.yaml << 'EOF'
apiVersion: 1
datasources:
  - name: CloudWatch
    type: cloudwatch
    access: proxy
    url: https://monitoring.${region}.amazonaws.com
    jsonData:
      authType: keys
      defaultRegion: ${region}
      accessKey: ${access_key}
      secretKey: ${secret_key}
    isDefault: true
    editable: true
EOF

# Download provisioning files from S3
aws s3 cp s3://aws-upc-pfg-lambda-bucket-marc10010/grafana-provisioning/datasources/cloudwatch.yaml provisioning/datasources/
aws s3 cp s3://aws-upc-pfg-lambda-bucket-marc10010/grafana-provisioning/dashboards/lambda-monitoring.json provisioning/dashboards/
aws s3 cp s3://aws-upc-pfg-lambda-bucket-marc10010/grafana-provisioning/dashboards/dynamodb-monitoring.json provisioning/dashboards/
aws s3 cp s3://aws-upc-pfg-lambda-bucket-marc10010/grafana-provisioning/dashboards/dashboard-config.yaml provisioning/dashboards/

# Start Grafana
docker-compose up -d

# Wait for Grafana
echo "Waiting for Grafana..."
for i in {1..30}; do
  if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "Grafana ready!"
    break
  fi
  echo "Attempt $i/30: Waiting..."
  sleep 10
done

# Log completion
echo "Grafana installation completed at $(date)" >> /var/log/grafana-setup.log
echo "Access: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):3000" >> /var/log/grafana-setup.log
echo "Password: ${grafana_admin_password}" >> /var/log/grafana-setup.log
echo "IMPORTANT: Configure CloudWatch datasource manually with IAM user credentials" >> /var/log/grafana-setup.log