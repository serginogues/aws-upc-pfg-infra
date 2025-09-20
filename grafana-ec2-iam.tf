# IAM Role for Grafana EC2 Instance
# This allows the EC2 instance to access S3 for provisioning files

# IAM Role for Grafana EC2
resource "aws_iam_role" "grafana_ec2_role" {
  name = "${local.name_prefix}-grafana-ec2-role"

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
    Name        = "${local.name_prefix}-grafana-ec2-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "grafana_ec2_s3" {
  name        = "${local.name_prefix}-grafana-ec2-s3"
  description = "Policy for Grafana EC2 to access S3 provisioning files"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.grafana_provisioning.arn,
          "${aws_s3_bucket.grafana_provisioning.arn}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-grafana-ec2-s3-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach S3 policy to role
resource "aws_iam_role_policy_attachment" "grafana_ec2_s3" {
  role       = aws_iam_role.grafana_ec2_role.name
  policy_arn = aws_iam_policy.grafana_ec2_s3.arn
}

# Attach basic EC2 policy
resource "aws_iam_role_policy_attachment" "grafana_ec2_basic" {
  role       = aws_iam_role.grafana_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

# Attach SSM policy for Session Manager
resource "aws_iam_role_policy_attachment" "grafana_ec2_ssm" {
  role       = aws_iam_role.grafana_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Policy for CloudWatch access
resource "aws_iam_policy" "grafana_ec2_cloudwatch" {
  name        = "${local.name_prefix}-grafana-ec2-cloudwatch"
  description = "Policy for Grafana EC2 to access CloudWatch metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:DescribeAlarmHistory",
          "cloudwatch:GetMetricWidgetImage",
          "cloudwatch:ListDashboards",
          "cloudwatch:GetDashboard",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents",
          "logs:FilterLogEvents",
          "logs:StartQuery",
          "logs:StopQuery",
          "logs:GetQueryResults"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:GetFunction",
          "dynamodb:ListTables",
          "dynamodb:DescribeTable"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-grafana-ec2-cloudwatch-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach CloudWatch policy to role
resource "aws_iam_role_policy_attachment" "grafana_ec2_cloudwatch" {
  role       = aws_iam_role.grafana_ec2_role.name
  policy_arn = aws_iam_policy.grafana_ec2_cloudwatch.arn
}

# Instance Profile for EC2
resource "aws_iam_instance_profile" "grafana_ec2" {
  name = "${local.name_prefix}-grafana-ec2-profile"
  role = aws_iam_role.grafana_ec2_role.name

  tags = {
    Name        = "${local.name_prefix}-grafana-ec2-profile"
    Environment = var.environment
    Project     = var.project_name
  }
}
