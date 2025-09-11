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

# Public Subnet
resource "aws_subnet" "grafana_public" {
  vpc_id                  = aws_vpc.grafana_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-grafana-public"
    Environment = var.environment
    Project     = var.app-name
  }
}

# Route Table
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

# Route Table Association
resource "aws_route_table_association" "grafana_public" {
  subnet_id      = aws_subnet.grafana_public.id
  route_table_id = aws_route_table.grafana_public.id
}

# =============================================================================
# SECURITY GROUPS
# =============================================================================

# Security Group for Grafana
resource "aws_security_group" "grafana" {
  name_prefix = "${local.name_prefix}-grafana-"
  vpc_id      = aws_vpc.grafana_vpc.id

  # HTTP access
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Grafana HTTP"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "HTTPS"
  }

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "SSH"
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
    Name        = "${local.name_prefix}-grafana-sg"
    Environment = var.environment
    Project     = var.app-name
  }
}

# =============================================================================
# IAM ROLE FOR GRAFANA
# =============================================================================

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
  }))
}

# EC2 Instance for Grafana
resource "aws_instance" "grafana" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.grafana_instance_type
  subnet_id              = aws_subnet.grafana_public.id
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
  }
}

# Elastic IP for Grafana
resource "aws_eip" "grafana" {
  instance = aws_instance.grafana.id
  domain   = "vpc"

  tags = {
    Name        = "${local.name_prefix}-grafana-eip"
    Environment = var.environment
    Project     = var.app-name
  }
}

# =============================================================================
# OUTPUTS
# =============================================================================

output "grafana_url" {
  description = "URL to access Grafana"
  value       = "http://${aws_eip.grafana.public_ip}:3000"
}

output "grafana_public_ip" {
  description = "Public IP of Grafana instance"
  value       = aws_eip.grafana.public_ip
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
