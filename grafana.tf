# =============================================================================
# VPC AND NETWORKING
# =============================================================================

# VPC for Grafana
resource "aws_vpc" "grafana_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.name_prefix}-grafana-vpc"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "grafana_igw" {
  vpc_id = aws_vpc.grafana_vpc.id

  tags = {
    Name        = "${local.name_prefix}-grafana-igw"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Public Subnet (for NAT Gateway)
resource "aws_subnet" "grafana_public" {
  vpc_id                  = aws_vpc.grafana_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-grafana-public"
    Environment = var.environment
    Project     = var.app-name
    Type        = "public"
  }
}

# Private Subnet (for Grafana)
resource "aws_subnet" "grafana_private" {
  vpc_id            = aws_vpc.grafana_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.region}a"

  tags = {
    Name        = "${local.name_prefix}-grafana-private"
    Environment = var.environment
    Project     = var.app-name
    Type        = "private"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "grafana_nat" {
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-grafana-nat-eip"
    Environment = var.environment
    Project     = var.app-name
  }

  depends_on = [aws_internet_gateway.grafana_igw]
}

# NAT Gateway
resource "aws_nat_gateway" "grafana_nat" {
  allocation_id = aws_eip.grafana_nat.id
  subnet_id     = aws_subnet.grafana_public.id

  tags = {
    Name        = "${local.name_prefix}-grafana-nat"
    Environment = var.environment
    Project     = var.app-name
  }

  depends_on = [aws_internet_gateway.grafana_igw]
}

# Public Route Table
resource "aws_route_table" "grafana_public" {
  vpc_id = aws_vpc.grafana_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.grafana_igw.id
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-public-rt"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Private Route Table
resource "aws_route_table" "grafana_private" {
  vpc_id = aws_vpc.grafana_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.grafana_nat.id
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-private-rt"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Public Route Table Association
resource "aws_route_table_association" "grafana_public" {
  subnet_id      = aws_subnet.grafana_public.id
  route_table_id = aws_route_table.grafana_public.id
}

# Private Route Table Association
resource "aws_route_table_association" "grafana_private" {
  subnet_id      = aws_subnet.grafana_private.id
  route_table_id = aws_route_table.grafana_private.id
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  name_prefix = "${local.name_prefix}-bastion-"
  vpc_id      = aws_vpc.grafana_vpc.id

  # SSH access from anywhere (for bastion access)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH from anywhere"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${local.name_prefix}-bastion-sg"
    Environment = var.environment
    Project     = var.app-name
    Subnet      = "public"
  }
}

# Security Group for Grafana
resource "aws_security_group" "grafana" {
  name_prefix = "${local.name_prefix}-grafana-"
  vpc_id      = aws_vpc.grafana_vpc.id

  # HTTP access - only from VPC
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.grafana_vpc.cidr_block]
    description = "Grafana HTTP from VPC"
  }

  # HTTPS access - only from VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.grafana_vpc.cidr_block]
    description = "HTTPS from VPC"
  }

  # SSH access - only from bastion host
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "SSH from bastion host"
  }

  # All outbound traffic (needed for CloudWatch API calls)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-sg"
    Environment = var.environment
    Project     = var.app-name
    Subnet      = "private"
  }
}

# =============================================================================
# BASTION HOST
# =============================================================================

# Generate SSH key pair for bastion
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "${local.name_prefix}-bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh

  tags = {
    Name        = "${local.name_prefix}-bastion-key"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Save private key to file
resource "local_file" "bastion_private_key" {
  content  = tls_private_key.bastion_key.private_key_pem
  filename = "${path.module}/bastion-key.pem"
  file_permission = "0400"
}

# Bastion Host EC2 Instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.grafana_public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]
  key_name               = aws_key_pair.bastion_key.key_name

  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name        = "${local.name_prefix}-bastion"
    Environment = var.environment
    Project     = var.app-name
    Service     = "bastion"
    Subnet      = "public"
  }
}

# =============================================================================
# IAM ROLE FOR GRAFANA
# =============================================================================

# IAM User for Grafana
resource "aws_iam_user" "grafana_user" {
  name = "${local.name_prefix}-grafana-user"
  path = "/"

  tags = {
    Name        = "${local.name_prefix}-grafana-user"
    Environment = var.environment
    Project     = var.app-name
    Service     = "monitoring"
  }
}

# IAM Policy for Grafana CloudWatch access
resource "aws_iam_policy" "grafana_user_cloudwatch" {
  name        = "${local.name_prefix}-grafana-user-cloudwatch"
  description = "Policy for Grafana user to access CloudWatch metrics and logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:DescribeAlarms",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-grafana-user-cloudwatch-policy"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Attach policy to user
resource "aws_iam_user_policy_attachment" "grafana_user_cloudwatch" {
  user       = aws_iam_user.grafana_user.name
  policy_arn = aws_iam_policy.grafana_user_cloudwatch.arn
}

# Create access keys for Grafana user
resource "aws_iam_access_key" "grafana_user" {
  user = aws_iam_user.grafana_user.name
}

# IAM Role for Grafana EC2 instance
resource "aws_iam_role" "grafana_role" {
  name = "${local.name_prefix}-grafana-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-grafana-role"
    Environment = var.environment
    Project     = var.app-name
  }
}

# IAM Policy for CloudWatch access
resource "aws_iam_policy" "grafana_cloudwatch" {
  name        = "${local.name_prefix}-grafana-cloudwatch"
  description = "Policy for Grafana to access CloudWatch metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:DescribeAlarms",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-grafana-cloudwatch-policy"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "grafana_cloudwatch" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = aws_iam_policy.grafana_cloudwatch.arn
}

# Attach AWS managed policy for EC2
resource "aws_iam_role_policy_attachment" "grafana_ec2" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Attach AWS managed policy for Systems Manager
resource "aws_iam_role_policy_attachment" "grafana_ssm" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "grafana_profile" {
  name = "${local.name_prefix}-grafana-profile"
  role = aws_iam_role.grafana_role.name

  tags = {
    Name        = "${local.name_prefix}-grafana-profile"
    Environment = var.environment
    Project     = var.app-name
  }
}

# =============================================================================
# EC2 INSTANCE
# =============================================================================

# Get latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script for Grafana installation
locals {
  grafana_user_data = base64encode(templatefile("${path.module}/grafana-user-data.sh", {
    grafana_admin_password = var.grafana_admin_password
    region                 = var.region
    access_key             = aws_iam_access_key.grafana_user.id
    secret_key             = aws_iam_access_key.grafana_user.secret
    secrets_function       = aws_lambda_function.secrets_function.function_name
    acknowledge_function   = aws_lambda_function.acknowledge_function.function_name
    qrcode_function        = aws_lambda_function.qrcode_generator_function.function_name
    dynamodb_table         = aws_dynamodb_table.secrets.name
  }))
}

# Upload provisioning files to S3
resource "aws_s3_object" "grafana_datasource" {
  bucket = "aws-upc-pfg-lambda-bucket-${var.account_name}"
  key    = "grafana-provisioning/datasources/cloudwatch.yaml"
  content = templatefile("${path.module}/grafana-provisioning/datasources/cloudwatch.yaml", {
    region     = var.region
    access_key = aws_iam_access_key.grafana_user.id
    secret_key = aws_iam_access_key.grafana_user.secret
  })
}

resource "aws_s3_object" "grafana_lambda_dashboard" {
  bucket = "aws-upc-pfg-lambda-bucket-${var.account_name}"
  key    = "grafana-provisioning/dashboards/lambda-monitoring.json"
  content = templatefile("${path.module}/grafana-provisioning/dashboards/lambda-monitoring.json", {
    region              = var.region
    secrets_function    = aws_lambda_function.secrets_function.function_name
    acknowledge_function = aws_lambda_function.acknowledge_function.function_name
    qrcode_function     = aws_lambda_function.qrcode_generator_function.function_name
  })
}

resource "aws_s3_object" "grafana_dynamodb_dashboard" {
  bucket = "aws-upc-pfg-lambda-bucket-${var.account_name}"
  key    = "grafana-provisioning/dashboards/dynamodb-monitoring.json"
  content = templatefile("${path.module}/grafana-provisioning/dashboards/dynamodb-monitoring.json", {
    region        = var.region
    dynamodb_table = aws_dynamodb_table.secrets.name
  })
}

resource "aws_s3_object" "grafana_dashboard_config" {
  bucket = "aws-upc-pfg-lambda-bucket-${var.account_name}"
  key    = "grafana-provisioning/dashboards/dashboard-config.yaml"
  content = file("${path.module}/grafana-provisioning/dashboards/dashboard-config.yaml")
}

# Wait for Grafana to be ready
resource "time_sleep" "wait_for_grafana" {
  depends_on = [aws_instance.grafana]
  
  create_duration = "5m"
}

# EC2 Instance for Grafana
resource "aws_instance" "grafana" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.grafana_instance_type
  subnet_id              = aws_subnet.grafana_private.id
  vpc_security_group_ids = [aws_security_group.grafana.id]
  iam_instance_profile   = aws_iam_instance_profile.grafana_profile.name

  user_data = local.grafana_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name        = "${local.name_prefix}-grafana"
    Environment = var.environment
    Project     = var.app-name
    Service     = "monitoring"
    Subnet      = "private"
  }
}

# Note: No Elastic IP needed for private subnet deployment

# =============================================================================
# OUTPUTS
# =============================================================================

output "grafana_private_ip" {
  description = "Private IP of Grafana instance"
  value       = aws_instance.grafana.private_ip
}

output "grafana_instance_id" {
  description = "Instance ID of Grafana"
  value       = aws_instance.grafana.id
}

output "grafana_admin_password" {
  description = "Admin password for Grafana (sensitive)"
  value       = var.grafana_admin_password
  sensitive   = true
}

output "grafana_access_info" {
  description = "Information about accessing Grafana in private subnet"
  value = {
    private_ip     = aws_instance.grafana.private_ip
    instance_id    = aws_instance.grafana.id
    vpc_id         = aws_vpc.grafana_vpc.id
    subnet_id      = aws_subnet.grafana_private.id
    access_method  = "Use bastion host to access Grafana"
    grafana_url    = "http://${aws_instance.grafana.private_ip}:3000"
  }
}

output "bastion_access_info" {
  description = "Information about accessing the bastion host"
  value = {
    public_ip      = aws_instance.bastion.public_ip
    instance_id    = aws_instance.bastion.id
    private_key    = "bastion-key.pem"
    ssh_command    = "ssh -i bastion-key.pem ec2-user@${aws_instance.bastion.public_ip}"
    grafana_tunnel = "ssh -i bastion-key.pem -L 3000:${aws_instance.grafana.private_ip}:3000 ec2-user@${aws_instance.bastion.public_ip}"
  }
}

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_instance.bastion.public_ip
}

output "grafana_cloudwatch_credentials" {
  description = "Credentials for CloudWatch datasource configuration"
  value = {
    access_key_id     = aws_iam_access_key.grafana_user.id
    secret_access_key = aws_iam_access_key.grafana_user.secret
    region           = var.region
  }
  sensitive = true
}

output "grafana_manual_setup_instructions" {
  description = "Instructions for manual CloudWatch datasource setup"
  value = <<-EOT
    If automatic datasource creation fails, configure manually:
    
    1. Go to Configuration → Data Sources → Add data source → CloudWatch
    2. Set Authentication Provider to "Keys"
    3. Access Key ID: [use grafana_cloudwatch_credentials output]
    4. Secret Access Key: [use grafana_cloudwatch_credentials output]
    5. Default Region: ${var.region}
    6. Click "Save & Test"
    
    Grafana URL: http://${aws_instance.grafana.private_ip}:3000
    Admin Password: ${var.grafana_admin_password}
  EOT
  sensitive = true
}

output "lambda_function_names" {
  description = "Lambda function names for dashboard configuration"
  value = {
    secrets_function     = aws_lambda_function.secrets_function.function_name
    acknowledge_function = aws_lambda_function.acknowledge_function.function_name
    qrcode_function      = aws_lambda_function.qrcode_generator_function.function_name
  }
}

output "grafana_datasource_uid" {
  description = "Grafana CloudWatch datasource UID for dashboard configuration"
  value       = "cloudwatch"  # Default UID for CloudWatch datasource
}

output "grafana_dashboard_instructions" {
  description = "Instructions for creating dashboards manually"
  value = <<-EOT
    To create dashboards manually in Grafana:
    
    1. Go to Dashboards → New → New Dashboard
    2. Add Panel → Add Visualization
    3. Select CloudWatch as datasource
    4. Use these function names:
       - Secrets Function: ${aws_lambda_function.secrets_function.function_name}
       - Acknowledge Function: ${aws_lambda_function.acknowledge_function.function_name}
       - QR Code Function: ${aws_lambda_function.qrcode_generator_function.function_name}
    
    5. Recommended metrics:
       - AWS/Lambda Invocations
       - AWS/Lambda Errors
       - AWS/Lambda Duration
       - AWS/Lambda Throttles
       - AWS/Lambda ConcurrentExecutions
    
    6. Set dimensions: FunctionName = [function_name]
  EOT
}

output "grafana_user_access_key_id" {
  description = "Access Key ID for Grafana user"
  value       = aws_iam_access_key.grafana_user.id
  sensitive   = true
}

output "grafana_user_credentials" {
  description = "Grafana user credentials for CloudWatch access"
  value = {
    access_key_id     = aws_iam_access_key.grafana_user.id
    secret_access_key = aws_iam_access_key.grafana_user.secret
  }
  sensitive = true
}

output "grafana_user_secret_access_key" {
  description = "Secret Access Key for Grafana user"
  value       = aws_iam_access_key.grafana_user.secret
  sensitive   = true
}
