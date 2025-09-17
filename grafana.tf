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

  # SSH access - only from VPC (for bastion access)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.grafana_vpc.cidr_block]
    description = "SSH from VPC"
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
    access_method  = "VPN or direct VPC access required"
    grafana_url    = "http://${aws_instance.grafana.private_ip}:3000"
  }
}
