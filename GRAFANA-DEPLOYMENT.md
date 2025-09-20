# 🚀 Grafana Deployment en AWS

Este proyecto despliega Grafana en una VPC privada de AWS con acceso a través de un bastion host.

## 📋 Arquitectura

```
Internet → Bastion Host (Public Subnet) → Grafana (Private Subnet)
                ↓
            CloudWatch (Métricas)
```

## 🛠️ Componentes

- **VPC**: Red privada con subredes pública y privada
- **Bastion Host**: Instancia EC2 en subred pública para acceso SSH
- **Grafana**: Instancia EC2 en subred privada con Docker
- **NAT Gateway**: Para acceso a internet desde subred privada
- **Security Groups**: Configuración de seguridad de red
- **IAM Roles**: Permisos para acceso a CloudWatch y S3

## 🚀 Despliegue

### 1. Configurar AWS
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 2. Inicializar Terraform
```bash
terraform init
```

### 3. Aplicar configuración
```bash
terraform apply
```

### 4. Verificar despliegue
```bash
./verify-grafana.sh
```

## 🔗 Acceso a Grafana

### Opción 1: Script automático
```bash
./access-grafana.sh
```

### Opción 2: Comando manual
```bash
# Obtener IPs
BASTION_IP=$(terraform output -raw bastion_public_ip)
GRAFANA_IP=$(terraform output -raw grafana_private_ip)

# Crear túnel SSH
ssh -i bastion-key.pem -L 3000:$GRAFANA_IP:3000 -N ec2-user@$BASTION_IP
```

### Opción 3: Script simple
```bash
./grafana-tunnel.sh
```

## 🌐 Acceso Web

Una vez establecido el túnel SSH:
- **URL**: http://localhost:3000
- **Usuario**: admin
- **Contraseña**: `$(terraform output -raw grafana_admin_password)`

## 🔧 Solución de Problemas

### Grafana no responde
```bash
# Conectar al bastion
ssh -i bastion-key.pem ec2-user@$(terraform output -raw bastion_public_ip)

# Verificar estado de Grafana
sudo docker ps | grep grafana

# Reiniciar Grafana
sudo docker-compose -f /opt/grafana/docker-compose.yml up -d

# Ver logs
sudo docker logs grafana
```

### Problemas de conectividad
```bash
# Verificar conectividad desde bastion
ssh -i bastion-key.pem ec2-user@$(terraform output -raw bastion_public_ip) "curl -I http://$(terraform output -raw grafana_private_ip):3000"

# Verificar security groups
aws ec2 describe-security-groups --group-ids $(terraform output -raw grafana_security_group_id)
```

### Reiniciar Grafana
```bash
# Desde el bastion
ssh -i bastion-key.pem ec2-user@$(terraform output -raw bastion_public_ip) "sudo systemctl restart grafana-docker"
```

## 📊 Configuración de CloudWatch

Grafana viene preconfigurado con:
- **Datasource**: CloudWatch
- **Dashboards**: Lambda monitoring, DynamoDB monitoring
- **Permisos**: IAM role para acceso a métricas

## 🧹 Limpieza

```bash
terraform destroy
```

## 📁 Archivos Importantes

- `grafana.tf`: Configuración principal de Terraform
- `bastion.tf`: Configuración del bastion host
- `grafana-setup.sh`: Script de instalación de Grafana
- `access-grafana.sh`: Script de acceso con túnel SSH
- `verify-grafana.sh`: Script de verificación del despliegue
- `grafana-tunnel.sh`: Script simple de túnel SSH

## 🔐 Seguridad

- Grafana solo es accesible desde el bastion host
- No hay acceso directo desde internet
- Todas las comunicaciones están encriptadas
- IAM roles con permisos mínimos necesarios
