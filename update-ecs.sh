#!/bin/bash

# Script para actualizar servicio ECS desde Git Bash
# Uso: ./update-ecs.sh

set -e

CLUSTER="devops-u2-cluster"
SERVICE="devops-u2-service"
REGION="us-east-1"
ACCOUNT_ID="404971863212"

echo "=================================================="
echo "  Actualizando servicio ECS"
echo "=================================================="
echo ""

# Verificar que AWS CLI esté disponible
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI no está instalado"
    exit 1
fi

# Actualizar servicio
echo "🚀 Forzando nuevo despliegue en $SERVICE..."
aws ecs update-service \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --force-new-deployment \
    --region "$REGION"

if [ $? -eq 0 ]; then
    echo "✅ Servicio actualizado exitosamente"
    echo ""
    echo "⏳ Esperando 5 segundos..."
    sleep 5
    
    echo ""
    echo "📊 Estado actual del servicio:"
    aws ecs describe-services \
        --cluster "$CLUSTER" \
        --services "$SERVICE" \
        --region "$REGION" \
        --query 'services[0].[serviceName,status,runningCount,desiredCount,deployments[0].status]' \
        --output table
    
    echo ""
    echo "✅ ¡Actualización completada!"
else
    echo "❌ Error actualizando el servicio"
    exit 1
fi
