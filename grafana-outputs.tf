# ECS Outputs
output "grafana_ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.grafana.name
}

output "grafana_ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.grafana.name
}

output "grafana_ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.grafana.arn
}

output "grafana_service_discovery_namespace" {
  description = "Service discovery namespace for Grafana"
  value       = aws_service_discovery_private_dns_namespace.grafana.name
}

output "grafana_access_info" {
  description = "Grafana access information"
  sensitive   = true
  value = {
    ecs_cluster_name   = aws_ecs_cluster.grafana.name
    ecs_service_name   = aws_ecs_service.grafana.name
    bastion_ip         = aws_instance.bastion.public_ip
    service_discovery  = "${aws_service_discovery_service.grafana.name}.${aws_service_discovery_private_dns_namespace.grafana.name}"
    admin_username     = "admin"
    admin_password     = var.grafana_admin_password
  }
}

output "grafana_access_instructions" {
  description = "Instructions for accessing Grafana"
  sensitive   = true
  value = <<-EOT
    🚀 Grafana ECS Deployment Access Instructions
    =============================================
    
    🏗️  ECS Cluster: ${aws_ecs_cluster.grafana.name}
    📊 ECS Service: ${aws_ecs_service.grafana.name}
    🔍 Service Discovery: ${aws_service_discovery_service.grafana.name}.${aws_service_discovery_private_dns_namespace.grafana.name}
    
    🔐 Credentials:
       Username: admin
       Password: ${var.grafana_admin_password}
    
    🌐 Access Methods:
    
    1. Via SSH Tunnel (Recommended):
       ./access-grafana.sh
       Then open: http://localhost:3000
    
    2. Manual SSH Tunnel:
       ssh -i bastion-key.pem -L 3000:$(./get-grafana-ip.sh):3000 -N ec2-user@${aws_instance.bastion.public_ip}
    
    📋 Monitoring:
    - ECS Service: AWS Console → ECS → Clusters → ${aws_ecs_cluster.grafana.name}
    - Logs: CloudWatch → Log Groups → /ecs/${local.name_prefix}-grafana
    - Metrics: CloudWatch → Dashboards → ${aws_cloudwatch_dashboard.grafana_ecs.dashboard_name}
    
    🔧 Management:
    - Scale: aws ecs update-service --cluster ${aws_ecs_cluster.grafana.name} --service ${aws_ecs_service.grafana.name} --desired-count 2
    - Restart: aws ecs update-service --cluster ${aws_ecs_cluster.grafana.name} --service ${aws_ecs_service.grafana.name} --force-new-deployment
    - Execute: aws ecs execute-command --cluster ${aws_ecs_cluster.grafana.name} --task <TASK_ID> --container grafana --interactive --command "/bin/bash"
  EOT
}

output "grafana_quick_access" {
  description = "Quick access commands for Grafana"
  value = {
    access_script     = "./access-grafana.sh"
    get_ip_script     = "./get-grafana-ip.sh"
    ecs_console       = "https://console.aws.amazon.com/ecs/home?region=${var.aws_region}#/clusters/${aws_ecs_cluster.grafana.name}/services"
    cloudwatch_logs   = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#logsV2:log-groups/log-group/${replace(aws_cloudwatch_log_group.grafana_ecs.name, "/", "$252F")}"
    cloudwatch_dashboard = "https://console.aws.amazon.com/cloudwatch/home?region=${var.aws_region}#dashboards:name=${aws_cloudwatch_dashboard.grafana_ecs.dashboard_name}"
  }
}
