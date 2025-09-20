# Data source for Amazon Linux AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# VPC for Grafana
resource "aws_vpc" "grafana_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${local.name_prefix}-grafana-vpc"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "grafana_igw" {
  vpc_id = aws_vpc.grafana_vpc.id

  tags = {
    Name        = "${local.name_prefix}-grafana-igw"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Public Subnet
resource "aws_subnet" "grafana_public" {
  vpc_id                  = aws_vpc.grafana_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "${local.name_prefix}-grafana-public"
    Environment = var.environment
    Project     = var.project_name
    Type        = "public"
  }
}

# Private Subnet
resource "aws_subnet" "grafana_private" {
  vpc_id            = aws_vpc.grafana_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name        = "${local.name_prefix}-grafana-private"
    Environment = var.environment
    Project     = var.project_name
    Type        = "private"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "grafana_nat" {
  domain = "vpc"

  tags = {
    Name        = "${local.name_prefix}-grafana-nat-eip"
    Environment = var.environment
    Project     = var.project_name
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
    Project     = var.project_name
  }

  depends_on = [aws_internet_gateway.grafana_igw]
}

# Route Table for Public Subnet
resource "aws_route_table" "grafana_public" {
  vpc_id = aws_vpc.grafana_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.grafana_igw.id
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-public-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route Table for Private Subnet
resource "aws_route_table" "grafana_private" {
  vpc_id = aws_vpc.grafana_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.grafana_nat.id
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-private-rt"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Route Table Associations
resource "aws_route_table_association" "grafana_public" {
  subnet_id      = aws_subnet.grafana_public.id
  route_table_id = aws_route_table.grafana_public.id
}

resource "aws_route_table_association" "grafana_private" {
  subnet_id      = aws_subnet.grafana_private.id
  route_table_id = aws_route_table.grafana_private.id
}
