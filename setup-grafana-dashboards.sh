#!/bin/bash

# Script to manually setup Grafana dashboards
# This script connects to the Grafana ECS task and downloads dashboards

set -e

echo "🚀 Setting up Grafana dashboards manually..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get Grafana IP
echo -e "${BLUE}📡 Getting Grafana IP...${NC}"
GRAFANA_IP=$(./get-grafana-ip.sh)
if [ -z "$GRAFANA_IP" ]; then
    echo -e "${RED}❌ Error: Could not get Grafana IP${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Grafana IP: $GRAFANA_IP${NC}"

# Get Bastion IP
echo -e "${BLUE}📡 Getting Bastion IP...${NC}"
BASTION_IP=$(terraform output -raw bastion_public_ip)
if [ -z "$BASTION_IP" ]; then
    echo -e "${RED}❌ Error: Could not get Bastion IP${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Bastion IP: $BASTION_IP${NC}"

# Get S3 bucket name
echo -e "${BLUE}📦 Getting S3 bucket name...${NC}"
S3_BUCKET=$(terraform output -raw grafana_provisioning_bucket_name)
if [ -z "$S3_BUCKET" ]; then
    echo -e "${RED}❌ Error: Could not get S3 bucket name${NC}"
    exit 1
fi
echo -e "${GREEN}✅ S3 Bucket: $S3_BUCKET${NC}"

# Create local provisioning directory
echo -e "${BLUE}📁 Creating local provisioning directory...${NC}"
mkdir -p ./grafana-provisioning-local/dashboards
mkdir -p ./grafana-provisioning-local/datasources

# Download files from S3 to local directory
echo -e "${BLUE}📥 Downloading files from S3...${NC}"
aws s3 cp s3://$S3_BUCKET/dashboards/lambda-monitoring.json ./grafana-provisioning-local/dashboards/ --region us-east-1
aws s3 cp s3://$S3_BUCKET/dashboards/dynamodb-monitoring.json ./grafana-provisioning-local/dashboards/ --region us-east-1
aws s3 cp s3://$S3_BUCKET/dashboards/dashboards.yml ./grafana-provisioning-local/dashboards/ --region us-east-1
aws s3 cp s3://$S3_BUCKET/datasources/cloudwatch.yml ./grafana-provisioning-local/datasources/ --region us-east-1

echo -e "${GREEN}✅ Files downloaded locally${NC}"

# Upload files directly to S3 and restart Grafana
echo -e "${BLUE}📤 Uploading files to S3 provisioning bucket...${NC}"

# Upload files to the provisioning bucket
aws s3 cp ./grafana-provisioning-local/dashboards/lambda-monitoring.json s3://$S3_BUCKET/dashboards/ --region us-east-1
aws s3 cp ./grafana-provisioning-local/dashboards/dynamodb-monitoring.json s3://$S3_BUCKET/dashboards/ --region us-east-1
aws s3 cp ./grafana-provisioning-local/dashboards/dashboards.yml s3://$S3_BUCKET/dashboards/ --region us-east-1
aws s3 cp ./grafana-provisioning-local/datasources/cloudwatch.yml s3://$S3_BUCKET/datasources/ --region us-east-1

echo -e "${GREEN}✅ Files uploaded to S3${NC}"

# Create a simple script that will download and setup files
echo -e "${BLUE}📤 Creating setup script...${NC}"

cat > ./setup-dashboards.sh << EOF
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
aws s3 cp s3://$S3_BUCKET/dashboards/lambda-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1
aws s3 cp s3://$S3_BUCKET/dashboards/dynamodb-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1
aws s3 cp s3://$S3_BUCKET/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/ --region us-east-1
aws s3 cp s3://$S3_BUCKET/datasources/cloudwatch.yml /etc/grafana/provisioning/datasources/ --region us-east-1

# Set permissions
chown -R 472:472 /etc/grafana/provisioning
chmod -R 755 /etc/grafana/provisioning

echo "✅ Dashboards setup completed"
ls -la /etc/grafana/provisioning/dashboards/
ls -la /etc/grafana/provisioning/datasources/
EOF

# Upload the setup script to S3
aws s3 cp ./setup-dashboards.sh s3://$S3_BUCKET/setup-dashboards.sh --region us-east-1

echo -e "${GREEN}✅ Setup script uploaded to S3${NC}"

# Now we need to modify the Grafana task definition to run this script
echo -e "${BLUE}📤 Updating Grafana task definition...${NC}"

# Create a new task definition that runs the setup script
cat > ./grafana-task-definition.json << EOF
{
  "family": "aws-upc-pfg-infra-dev-grafana",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "512",
  "memory": "1024",
  "executionRoleArn": "arn:aws:iam::389011575948:role/aws-upc-pfg-infra-dev-ecs-execution-role",
  "taskRoleArn": "arn:aws:iam::389011575948:role/aws-upc-pfg-infra-dev-ecs-task-role",
  "containerDefinitions": [
    {
      "name": "grafana",
      "image": "grafana/grafana:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "command": [
        "sh",
        "-c",
        "echo 'Starting Grafana with dashboard setup...' && apk add --no-cache curl unzip && curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip' && unzip awscliv2.zip && ./aws/install && mkdir -p /etc/grafana/provisioning/dashboards /etc/grafana/provisioning/datasources && aws s3 cp s3://$S3_BUCKET/dashboards/lambda-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1 && aws s3 cp s3://$S3_BUCKET/dashboards/dynamodb-monitoring.json /etc/grafana/provisioning/dashboards/ --region us-east-1 && aws s3 cp s3://$S3_BUCKET/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/ --region us-east-1 && aws s3 cp s3://$S3_BUCKET/datasources/cloudwatch.yml /etc/grafana/provisioning/datasources/ --region us-east-1 && chown -R 472:472 /etc/grafana/provisioning && echo 'Dashboards setup completed!' && /run.sh"
      ],
      "environment": [
        {
          "name": "GF_SECURITY_ADMIN_PASSWORD",
          "value": "admin"
        },
        {
          "name": "GF_INSTALL_PLUGINS",
          "value": "grafana-piechart-panel,grafana-clock-panel"
        },
        {
          "name": "GF_SECURITY_ALLOW_EMBEDDING",
          "value": "true"
        },
        {
          "name": "GF_AUTH_ANONYMOUS_ENABLED",
          "value": "false"
        },
        {
          "name": "GF_SERVER_ROOT_URL",
          "value": "http://localhost:3000"
        },
        {
          "name": "GF_PATHS_PROVISIONING",
          "value": "/etc/grafana/provisioning"
        },
        {
          "name": "GF_DATABASE_TYPE",
          "value": "sqlite3"
        },
        {
          "name": "GF_DATABASE_PATH",
          "value": "/var/lib/grafana/grafana.db"
        }
      ],
      "mountPoints": [
        {
          "sourceVolume": "grafana-provisioning",
          "containerPath": "/etc/grafana/provisioning",
          "readOnly": false
        }
      ],
      "healthCheck": {
        "command": [
          "CMD-SHELL",
          "curl -f http://localhost:3000/api/health || exit 1"
        ],
        "interval": 30,
        "timeout": 5,
        "retries": 3,
        "startPeriod": 60
      },
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/aws-upc-pfg-infra-dev-grafana",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "essential": true
    }
  ],
  "volumes": [
    {
      "name": "grafana-provisioning"
    }
  ]
}
EOF

# Register the new task definition
echo -e "${BLUE}📤 Registering new task definition...${NC}"
TASK_DEF_ARN=$(aws ecs register-task-definition --cli-input-json file://grafana-task-definition.json --region us-east-1 --query 'taskDefinition.arn' --output text)

echo -e "${GREEN}✅ New task definition registered: $TASK_DEF_ARN${NC}"

# Update the service to use the new task definition
echo -e "${BLUE}🔄 Updating ECS service...${NC}"
aws ecs update-service --cluster aws-upc-pfg-infra-dev-grafana-cluster --service aws-upc-pfg-infra-dev-grafana --task-definition $TASK_DEF_ARN --region us-east-1

echo -e "${GREEN}✅ Service updated successfully${NC}"

# Cleanup
rm -f ./copy-files.sh
rm -rf ./grafana-provisioning-local

echo -e "${GREEN}🎉 Grafana dashboards setup completed successfully!${NC}"
echo -e "${YELLOW}📝 You can now access Grafana at http://localhost:3000${NC}"
echo -e "${YELLOW}   Run: ./access-grafana.sh${NC}"
