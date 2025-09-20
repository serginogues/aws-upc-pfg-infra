#!/bin/bash

# Script to get Grafana ECS task IP
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get ECS cluster name
CLUSTER_NAME=$(terraform output -raw grafana_ecs_cluster_name 2>/dev/null || echo "")
SERVICE_NAME=$(terraform output -raw grafana_ecs_service_name 2>/dev/null || echo "")

if [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}❌ Error: No se pudieron obtener los nombres del cluster o servicio${NC}" >&2
    echo -e "${YELLOW}💡 Asegúrate de que la infraestructura ECS esté desplegada${NC}" >&2
    exit 1
fi

# Get task ARN
TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --region us-east-1 --query 'taskArns[0]' --output text)

if [ "$TASK_ARN" = "None" ] || [ -z "$TASK_ARN" ]; then
    echo -e "${RED}❌ Error: No se encontró ninguna tarea ejecutándose${NC}" >&2
    echo -e "${YELLOW}💡 Verifica que el servicio ECS esté funcionando${NC}" >&2
    exit 1
fi

# Get task details
TASK_DETAILS=$(aws ecs describe-tasks --cluster "$CLUSTER_NAME" --tasks "$TASK_ARN" --region us-east-1)

# Extract private IP
PRIVATE_IP=$(echo "$TASK_DETAILS" | jq -r '.tasks[0].attachments[0].details[] | select(.name=="privateIPv4Address") | .value')

if [ -z "$PRIVATE_IP" ] || [ "$PRIVATE_IP" = "null" ]; then
    echo -e "${RED}❌ Error: No se pudo obtener la IP privada de la tarea${NC}" >&2
    exit 1
fi

echo "$PRIVATE_IP"
