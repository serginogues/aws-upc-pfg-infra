# AWS UPC PFG Infrastructure - Grafana Monitoring

## 🏗️ Architecture Overview

This infrastructure deploys **Grafana in a private VPC** with secure access through a bastion host and CloudWatch integration.

### Key Components:
- **VPC** with public and private subnets
- **NAT Gateway** for internet access from private subnet
- **Bastion Host** in public subnet for secure access
- **Grafana** in private subnet (no public IP)
- **CloudWatch Integration** for AWS metrics monitoring
- **S3 Bucket** for Grafana dashboards and provisioning

## 🚀 Quick Start

### 1. Deploy Infrastructure
```bash
terraform init
terraform apply
```

### 2. Access Grafana
```bash
./access-grafana.sh
```
Grafana will be available at: `http://localhost:3000`
- **Username:** admin
- **Password:** admin123 (or as defined in terraform.tfvars)

### 3. Verify Architecture
```bash
./verify-architecture.sh
```

## 📁 Project Structure

```
├── bastion.tf              # Bastion host configuration
├── grafana.tf              # Grafana VPC, security groups, and instance
├── grafana-setup.sh        # Grafana installation script
├── access-grafana.sh       # Script to access Grafana via bastion
├── verify-architecture.sh  # Architecture verification script
├── grafana-provisioning/   # Grafana dashboards and datasources
│   ├── dashboards/
│   └── datasources/
└── terraform.tfvars        # Configuration variables
```

## 🔐 Security Features

- **Private Subnet Deployment:** Grafana has no public IP
- **Bastion Access Only:** SSH access only through bastion host
- **IAM Permissions:** Least privilege access to CloudWatch
- **Encrypted Storage:** All EBS volumes encrypted
- **Security Groups:** Restrictive firewall rules

## 📊 Monitoring

Pre-configured dashboards for:
- **AWS Lambda** metrics (invocations, errors, duration)
- **DynamoDB** metrics (read/write capacity, item count)
- **CloudWatch** logs integration

## 🛠️ Configuration

Edit `terraform.tfvars` to customize:
- `account_name`: Your AWS account name
- `environment`: Deployment environment (dev/prod)
- `grafana_admin_password`: Grafana admin password
- `grafana_instance_type`: EC2 instance type for Grafana

## 🔧 Troubleshooting

### Cannot connect to Grafana
1. Verify bastion host is running: `terraform output bastion_public_ip`
2. Check SSH key permissions: `chmod 600 bastion-key.pem`
3. Test bastion connectivity: `ssh -i bastion-key.pem ec2-user@<bastion-ip>`

### Grafana not loading dashboards
1. Check CloudWatch datasource configuration
2. Verify IAM permissions for Grafana user
3. Check S3 bucket access for dashboard files

## 📝 S3 Backend Setup

The Terraform state is stored in S3. To set up the backend bucket:

```bash
# Create the bucket (replace with your account name)
aws s3api create-bucket --bucket aws-upc-pfg-infra-tfstate-bucket-{account-name} --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket aws-upc-pfg-infra-tfstate-bucket-{account-name} --versioning-configuration Status=Enabled

# Apply bucket policy
aws s3api put-bucket-policy --bucket aws-upc-pfg-infra-tfstate-bucket-{account-name} --policy file://tfstate-s3-bucket-policy.json
```
