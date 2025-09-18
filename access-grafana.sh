#!/bin/bash

# Script para acceder a Grafana a través del bastion host
# Uso: ./access-grafana.sh

set -e  # Exit on any error

echo "🔐 Accediendo a Grafana a través del Bastion Host..."
echo ""

# Obtener información del bastion y Grafana usando terraform output
BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "54.158.224.93")
GRAFANA_IP=$(terraform output -raw grafana_private_ip 2>/dev/null || echo "10.0.2.250")
GRAFANA_PASSWORD=$(terraform output -raw grafana_admin_password 2>/dev/null || echo "admin123")

# Verificar que el archivo de clave existe
KEY_FILE="bastion-key.pem"
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ Error: No se encontró el archivo de clave $KEY_FILE"
    echo "   Asegúrate de que el archivo esté en el directorio actual"
    exit 1
fi

echo "📍 Bastion IP: $BASTION_IP"
echo "📍 Grafana IP: $GRAFANA_IP"
echo "🔑 Grafana Password: $GRAFANA_PASSWORD"
echo ""

# Verificar conectividad al bastion host
echo "🔍 Verificando conectividad al bastion host..."
if ! ssh -i "$KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$BASTION_IP "echo 'Conexión exitosa'" >/dev/null 2>&1; then
    echo "❌ Error: No se puede conectar al bastion host"
    echo "   Verifica que la instancia esté ejecutándose y que la clave SSH sea correcta"
    exit 1
fi

echo "✅ Conectividad al bastion host verificada"
echo ""

echo "🚀 Iniciando túnel SSH..."
echo "   - Grafana estará disponible en: http://localhost:3000"
echo "   - Usuario: admin"
echo "   - Password: $GRAFANA_PASSWORD"
echo ""
echo "💡 Para detener el túnel, presiona Ctrl+C"
echo ""

# Crear túnel SSH
ssh -i "$KEY_FILE" -L 3000:$GRAFANA_IP:3000 ec2-user@$BASTION_IP
