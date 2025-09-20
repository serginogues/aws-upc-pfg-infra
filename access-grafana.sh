#!/bin/bash

# Script para acceder a Grafana ECS a través del Bastion Host
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
LOCAL_PORT=3000
GRAFANA_PORT=80
SSH_KEY_PATH="bastion-key.pem"

# Help function
show_help() {
    echo -e "${BLUE}🚀 Acceso a Grafana ECS a través del Bastion Host${NC}"
    echo "=================================================="
    echo ""
    echo "Uso: $0 [opciones]"
    echo ""
    echo "Opciones:"
    echo "  -p, --port PORT        Puerto local para el túnel (default: 3000)"
    echo "  -k, --key PATH         Ruta a la clave SSH (default: bastion-key.pem)"
    echo "  -h, --help             Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0                     # Usar configuración por defecto"
    echo "  $0 -p 8080            # Usar puerto local 8080"
    echo "  $0 -k ~/.ssh/my-key   # Usar clave SSH personalizada"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--port)
            LOCAL_PORT="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY_PATH="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opción desconocida: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

echo -e "${BLUE}🚀 Accediendo a Grafana ECS a través del Bastion Host${NC}"
echo "=================================================="

# Verificar que la clave SSH existe
if [ ! -f "$SSH_KEY_PATH" ]; then
    echo -e "${RED}❌ Error: No se encontró la clave SSH en '$SSH_KEY_PATH'${NC}"
    echo -e "${YELLOW}💡 Asegúrate de que el archivo bastion-key.pem esté en el directorio actual${NC}"
    echo -e "${YELLOW}💡 O usa -k para especificar la ruta correcta${NC}"
    exit 1
fi

# Verificar permisos de la clave SSH
if [ "$(stat -c %a "$SSH_KEY_PATH")" != "600" ]; then
    echo -e "${YELLOW}⚠️  Ajustando permisos de la clave SSH...${NC}"
    chmod 600 "$SSH_KEY_PATH"
fi

# Verificar que Terraform ha sido ejecutado
if ! terraform state list >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: No se puede acceder al estado de Terraform${NC}"
    echo -e "${YELLOW}💡 Ejecuta 'terraform init' y 'terraform apply' primero${NC}"
    exit 1
fi

# Obtener información de Terraform
echo -e "${BLUE}📋 Obteniendo información de la infraestructura...${NC}"

BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
GRAFANA_IP=$(./get-grafana-ip.sh 2>/dev/null || echo "")
GRAFANA_ADMIN_PASSWORD=$(terraform output -raw grafana_admin_password 2>/dev/null || echo "admin")

# Verificar que se obtuvieron las IPs
if [ -z "$BASTION_IP" ]; then
    echo -e "${RED}❌ Error: No se pudo obtener la IP del bastion${NC}"
    echo -e "${YELLOW}💡 Asegúrate de que la infraestructura esté desplegada${NC}"
    exit 1
fi

if [ -z "$GRAFANA_IP" ]; then
    echo -e "${RED}❌ Error: No se pudo obtener la IP de Grafana ECS${NC}"
    echo -e "${YELLOW}💡 Asegúrate de que el servicio ECS esté funcionando${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Bastion IP: $BASTION_IP${NC}"
echo -e "${GREEN}✅ Grafana ECS IP: $GRAFANA_IP${NC}"

# Verificar que el puerto local esté disponible
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠️  El puerto $LOCAL_PORT está en uso${NC}"
    echo -e "${YELLOW}💡 Usa -p para especificar un puerto diferente${NC}"
    exit 1
fi

# Verificar conectividad al bastion
echo -e "${BLUE}🔐 Probando conexión SSH al bastion...${NC}"
if ! ssh -i "$SSH_KEY_PATH" -o ConnectTimeout=10 -o BatchMode=yes ec2-user@$BASTION_IP "echo 'SSH OK'" >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: No se puede conectar por SSH al bastion${NC}"
    echo -e "${YELLOW}💡 Verifica que la clave SSH sea correcta y el bastion esté funcionando${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Conexión SSH al bastion exitosa${NC}"

# Crear túnel SSH
echo -e "${BLUE}🔗 Creando túnel SSH...${NC}"
echo -e "${YELLOW}Comando: ssh -i $SSH_KEY_PATH -L $LOCAL_PORT:$ALB_DNS:$GRAFANA_PORT -N ec2-user@$BASTION_IP${NC}"

# Iniciar túnel en segundo plano
ssh -i "$SSH_KEY_PATH" -L "$LOCAL_PORT:$ALB_DNS:$GRAFANA_PORT" -N ec2-user@$BASTION_IP &
SSH_PID=$!

# Esperar un momento para que el túnel se establezca
sleep 5

# Verificar que el túnel esté funcionando
echo -e "${BLUE}🔍 Verificando túnel SSH...${NC}"
if lsof -Pi :$LOCAL_PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Túnel SSH creado exitosamente!${NC}"
    echo -e "${GREEN}✅ PID del proceso SSH: $SSH_PID${NC}"
else
    echo -e "${RED}❌ Error: No se pudo crear el túnel SSH${NC}"
    kill $SSH_PID 2>/dev/null || true
    exit 1
fi

# Mostrar información de acceso
echo ""
echo -e "${GREEN}🎉 ¡Grafana ECS está accesible!${NC}"
echo "=============================================="
echo -e "${BLUE}🌐 Abre tu navegador en: http://localhost:$LOCAL_PORT${NC}"
echo ""
echo -e "${YELLOW}📝 Credenciales de Grafana:${NC}"
echo -e "   Usuario: admin"
echo -e "   Contraseña: $GRAFANA_ADMIN_PASSWORD"
echo ""
echo -e "${YELLOW}🔧 Información del túnel:${NC}"
echo -e "   Puerto local: $LOCAL_PORT"
echo -e "   ALB DNS: $ALB_DNS"
echo -e "   Bastion IP: $BASTION_IP"
echo -e "   PID SSH: $SSH_PID"
echo ""
echo -e "${BLUE}💡 Para detener el túnel, ejecuta:${NC}"
echo -e "   kill $SSH_PID"
echo -e "   O presiona Ctrl+C si ejecutaste el script en primer plano"
echo ""
echo -e "${BLUE}💡 El túnel permanecerá activo hasta que lo detengas${NC}"

# Mantener el script corriendo si se ejecuta en primer plano
if [ -t 0 ]; then
    echo -e "${YELLOW}Presiona Ctrl+C para detener el túnel...${NC}"
    trap "echo -e '\n${BLUE}🛑 Deteniendo túnel SSH...${NC}'; kill $SSH_PID 2>/dev/null; exit 0" INT
    wait $SSH_PID
fi
