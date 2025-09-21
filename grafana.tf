# Grafana EC2 Instance and related resources

# Data source to get Ubuntu 22.04 LTS AMI (allows 8GB volumes)
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Data source to get current public IP for SSH restriction
data "http" "current_ip" {
  url = "https://ipv4.icanhazip.com"
}

# Security Group for Grafana
resource "aws_security_group" "grafana_sg" {
  name        = "${local.name_prefix}-grafana-sg"
  description = "Security group for Grafana instance"

  # Grafana web interface
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Grafana web interface"
  }

  # SSH access restricted to current public IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.current_ip.response_body)}/32"]
    description = "SSH access from current IP"
  }

  # Outbound traffic (for Docker pulls, updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${local.name_prefix}-grafana-sg"
  }
}

# IAM Role for Grafana to access CloudWatch
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
    Name = "${local.name_prefix}-grafana-role"
  }
}

# IAM Policy for CloudWatch access
resource "aws_iam_policy" "grafana_cloudwatch_policy" {
  name        = "${local.name_prefix}-grafana-cloudwatch-policy"
  description = "Policy for Grafana to access CloudWatch metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:DescribeAlarmsForMetric",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:TestMetricFilter",
          "ec2:DescribeTags",
          "ec2:DescribeInstances",
          "ec2:DescribeRegions",
          "tag:GetResources"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "grafana_cloudwatch_attachment" {
  role       = aws_iam_role.grafana_role.name
  policy_arn = aws_iam_policy.grafana_cloudwatch_policy.arn
}

# Instance profile for the role
resource "aws_iam_instance_profile" "grafana_instance_profile" {
  name = "${local.name_prefix}-grafana-instance-profile"
  role = aws_iam_role.grafana_role.name
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get default subnet (first available)
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

# S3 bucket for storing dashboard files
resource "aws_s3_bucket" "grafana_dashboards" {
  bucket = "${local.name_prefix}-grafana-dashboards"
}

resource "aws_s3_bucket_public_access_block" "grafana_dashboards" {
  bucket = aws_s3_bucket.grafana_dashboards.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "grafana_dashboards" {
  bucket = aws_s3_bucket.grafana_dashboards.id
  depends_on = [aws_s3_bucket_public_access_block.grafana_dashboards]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.grafana_dashboards.arn}/*"
      }
    ]
  })
}

# Upload dashboard files to S3 (processed as templates)
resource "aws_s3_object" "lambda_dashboard" {
  bucket = aws_s3_bucket.grafana_dashboards.bucket
  key    = "lambda-dashboard.json"
  content = templatefile("${path.module}/grafana-dashboards/lambda-dashboard.json", {
    name_prefix = local.name_prefix
    region = var.region
  })
  content_type = "application/json"
}

resource "aws_s3_object" "dynamodb_dashboard" {
  bucket = aws_s3_bucket.grafana_dashboards.bucket
  key    = "dynamodb-dashboard.json"
  content = templatefile("${path.module}/grafana-dashboards/dynamodb-dashboard.json", {
    name_prefix = local.name_prefix
    region = var.region
  })
  content_type = "application/json"
}

resource "aws_s3_object" "sqs_dashboard" {
  bucket = aws_s3_bucket.grafana_dashboards.bucket
  key    = "sqs-dashboard.json"
  content = templatefile("${path.module}/grafana-dashboards/sqs-dashboard.json", {
    name_prefix = local.name_prefix
    region = var.region
  })
  content_type = "application/json"
}

# User data script (now much shorter)
locals {
  grafana_user_data = base64encode(templatefile("${path.module}/scripts/grafana-setup.sh", {
    region = var.region
    name_prefix = local.name_prefix
    dashboard_bucket = aws_s3_bucket.grafana_dashboards.bucket
  }))
}

# Create a key pair for SSH access
resource "aws_key_pair" "grafana_key" {
  key_name   = "${local.name_prefix}-grafana-key"
  public_key = file("~/.ssh/grafana_key.pub")
}

# Grafana EC2 Instance
resource "aws_instance" "grafana" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.grafana_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.grafana_instance_profile.name
  key_name               = aws_key_pair.grafana_key.key_name
  
  user_data = local.grafana_user_data

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name = "${local.name_prefix}-grafana"
    Purpose = "Monitoring"
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  # Wait for the instance to be fully ready before considering it created
  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait"
    ]
    
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("~/.ssh/grafana_key")
      host        = self.public_ip
    }
  }
}
