#!/bin/bash

# Script completo de despliegue para Git Bash
# Uso: ./deploy.sh

set -e

AWS_REGION="us-east-1"
ACCOUNT_ID="404971863212"
PROJECT_NAME="devops-u2"

echo ""
echo "🚀 Iniciando despliegue automatizado..."
echo "Region: $AWS_REGION | Account: $ACCOUNT_ID | Project: $PROJECT_NAME"
echo ""

# 1. Login en ECR
echo "📦 [1/4] Conectando a ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

if [ $? -eq 0 ]; then
    echo "✅ Autenticación ECR exitosa"
else
    echo "❌ Error en autenticación ECR"
    exit 1
fi

# 2. Build Backend
echo ""
echo "🔨 [2/4] Construyendo Backend..."
BACKEND_IMAGE="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME-backend:latest"
docker buildx build --platform linux/amd64 -t "$BACKEND_IMAGE" ./back-Ventas_SpringBoot/Springboot-API-REST --push

if [ $? -eq 0 ]; then
    echo "✅ Backend construido: $BACKEND_IMAGE"
else
    echo "❌ Error construyendo Backend"
    exit 1
fi

# 3. Build Frontend
echo ""
echo "🎨 [3/4] Construyendo Frontend..."
FRONTEND_IMAGE="$ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$PROJECT_NAME-frontend:latest"
docker buildx build --platform linux/amd64 -t "$FRONTEND_IMAGE" ./front_despacho --push

if [ $? -eq 0 ]; then
    echo "✅ Frontend construido: $FRONTEND_IMAGE"
else
    echo "❌ Error construyendo Frontend"
    exit 1
fi

# 4. Update ECS Service
echo ""
echo "🐳 [4/4] Actualizando ECS Service..."
aws ecs update-service \
    --cluster "$PROJECT_NAME-cluster" \
    --service "$PROJECT_NAME-service" \
    --force-new-deployment \
    --region "$AWS_REGION"

if [ $? -eq 0 ]; then
    echo "✅ ECS Service actualizado"
else
    echo "❌ Error actualizando ECS Service"
    exit 1
fi

echo ""
echo "📊 Estado actual:"
aws ecs describe-services \
    --cluster "$PROJECT_NAME-cluster" \
    --services "$PROJECT_NAME-service" \
    --region "$AWS_REGION" \
    --query 'services[0].[serviceName,status,runningCount,desiredCount]' \
    --output table

echo ""
echo "✅ ¡Despliegue completado exitosamente!"
echo "🔗 Espera 2-3 minutos para que ECS lance las nuevas tareas..."
