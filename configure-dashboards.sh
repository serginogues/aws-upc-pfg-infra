#!/bin/bash

# Script to configure Grafana dashboards on EC2 instance

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🚀 Configuring Grafana dashboards...${NC}"

# Get Grafana EC2 IP
GRAFANA_IP=$(terraform output -raw grafana_ec2_public_ip)
S3_BUCKET_NAME=$(terraform output -raw grafana_provisioning_bucket_name)

echo -e "${GREEN}✅ Grafana IP: $GRAFANA_IP${NC}"
echo -e "${GREEN}✅ S3 Bucket: $S3_BUCKET_NAME${NC}"

# Create a script to run on the EC2 instance
cat > ./configure-dashboards-remote.sh << 'EOF'
#!/bin/bash

echo "Starting dashboard configuration..."

# Create directories
docker exec grafana mkdir -p /etc/grafana/provisioning/dashboards
docker exec grafana mkdir -p /etc/grafana/provisioning/datasources

# Download files from S3
aws s3 cp s3://BUCKET_NAME/dashboards/lambda-monitoring.json /tmp/lambda-monitoring.json --region us-east-1
aws s3 cp s3://BUCKET_NAME/dashboards/dynamodb-monitoring.json /tmp/dynamodb-monitoring.json --region us-east-1
aws s3 cp s3://BUCKET_NAME/dashboards/dashboards.yml /tmp/dashboards.yml --region us-east-1
aws s3 cp s3://BUCKET_NAME/datasources/cloudwatch.yml /tmp/cloudwatch.yml --region us-east-1

# Copy files to Grafana container
docker cp /tmp/lambda-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dynamodb-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dashboards.yml grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/cloudwatch.yml grafana:/etc/grafana/provisioning/datasources/

# Set proper permissions
docker exec grafana chown -R 472:472 /etc/grafana/provisioning

# Restart Grafana
docker restart grafana

# Clean up
rm -f /tmp/*.json /tmp/*.yml

echo "Dashboard configuration completed successfully!"
EOF

# Replace bucket name in the script
sed -i "s/BUCKET_NAME/$S3_BUCKET_NAME/g" ./configure-dashboards-remote.sh

# Wait for SSH to be ready
echo -e "${YELLOW}⏳ Waiting for SSH to be ready...${NC}"
sleep 10

# Test SSH connection
echo -e "${YELLOW}🔍 Testing SSH connection...${NC}"
if ! ssh -i bastion-key.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@$GRAFANA_IP "echo 'SSH connection successful'" >/dev/null 2>&1; then
    echo -e "${RED}❌ SSH connection failed. Retrying in 30 seconds...${NC}"
    sleep 30
fi

# Execute dashboard configuration via SSH
echo -e "${GREEN}🚀 Executing dashboard configuration via SSH...${NC}"

ssh -i bastion-key.pem -o StrictHostKeyChecking=no ec2-user@$GRAFANA_IP << 'EOF'
echo "Starting dashboard configuration..."

# Create directories
docker exec grafana mkdir -p /etc/grafana/provisioning/dashboards
docker exec grafana mkdir -p /etc/grafana/provisioning/datasources

# Download files from S3
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/lambda-monitoring.json /tmp/lambda-monitoring.json --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dynamodb-monitoring.json /tmp/dynamodb-monitoring.json --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/dashboards/dashboards.yml /tmp/dashboards.yml --region us-east-1
aws s3 cp s3://aws-upc-pfg-infra-dev-grafana-provisioning-875gkede/datasources/cloudwatch.yml /tmp/cloudwatch.yml --region us-east-1

# Copy files to Grafana container
docker cp /tmp/lambda-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dynamodb-monitoring.json grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/dashboards.yml grafana:/etc/grafana/provisioning/dashboards/
docker cp /tmp/cloudwatch.yml grafana:/etc/grafana/provisioning/datasources/

# Set proper permissions
docker exec grafana chown -R 472:472 /etc/grafana/provisioning

# Restart Grafana
docker restart grafana

# Clean up
rm -f /tmp/*.json /tmp/*.yml

echo "Dashboard configuration completed successfully!"
EOF

echo -e "${GREEN}✅ Dashboard configuration completed via SSH${NC}"

# Clean up local script
rm -f ./configure-dashboards-remote.sh

echo -e "${GREEN}🎉 Dashboard configuration completed!${NC}"
echo -e "${GREEN}🌐 Access Grafana at: http://$GRAFANA_IP:3000${NC}"
echo -e "${YELLOW}📊 Default credentials: admin / $(terraform output -raw grafana_admin_password)${NC}"
