#!/bin/bash

# Script de despliegue para Terraform en AWS
# Uso: ./deploy.sh [etapa_1|etapa_2] [init|plan|apply|destroy]

set -e

ETAPA=${1:-etapa_1}
ACCION=${2:-plan}

ROJO='\033[0;31m'
VERDE='\033[0;32m'
AMARILLO='\033[1;33m'
NC='\033[0m'

echo -e "${AMARILLO}========================================${NC}"
echo -e "${AMARILLO}DevOps Project - Terraform Deployer${NC}"
echo -e "${AMARILLO}========================================${NC}"

# Validar etapa
if [ "$ETAPA" != "etapa_1" ] && [ "$ETAPA" != "etapa_2" ]; then
    echo -e "${ROJO}Error: Usa 'etapa_1' o 'etapa_2'${NC}"
    exit 1
fi

# Validar acción
if [ "$ACCION" != "init" ] && [ "$ACCION" != "plan" ] && [ "$ACCION" != "apply" ] && [ "$ACCION" != "destroy" ]; then
    echo -e "${ROJO}Error: Usa 'init', 'plan', 'apply' o 'destroy'${NC}"
    exit 1
fi

cd "infra/$ETAPA"

echo -e "${VERDE}Directorio: $(pwd)${NC}"
echo -e "${VERDE}Acción: $ACCION${NC}"

case $ACCION in
    init)
        echo -e "${AMARILLO}Inicializando Terraform...${NC}"
        terraform init
        ;;
    plan)
        echo -e "${AMARILLO}Generando plan...${NC}"
        terraform plan -out=tfplan
        ;;
    apply)
        echo -e "${AMARILLO}Aplicando cambios...${NC}"
        if [ ! -f tfplan ]; then
            echo -e "${ROJO}Error: Ejecuta 'plan' primero${NC}"
            exit 1
        fi
        terraform apply tfplan
        rm tfplan
        ;;
    destroy)
        echo -e "${ROJO}⚠️  Esto destruirá todos los recursos en $ETAPA${NC}"
        read -p "¿Estás seguro? (s/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            terraform destroy -auto-approve
        else
            echo -e "${AMARILLO}Cancelado${NC}"
        fi
        ;;
esac

echo -e "${VERDE}✓ Completado${NC}"
