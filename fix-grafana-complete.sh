#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔧 Complete Grafana fix...${NC}"

# Get Grafana IP
GRAFANA_IP=$(terraform output -raw grafana_ec2_public_ip)

if [ -z "$GRAFANA_IP" ]; then
  echo -e "${RED}❌ Error: Could not get Grafana IP.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Grafana IP: $GRAFANA_IP${NC}"

# Fix everything via SSH
echo -e "${YELLOW}🔧 Applying complete Grafana fix...${NC}"

ssh -i bastion-key.pem -o StrictHostKeyChecking=no ec2-user@$GRAFANA_IP << 'EOF'
echo "Stopping Grafana container..."
docker stop grafana || true

echo "Removing old Grafana container..."
docker rm grafana || true

echo "Removing old volumes..."
docker volume rm grafana-data grafana-provisioning || true

echo "Creating new volumes..."
docker volume create grafana-data
docker volume create grafana-provisioning

echo "Starting new Grafana container..."
docker run -d \
  --name grafana \
  --restart unless-stopped \
  -p 3000:3000 \
  -e GF_SECURITY_ADMIN_PASSWORD=admin123 \
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

echo "Waiting for Grafana to start..."
sleep 30

echo "Creating provisioning directories..."
docker exec grafana mkdir -p /etc/grafana/provisioning/dashboards
docker exec grafana mkdir -p /etc/grafana/provisioning/datasources

echo "Downloading provisioning files from S3..."
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/lambda-monitoring.json /tmp/lambda-monitoring.json --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dynamodb-monitoring.json /tmp/dynamodb-monitoring.json --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dashboards.yml /tmp/dashboards.yml --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/datasources/cloudwatch.yml /tmp/cloudwatch.yml --region us-east-1

echo "Copying files to Grafana container..."
docker cp /tmp/lambda-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dynamodb-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dashboards.yml grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/cloudwatch.yml grafana:/etc/grafana/provisioning/datasources/

echo "Setting proper permissions..."
docker exec grafana chown -R 472:472 /etc/grafana/provisioning

echo "Restarting Grafana to apply changes..."
docker restart grafana

echo "Waiting for Grafana to restart..."
sleep 30

echo "Testing CloudWatch connection..."
docker exec grafana curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/datasources/proxy/cloudwatch/api/v1/query

echo "Cleaning up..."
rm -f /tmp/*.json /tmp/*.yml

echo "Complete Grafana fix applied!"
EOF

echo -e "${GREEN}✅ Complete Grafana fix applied!${NC}"
echo -e "${GREEN}🌐 Access Grafana at: http://$GRAFANA_IP:3000${NC}"
echo -e "${YELLOW}💡 Credentials: admin / admin123${NC}"
echo -e "${YELLOW}💡 Dashboards should now be visible${NC}"
