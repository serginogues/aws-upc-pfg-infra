#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔄 Updating CloudWatch datasource...${NC}"

# Get Grafana IP
GRAFANA_IP=$(terraform output -raw grafana_ec2_public_ip)

if [ -z "$GRAFANA_IP" ]; then
  echo -e "${RED}❌ Error: Could not get Grafana IP.${NC}"
  exit 1
fi

echo -e "${GREEN}✅ Grafana IP: $GRAFANA_IP${NC}"

# Update datasource via SSH
echo -e "${YELLOW}🔧 Updating CloudWatch datasource configuration...${NC}"

ssh -i bastion-key.pem -o StrictHostKeyChecking=no ec2-user@$GRAFANA_IP << 'EOF'
echo "Downloading updated datasource config..."
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/datasources/cloudwatch.yml /tmp/cloudwatch.yml --region us-east-1

echo "Copying to Grafana container..."
docker cp /tmp/cloudwatch.yml grafana:/etc/grafana/provisioning/datasources/

echo "Restarting Grafana..."
docker restart grafana

echo "Waiting for Grafana to restart..."
sleep 10

echo "Cleaning up..."
rm -f /tmp/cloudwatch.yml

echo "Datasource update completed!"
EOF

echo -e "${GREEN}✅ CloudWatch datasource updated successfully!${NC}"
echo -e "${GREEN}🌐 Access Grafana at: http://$GRAFANA_IP:3000${NC}"
echo -e "${YELLOW}💡 The region should now be pre-selected as 'us-east-1'${NC}"
