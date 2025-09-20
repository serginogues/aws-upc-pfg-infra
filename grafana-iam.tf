# ECS Task Execution Role with minimal permissions
resource "aws_iam_role" "ecs_execution_role" {
  name = "${local.name_prefix}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-ecs-execution-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role with specific permissions
resource "aws_iam_role" "ecs_task_role" {
  name = "${local.name_prefix}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-ecs-task-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Custom policy for Grafana CloudWatch access
resource "aws_iam_policy" "grafana_ecs_cloudwatch" {
  name        = "${local.name_prefix}-grafana-ecs-cloudwatch"
  description = "Policy for Grafana ECS task to access CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetInsightRuleReport"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
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
    Name        = "${local.name_prefix}-grafana-ecs-cloudwatch-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach CloudWatch permissions
resource "aws_iam_role_policy_attachment" "ecs_task_cloudwatch" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.grafana_ecs_cloudwatch.arn
}

# S3 policy for Grafana dashboards
resource "aws_iam_policy" "grafana_s3" {
  name        = "${local.name_prefix}-grafana-s3"
  description = "Policy for Grafana to access S3 dashboards"

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
          "arn:aws:s3:::${aws_s3_bucket.grafana-dashboards-bucket.bucket}",
          "arn:aws:s3:::${aws_s3_bucket.grafana-dashboards-bucket.bucket}/*"
        ]
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-grafana-s3-policy"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Attach S3 permissions for dashboards
resource "aws_iam_role_policy_attachment" "ecs_task_s3" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.grafana_s3.arn
}
