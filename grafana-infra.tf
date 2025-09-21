# Grafana EC2 Instance - COMMENTED OUT (already exists)
# resource "aws_instance" "grafana" {
#   ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2
#   instance_type          = "t3.medium"
#   key_name              = "aws-upc-pfg-key-${var.account_name}"
#   vpc_security_group_ids = [aws_security_group.grafana_sg.id]
#   subnet_id             = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.private_subnet_id
#   iam_instance_profile  = aws_iam_instance_profile.grafana_profile.name
#
#   user_data = base64encode(templatefile("${path.module}/grafana-user-data.sh", {
#     grafana_admin_password = var.grafana_password != "" ? var.grafana_password : random_password.grafana_password.result
#     region                = var.region
#   }))
#
#   tags = {
#     Name = "grafana-${var.account_name}"
#   }
# }

# Random password for Grafana if not provided
resource "random_password" "grafana_password" {
  length  = 16
  special = true
}

# Security Group for Grafana
resource "aws_security_group" "grafana_sg" {
  name_prefix = "grafana-sg-${var.account_name}"
  vpc_id      = data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.vpc_id

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.aws_upc_pfg_tfstate.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "grafana-sg-${var.account_name}"
  }
}

# IAM Role for Grafana
resource "aws_iam_role" "grafana_role" {
  name = "grafana-role-${var.account_name}"

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
    Name = "grafana-role-${var.account_name}"
  }
}

# IAM Instance Profile for Grafana
resource "aws_iam_instance_profile" "grafana_profile" {
  name = "grafana-profile-${var.account_name}"
  role = aws_iam_role.grafana_role.name
}

# IAM Policy for Grafana to access CloudWatch
resource "aws_iam_role_policy" "grafana_cloudwatch_policy" {
  name = "grafana-cloudwatch-policy-${var.account_name}"
  role = aws_iam_role.grafana_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:GetLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}
