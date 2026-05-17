#!/bin/bash

# Script para limpiar recursos de ECS antes de terraform destroy
# Uso: ./cleanup-ecs.sh

set -e

CLUSTER="devops-u2-cluster"
SERVICE="devops-u2-service"
REGION="us-east-1"

echo "=================================================="
echo "  Limpiando recursos ECS"
echo "=================================================="
echo ""

# 1. Eliminar servicio
echo "🔄 [1/3] Eliminando servicio ECS: $SERVICE..."
aws ecs delete-service \
    --cluster "$CLUSTER" \
    --service "$SERVICE" \
    --force \
    --region "$REGION" 2>/dev/null || true

echo "✅ Servicio marcado para eliminación"
echo ""

# 2. Esperar a que se elimine
echo "⏳ [2/3] Esperando a que el servicio se elimine (30 segundos)..."
sleep 30

# 3. Listar tareas y detenerlas
echo ""
echo "🛑 [3/3] Deteniendo tareas activas..."
TASKS=$(aws ecs list-tasks --cluster "$CLUSTER" --region "$REGION" --query 'taskArns[]' --output text 2>/dev/null || true)

if [ ! -z "$TASKS" ]; then
    for TASK in $TASKS; do
        echo "   Deteniendo tarea: $TASK"
        aws ecs stop-task --cluster "$CLUSTER" --task "$TASK" --region "$REGION" 2>/dev/null || true
    done
    echo "✅ Tareas detenidas"
else
    echo "✅ No hay tareas activas"
fi

echo ""
echo "=================================================="
echo "  ✅ Cleanup completado"
echo "  Ahora puedes ejecutar: terraform destroy"
echo "=================================================="
