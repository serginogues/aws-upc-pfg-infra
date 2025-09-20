# Security Group for ECS Service with least privilege
resource "aws_security_group" "grafana_ecs" {
  name_prefix = "${local.name_prefix}-grafana-ecs-"
  vpc_id      = aws_vpc.grafana_vpc.id
  description = "Security group for Grafana ECS service"

  # Allow HTTP traffic only from bastion
  ingress {
    from_port       = 3000
    to_port         = 3000
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion.id]
    description     = "Grafana HTTP from bastion host"
  }

  # Allow all outbound traffic for container operations
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic for container operations"
  }

  tags = {
    Name        = "${local.name_prefix}-grafana-ecs-sg"
    Environment = var.environment
    Project     = var.project_name
    Service     = "monitoring"
  }
}

# Update bastion security group to allow ECS access
resource "aws_security_group_rule" "bastion_to_ecs" {
  type                     = "egress"
  from_port                = 3000
  to_port                  = 3000
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grafana_ecs.id
  security_group_id        = aws_security_group.bastion.id
  description              = "HTTP access to Grafana ECS service"
}
