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

# Create provisioning directory structure (for future use)
mkdir -p provisioning/datasources
mkdir -p provisioning/dashboards

# Start Grafana with Docker Compose
docker-compose up -d

# Wait for Grafana to start and be ready
echo "Waiting for Grafana to be ready..."
for i in {1..30}; do
  if curl -s http://localhost:3000/api/health > /dev/null 2>&1; then
    echo "Grafana is ready!"
    break
  fi
  echo "Attempt $i/30: Grafana not ready yet, waiting..."
  sleep 10
done

# Log completion
echo "Grafana installation completed at $(date)" >> /var/log/grafana-setup.log
echo "Access Grafana at: http://$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4):3000" >> /var/log/grafana-setup.log
echo "Admin password: ${grafana_admin_password}" >> /var/log/grafana-setup.log
echo "IMPORTANT: Grafana is deployed in private subnet - use SSH tunnel or bastion host to access" >> /var/log/grafana-setup.log
echo "IMPORTANT: Configure CloudWatch datasource manually with IAM user credentials" >> /var/log/grafana-setup.log