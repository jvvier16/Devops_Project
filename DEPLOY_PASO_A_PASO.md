# Guía de Despliegue en AWS - Paso a Paso

Instrucciones detalladas para desplegar la aplicación en AWS usando Terraform, Docker y ECR.

---

## Requisitos Previos

- AWS CLI instalado
- Terraform instalado
- Docker instalado
- Docker Buildx configurado
- Acceso a una cuenta de AWS
- Permisos para crear recursos en AWS

---

## Paso 1: Configurar AWS CLI

Configura las credenciales de AWS en tu máquina local.

```bash
aws configure
```

Se te pedirá que ingreses:
- AWS Access Key ID: Tu clave de acceso
- AWS Secret Access Key: Tu clave secreta
- Default region name: us-east-1
- Default output format: json

---

## Paso 2: Variables de Configuración

Define las siguientes variables para tu despliegue:

```bash
# Base de Datos
DB_NAME="asistencia_db"
DB_USER="asistencia_user"
DB_PASSWORD="S3gura!P4ssw0rd2026"

# AWS
AWS_REGION="us-east-1"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# ECR - Repositorio de Docker
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
BACKEND_VENTAS_REPO="backend-ventas"
BACKEND_DESPACHOS_REPO="backend-despachos"
FRONTEND_REPO="frontend-despacho"

# Key Pair para EC2
KEY_PAIR_NAME="my-keypair-asistencia"

# Verificar el Account ID
echo "Tu AWS Account ID es: $AWS_ACCOUNT_ID"
```

---

## Paso 3: Crear Key Pair en AWS

Crea un par de claves para acceder a tus instancias EC2.

```bash
# Crear el key pair
aws ec2 create-key-pair \
  --key-name $KEY_PAIR_NAME \
  --region $AWS_REGION \
  --query 'KeyMaterial' \
  --output text > $KEY_PAIR_NAME.pem

# Cambiar permisos del archivo (importante para Linux/Mac)
chmod 400 $KEY_PAIR_NAME.pem

# En Windows, asegúrate de que solo tu usuario puede leer el archivo
```

---

## Paso 4: Inicializar Terraform

Navega al directorio de infraestructura y prepara Terraform.

```bash
# Ir al directorio de Terraform
cd infra/etapa_1

# Inicializar Terraform (descarga providers necesarios)
terraform init

# Validar la configuración
terraform validate
```

---

## Paso 5: Planificar la Infraestructura

Revisa qué recursos se crearán en AWS.

```bash
# Crear un plan de Terraform
terraform plan -out=tfplan

# Este comando mostrará:
# - VPC (Red Virtual)
# - Subnets (Subredes)
# - Security Groups (Grupos de Seguridad)
# - ALB (Application Load Balancer)
# - ECS Cluster
# - ECR Repositories
# - RDS MySQL
# - Y otros recursos
```

---

## Paso 6: Aplicar la Infraestructura

Crea los recursos en AWS.

```bash
# Aplicar la configuración de Terraform
terraform apply tfplan

# Espera a que se completen todos los recursos (puede tomar 10-15 minutos)

# Al finalizar, Terraform mostrará los outputs:
# - ALB DNS Name
# - ECR Repository URLs
# - RDS Endpoint
# Anota estos valores para los próximos pasos
```

---

## Paso 7: Obtener Outputs de Terraform

Recupera la información que necesitarás para los siguientes pasos.

```bash
# Mostrar todos los outputs
terraform output

# Guardar valores específicos
ECR_REGISTRY=$(terraform output -raw ecr_registry_url | cut -d'/' -f1)
ALB_DNS=$(terraform output -raw alb_dns_name)
RDS_ENDPOINT=$(terraform output -raw rds_endpoint)

echo "ECR Registry: $ECR_REGISTRY"
echo "ALB DNS: $ALB_DNS"
echo "RDS Endpoint: $RDS_ENDPOINT"
```

---

## Paso 8: Configurar Docker para ECR

Inicia sesión en Amazon ECR para poder subir imágenes Docker.

```bash
# Obtener el token de autenticación y conectar Docker a ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY

# Respuesta esperada: Login Succeeded
```

---

## Paso 9: Construir y Subir Backend - Ventas

Construye la imagen Docker del backend de ventas para la arquitectura de AWS (linux/amd64).

```bash
# Definir el tag de la imagen
BACKEND_VENTAS_TAG="$ECR_REGISTRY/$BACKEND_VENTAS_REPO:latest"

# Construir la imagen multi-plataforma y subirla a ECR
docker buildx build --platform linux/amd64 \
  -t $BACKEND_VENTAS_TAG \
  ./back-Ventas_SpringBoot/Springboot-API-REST \
  --push

# Verificar que la imagen está en ECR
aws ecr describe-images \
  --repository-name $BACKEND_VENTAS_REPO \
  --region $AWS_REGION
```

---

## Paso 10: Construir y Subir Backend - Despachos

Construye la imagen Docker del backend de despachos y súbela a ECR.

```bash
# Definir el tag de la imagen
BACKEND_DESPACHOS_TAG="$ECR_REGISTRY/$BACKEND_DESPACHOS_REPO:latest"

# Construir la imagen multi-plataforma y subirla a ECR
docker buildx build --platform linux/amd64 \
  -t $BACKEND_DESPACHOS_TAG \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO \
  --push

# Verificar que la imagen está en ECR
aws ecr describe-images \
  --repository-name $BACKEND_DESPACHOS_REPO \
  --region $AWS_REGION
```

---

## Paso 11: Construir y Subir Frontend

Construye la imagen Docker del frontend y súbela a ECR.

```bash
# Definir el tag de la imagen
FRONTEND_TAG="$ECR_REGISTRY/$FRONTEND_REPO:latest"

# Construir la imagen multi-plataforma y subirla a ECR
docker buildx build --platform linux/amd64 \
  -t $FRONTEND_TAG \
  ./front \
  --push

# Verificar que la imagen está en ECR
aws ecr describe-images \
  --repository-name $FRONTEND_REPO \
  --region $AWS_REGION
```

---

## Paso 12: Desplegar Etapa 2 (Aplicaciones)

Una vez que las imágenes están en ECR, despliega la segunda etapa de Terraform.

```bash
# Ir al directorio de Terraform etapa 2
cd ../etapa_2

# Inicializar Terraform
terraform init

# Planificar
terraform plan \
  -var="backend_ventas_image=$BACKEND_VENTAS_TAG" \
  -var="backend_despachos_image=$BACKEND_DESPACHOS_TAG" \
  -var="frontend_image=$FRONTEND_TAG" \
  -var="db_name=$DB_NAME" \
  -var="db_user=$DB_USER" \
  -var="db_password=$DB_PASSWORD" \
  -out=tfplan

# Aplicar
terraform apply tfplan

# Espera a que los servicios ECS se estabilicen (puede tomar 5-10 minutos)
```

---

## Paso 13: Verificar el Despliegue

Verifica que todos los servicios estén funcionando correctamente.

```bash
# Obtener la URL del Application Load Balancer
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region $AWS_REGION \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "Tu aplicación está disponible en: http://$ALB_DNS"

# Ver el estado de los servicios ECS
aws ecs list-services --cluster asistencia-cluster --region $AWS_REGION

# Ver tareas en ejecución
aws ecs list-tasks --cluster asistencia-cluster --region $AWS_REGION

# Ver logs de un servicio
aws logs get-log-stream-names \
  --log-group-name /ecs/backend-ventas \
  --region $AWS_REGION
```

---

## Paso 14: Configurar Dominio Personalizado (Opcional)

Si tienes un dominio en Route53, puedes configurarlo.

```bash
# Ver registros de Route53
aws route53 list-hosted-zones

# Crear un alias para apuntar al ALB
# (Requiere ID de tu hosted zone)
HOSTED_ZONE_ID="Z1234567890ABC"
DOMAIN_NAME="app.tudominio.com"

aws route53 change-resource-record-sets \
  --hosted-zone-id $HOSTED_ZONE_ID \
  --change-batch "{
    \"Changes\": [{
      \"Action\": \"UPSERT\",
      \"ResourceRecordSet\": {
        \"Name\": \"$DOMAIN_NAME\",
        \"Type\": \"A\",
        \"AliasTarget\": {
          \"HostedZoneId\": \"Z35SXDOTRQ7X7K\",
          \"DNSName\": \"$ALB_DNS\",
          \"EvaluateTargetHealth\": false
        }
      }
    }]
  }"
```

---

## Paso 15: Limpiar Recursos (Cuando Termines)

Elimina los recursos de AWS para evitar cargos innecesarios.

```bash
# ADVERTENCIA: Esto eliminará TODOS los recursos creados por Terraform

# Ir a la etapa 2
cd infra/etapa_2
terraform destroy

# Ir a la etapa 1
cd ../etapa_1
terraform destroy

# Eliminar el key pair (opcional)
aws ec2 delete-key-pair --key-name $KEY_PAIR_NAME --region $AWS_REGION

# Eliminar repositorios ECR (opcional - pero mantén el histórico si quieres)
aws ecr delete-repository \
  --repository-name $BACKEND_VENTAS_REPO \
  --region $AWS_REGION \
  --force
```

---

## Troubleshooting

### Error: "No valid provider found"

```bash
terraform init -upgrade
```

### Error: "AccessDenied" en AWS

Verifica que tu usuario de AWS tiene los permisos necesarios:
- EC2, ECS, ECR, RDS, VPC, ALB, CloudWatch

### Error: "Docker login failed"

```bash
# Regenera el token de ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin $ECR_REGISTRY
```

### Las tareas ECS no inician

```bash
# Ver logs detallados
aws ecs describe-tasks \
  --cluster asistencia-cluster \
  --tasks <task-arn> \
  --region $AWS_REGION

# Ver logs de CloudWatch
aws logs tail /ecs/backend-ventas --follow --region $AWS_REGION
```

---

## Variables de Entorno Resumen

```bash
DB_NAME="asistencia_db"
DB_USER="asistencia_user"
DB_PASSWORD="S3gura!P4ssw0rd2026"
AWS_REGION="us-east-1"
KEY_PAIR_NAME="my-keypair-asistencia"
```

---

## Documentación de Referencia

- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Docker Buildx](https://docs.docker.com/build/architecture/)
- [Amazon ECS](https://docs.aws.amazon.com/ecs/)
- [Amazon ECR](https://docs.aws.amazon.com/ecr/)
