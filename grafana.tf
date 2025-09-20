# ECS Cluster with best practices
resource "aws_ecs_cluster" "grafana" {
  name = "${local.name_prefix}-grafana-cluster"

  # Enable Container Insights for monitoring
  setting {
    name  = "containerInsights"
    value = "enabled"
  }


  tags = {
    Name        = "${local.name_prefix}-grafana-cluster"
    Environment = var.environment
    Project     = var.project_name
    Service     = "monitoring"
  }
}

# ECS Task Definition with best practices
resource "aws_ecs_task_definition" "grafana" {
  family                   = "${local.name_prefix}-grafana"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name  = "grafana"
      image = "grafana/grafana:latest"
      
      portMappings = [
        {
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "GF_SECURITY_ADMIN_PASSWORD"
          value = var.grafana_admin_password
        },
        {
          name  = "GF_INSTALL_PLUGINS"
          value = "grafana-piechart-panel,grafana-clock-panel"
        },
        {
          name  = "GF_SECURITY_ALLOW_EMBEDDING"
          value = "true"
        },
        {
          name  = "GF_AUTH_ANONYMOUS_ENABLED"
          value = "false"
        },
        {
          name  = "GF_SERVER_ROOT_URL"
          value = "http://localhost:3000"
        }
      ]

      # Health check configuration
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:3000/api/health || exit 1"
        ]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }

      # Logging configuration
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.grafana_ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Resource limits
      cpu    = 512
      memory = 1024

      # Essential container
      essential = true
    }
  ])

  tags = {
    Name        = "${local.name_prefix}-grafana-task"
    Environment = var.environment
    Project     = var.project_name
    Service     = "monitoring"
  }
}

# ECS Service with auto-scaling
resource "aws_ecs_service" "grafana" {
  name            = "${local.name_prefix}-grafana"
  cluster         = aws_ecs_cluster.grafana.id
  task_definition = aws_ecs_task_definition.grafana.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.grafana_private.id]
    security_groups  = [aws_security_group.grafana_ecs.id]
    assign_public_ip = false
  }

  # Enable service discovery
  service_registries {
    registry_arn = aws_service_discovery_service.grafana.arn
  }


  # Enable execute command for debugging
  enable_execute_command = true

  tags = {
    Name        = "${local.name_prefix}-grafana-service"
    Environment = var.environment
    Project     = var.project_name
    Service     = "monitoring"
  }
}

# Service Discovery
resource "aws_service_discovery_private_dns_namespace" "grafana" {
  name        = "grafana.local"
  description = "Private DNS namespace for Grafana"
  vpc         = aws_vpc.grafana_vpc.id

  tags = {
    Name        = "${local.name_prefix}-grafana-namespace"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_service_discovery_service" "grafana" {
  name = "grafana"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.grafana.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }


  tags = {
    Name        = "${local.name_prefix}-grafana-discovery"
    Environment = var.environment
    Project     = var.project_name
  }
}
