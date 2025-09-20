#!/bin/bash

# Script to verify Grafana ECS deployment
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Verificando despliegue de Grafana ECS${NC}"
echo "=============================================="

# Check if Terraform state is available
if ! terraform state list >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: No se puede acceder al estado de Terraform${NC}"
    echo -e "${YELLOW}💡 Ejecuta 'terraform init' y 'terraform apply' primero${NC}"
    exit 1
fi

# Get infrastructure information
echo -e "${BLUE}📋 Obteniendo información de la infraestructura...${NC}"
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
CLUSTER_NAME=$(terraform output -raw grafana_ecs_cluster_name 2>/dev/null || echo "")
SERVICE_NAME=$(terraform output -raw grafana_ecs_service_name 2>/dev/null || echo "")

if [ -z "$BASTION_IP" ] || [ -z "$CLUSTER_NAME" ] || [ -z "$SERVICE_NAME" ]; then
    echo -e "${RED}❌ Error: No se pudieron obtener los datos de la infraestructura${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Bastion IP: $BASTION_IP${NC}"
echo -e "${GREEN}✅ ECS Cluster: $CLUSTER_NAME${NC}"
echo -e "${GREEN}✅ ECS Service: $SERVICE_NAME${NC}"

# Test SSH connection to bastion
echo -e "${BLUE}🔐 Probando conexión SSH al bastion...${NC}"
if ssh -i bastion-key.pem -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no ec2-user@$BASTION_IP "echo 'SSH OK'" >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Conexión SSH al bastion exitosa${NC}"
else
    echo -e "${RED}❌ Error: No se puede conectar por SSH al bastion${NC}"
    exit 1
fi

# Check ECS service status
echo -e "${BLUE}📊 Verificando estado del servicio ECS...${NC}"
SERVICE_STATUS=$(aws ecs describe-services --cluster "$CLUSTER_NAME" --services "$SERVICE_NAME" --region us-east-1 --query 'services[0].status' --output text 2>/dev/null || echo "UNKNOWN")

if [ "$SERVICE_STATUS" = "ACTIVE" ]; then
    echo -e "${GREEN}✅ Servicio ECS está activo${NC}"
else
    echo -e "${RED}❌ Error: Servicio ECS no está activo (Status: $SERVICE_STATUS)${NC}"
    exit 1
fi

# Check if tasks are running
echo -e "${BLUE}🔍 Verificando tareas ejecutándose...${NC}"
RUNNING_TASKS=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --region us-east-1 --query 'taskArns | length(@)' --output text 2>/dev/null || echo "0")

if [ "$RUNNING_TASKS" -gt 0 ]; then
    echo -e "${GREEN}✅ $RUNNING_TASKS tarea(s) ejecutándose${NC}"
else
    echo -e "${RED}❌ Error: No hay tareas ejecutándose${NC}"
    exit 1
fi

# Get Grafana IP and test connectivity
echo -e "${BLUE}🌐 Obteniendo IP de Grafana y probando conectividad...${NC}"
GRAFANA_IP=$(./get-grafana-ip.sh 2>/dev/null || echo "")

if [ -z "$GRAFANA_IP" ]; then
    echo -e "${RED}❌ Error: No se pudo obtener la IP de Grafana${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Grafana IP: $GRAFANA_IP${NC}"

# Test connectivity from bastion to Grafana
if ssh -i bastion-key.pem -o StrictHostKeyChecking=no ec2-user@$BASTION_IP "curl -s -o /dev/null -w '%{http_code}' http://$GRAFANA_IP:3000" | grep -q "200\|302"; then
    echo -e "${GREEN}✅ Grafana responde correctamente en $GRAFANA_IP:3000${NC}"
else
    echo -e "${YELLOW}⚠️  Grafana no responde. Verificando estado...${NC}"
    
    # Check ECS task health
    TASK_ARN=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --service-name "$SERVICE_NAME" --region us-east-1 --query 'taskArns[0]' --output text 2>/dev/null || echo "")
    
    if [ -n "$TASK_ARN" ] && [ "$TASK_ARN" != "None" ]; then
        echo -e "${BLUE}🔍 Verificando salud de la tarea...${NC}"
        TASK_HEALTH=$(aws ecs describe-tasks --cluster "$CLUSTER_NAME" --tasks "$TASK_ARN" --region us-east-1 --query 'tasks[0].healthStatus' --output text 2>/dev/null || echo "UNKNOWN")
        echo -e "${YELLOW}Estado de salud de la tarea: $TASK_HEALTH${NC}"
    fi
    
    echo -e "${YELLOW}💡 Para solucionar, ejecuta:${NC}"
    echo -e "${YELLOW}   aws ecs update-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force-new-deployment${NC}"
    exit 1
fi

# Test SSH tunnel
echo -e "${BLUE}🔗 Probando túnel SSH...${NC}"
echo -e "${YELLOW}Iniciando túnel SSH en segundo plano...${NC}"

# Start tunnel in background
ssh -i bastion-key.pem -o StrictHostKeyChecking=no -L 3000:$GRAFANA_IP:3000 -N ec2-user@$BASTION_IP &
TUNNEL_PID=$!

# Wait a moment for tunnel to establish
sleep 5

# Test local connection
if curl -s -o /dev/null -w '%{http_code}' http://localhost:3000 | grep -q "200\|302"; then
    echo -e "${GREEN}✅ Túnel SSH funciona correctamente${NC}"
    echo -e "${GREEN}✅ Grafana es accesible en http://localhost:3000${NC}"
    
    # Kill the test tunnel
    kill $TUNNEL_PID 2>/dev/null || true
    
    echo -e "${BLUE}🎉 Verificación completada exitosamente!${NC}"
    echo -e "${YELLOW}💡 Para acceder a Grafana, ejecuta:${NC}"
    echo -e "${YELLOW}   ./access-grafana.sh${NC}"
    echo -e "${YELLOW}   O manualmente:${NC}"
    echo -e "${YELLOW}   ssh -i bastion-key.pem -L 3000:$GRAFANA_IP:3000 -N ec2-user@$BASTION_IP${NC}"
    
else
    echo -e "${RED}❌ Error: El túnel SSH no funciona correctamente${NC}"
    kill $TUNNEL_PID 2>/dev/null || true
    exit 1
fi
