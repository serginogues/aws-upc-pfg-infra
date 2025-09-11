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

# Create provisioning directory structure
mkdir -p provisioning/datasources
mkdir -p provisioning/dashboards

# Create CloudWatch datasource configuration
cat > provisioning/datasources/cloudwatch.yml << 'EOF'
apiVersion: 1

datasources:
  - name: CloudWatch
    type: cloudwatch
    access: proxy
    url: https://monitoring.${region}.amazonaws.com
    jsonData:
      authType: default
      defaultRegion: ${region}
    isDefault: true
    editable: true
EOF

# Create dashboard configuration
cat > provisioning/dashboards/dashboard.yml << 'EOF'
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

# Create a basic Lambda monitoring dashboard
cat > provisioning/dashboards/lambda-dashboard.json << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "AWS Lambda Monitoring",
    "tags": ["lambda", "aws"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Lambda Invocations",
        "type": "graph",
        "targets": [
          {
            "expr": "AWS/Lambda Invocations",
            "refId": "A"
          }
        ],
        "yAxes": [
          {
            "label": "Invocations"
          }
        ],
        "xAxis": {
          "show": true
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        }
      },
      {
        "id": 2,
        "title": "Lambda Errors",
        "type": "graph",
        "targets": [
          {
            "expr": "AWS/Lambda Errors",
            "refId": "A"
          }
        ],
        "yAxes": [
          {
            "label": "Errors"
          }
        ],
        "xAxis": {
          "show": true
        },
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        }
      },
      {
        "id": 3,
        "title": "Lambda Duration",
        "type": "graph",
        "targets": [
          {
            "expr": "AWS/Lambda Duration",
            "refId": "A"
          }
        ],
        "yAxes": [
          {
            "label": "Duration (ms)"
          }
        ],
        "xAxis": {
          "show": true
        },
        "gridPos": {
          "h": 8,
          "w": 24,
          "x": 0,
          "y": 8
        }
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
EOF

# Start Grafana with Docker Compose
docker-compose up -d

# Wait for Grafana to start
sleep 30

# Configure CloudWatch datasource via API
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "CloudWatch",
    "type": "cloudwatch",
    "access": "proxy",
    "url": "https://monitoring.${region}.amazonaws.com",
    "jsonData": {
      "authType": "default",
      "defaultRegion": "${region}"
    },
    "isDefault": true
  }' \
  http://admin:${grafana_admin_password}@localhost:3000/api/datasources

# Log completion
echo "Grafana installation completed at $(date)" >> /var/log/grafana-setup.log
echo "Access Grafana at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000" >> /var/log/grafana-setup.log
echo "Admin password: ${grafana_admin_password}" >> /var/log/grafana-setup.log
