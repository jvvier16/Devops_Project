# Terraform Infrastructure for DevOps Project

## 📋 Estructura

### Etapa 1: ECR (Elastic Container Registry)
- Crea 2 repositorios en ECR para backend y frontend
- Básico y rápido de desplegar
- **Uso**: Preparar los registros para las imágenes Docker

### Etapa 2: Infraestructura Completa
- VPC con subnets públicas
- EC2 para MySQL 8
- Security Groups
- ECS Fargate con frontend y backend
- Application Load Balancer (ALB)
- CloudWatch Logs
- **Uso**: Despliegue completo de la aplicación

## 🚀 Requisitos Previos

1. **Cuenta AWS** con credenciales configuradas
2. **Terraform** >= 1.0
3. **AWS CLI** configurado
4. **EC2 Key Pair** creado en AWS

## 📝 Instalación de Terraform

### Windows
```powershell
# Descargar e instalar Terraform (si usas Chocolatey)
choco install terraform

# O descargar manualmente desde: https://www.terraform.io/downloads.html
```

### Verificar instalación
```bash
terraform version
```

## 🔧 Configuración

### Paso 1: Configurar AWS Credentials
```bash
aws configure
# Ingresa: Access Key, Secret Access Key, Region (us-east-1), Output format (json)
```

### Paso 2: Crear terraform.tfvars (desde el .example)

#### Para Etapa 1:
```bash
cd infra/etapa_1
copy terraform.tfvars.example terraform.tfvars
```

Editar `terraform.tfvars`:
```hcl
aws_region = "us-east-1"
project_name = "devops-u2"
```

#### Para Etapa 2:
```bash
cd infra/etapa_2
copy terraform.tfvars.example terraform.tfvars
```

Editar `terraform.tfvars`:
```hcl
aws_region    = "us-east-1"
project_name  = "devops-u2"
db_user       = "admin"
db_password   = "YourSecurePassword123!"
db_name       = "asistencia_db"
key_pair_name = "tu-ec2-key-pair"  # El nombre de la keypair creada en AWS
```

## 📦 Despliegue

### Etapa 1: ECR

```bash
cd infra/etapa_1

# Inicializar Terraform
terraform init

# Validar sintaxis
terraform validate

# Ver plan de cambios
terraform plan

# Aplicar cambios
terraform apply
```

**Output esperado:**
```
backend_ecr_url = "123456789.dkr.ecr.us-east-1.amazonaws.com/devops-u2-backend"
frontend_ecr_url = "123456789.dkr.ecr.us-east-1.amazonaws.com/devops-u2-frontend"
```

### Etapa 2: Infraestructura Completa

⚠️ **Nota**: Ejecutar primero la Etapa 1 para crear los ECR

```bash
cd infra/etapa_2

# Inicializar Terraform
terraform init

# Ver plan
terraform plan

# Aplicar
terraform apply

# Esperar ~5-10 minutos para que todo esté listo
```

**Output esperado:**
```
backend_ecr_url = "..."
frontend_ecr_url = "..."
mysql_public_ip = "XX.XX.XX.XX"
load_balancer_dns = "devops-u2-alb-123456.us-east-1.elb.amazonaws.com"
```

## 🐳 Construir y Pushear Imágenes Docker

### 1. Hacer login en ECR
```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 123456789.dkr.ecr.us-east-1.amazonaws.com
```

### 2. Construir imágenes
```bash
# Backend
cd back-Ventas_SpringBoot/Springboot-API-REST
docker build -t devops-u2-backend:latest .
docker tag devops-u2-backend:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/devops-u2-backend:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/devops-u2-backend:latest

# Frontend
cd front_despacho
docker build -t devops-u2-frontend:latest .
docker tag devops-u2-frontend:latest 123456789.dkr.ecr.us-east-1.amazonaws.com/devops-u2-frontend:latest
docker push 123456789.dkr.ecr.us-east-1.amazonaws.com/devops-u2-frontend:latest
```

## 🧹 Limpiar Recursos

```bash
cd infra/etapa_2
terraform destroy

cd ../etapa_1
terraform destroy
```

⚠️ **Importante**: Los ECR que contienen imágenes deben tener `force_delete = true` para ser eliminados automáticamente.

## 📊 Monitorear

### Ver logs en CloudWatch
```bash
# Lista los logs
aws logs describe-log-groups

# Ver logs del ECS
aws logs tail /ecs/devops-u2 --follow
```

### Acceder a la aplicación
```
Frontend: http://devops-u2-alb-123456.us-east-1.elb.amazonaws.com
Backend: http://devops-u2-alb-123456.us-east-1.elb.amazonaws.com:8080
```

## 🐛 Troubleshooting

### Error: "LabRole not found"
La variable `data "aws_iam_role" "lab"` busca el rol "LabRole" en tu cuenta AWS. Para usar otro rol:

Editar `infra/etapa_2/main.tf`:
```hcl
data "aws_iam_role" "lab" {
  name = "ecsTaskExecutionRole"  # O el nombre de tu rol
}
```

### Error: "InvalidKeyPair.NotFound"
El EC2 Key Pair especificado no existe en AWS. Crear uno:
```bash
aws ec2 create-key-pair --key-name tu-ec2-key-pair --region us-east-1
```

### Las imágenes no se actualizan en ECS
ECS cachea las imágenes. Forzar actualización:
```bash
terraform apply -var="force_new_deployment=true"
```

## 📚 Recursos Útiles

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [Terraform State Management](https://www.terraform.io/language/state)

## ✅ Checklist de Despliegue

- [ ] AWS credentials configurados
- [ ] EC2 Key Pair creado
- [ ] terraform.tfvars completado (etapa_1 y etapa_2)
- [ ] `terraform init` ejecutado en ambas etapas
- [ ] Imágenes Docker pusheadas a ECR
- [ ] ECS service corriendo sin errores
- [ ] ALB responding en el DNS
- [ ] Frontend accesible desde el navegador
- [ ] Backend respondiendo en `/swagger-ui.html`
