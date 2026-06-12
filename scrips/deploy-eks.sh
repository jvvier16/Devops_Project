#!/bin/bash
# Script de despliegue en AWS EKS - Proyecto Despachos
# Uso: ./deploy-eks.sh [init|deploy|destroy|status]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${PROJECT_ROOT}/infra/terraform"
K8S_DIR="${PROJECT_ROOT}/infra/k8s"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Funciones de logging
log()  { echo -e "${GREEN}[✓]${NC} $*"; }
info() { echo -e "${BLUE}[ℹ]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }

# Verificar requisitos
check_requirements() {
  info "Verificando requisitos..."
  local missing=0
  
  for cmd in aws kubectl terraform docker; do
    if ! command -v "$cmd" &> /dev/null; then
      err "Falta: $cmd"
      missing=1
    fi
  done
  
  if [[ $missing -eq 1 ]]; then
    err "Por favor instala los comandos faltantes"
    exit 1
  fi
  
  # Verificar AWS credentials
  if ! aws sts get-caller-identity &> /dev/null; then
    err "Credenciales AWS no válidas. Ejecuta: aws configure"
    exit 1
  fi
  
  log "Todos los requisitos están OK"
}

# Obtener valores de Terraform
get_tf_output() {
  local key="$1"
  (cd "$TERRAFORM_DIR" && terraform output -raw "$key" 2>/dev/null) || echo ""
}

# Inicializar Terraform
init_terraform() {
  info "Inicializando Terraform..."
  cd "$TERRAFORM_DIR"
  terraform init
  terraform validate || {
    err "Validación de Terraform falló"
    exit 1
  }
  log "Terraform inicializado"
}

# Desplegar infraestructura
deploy_infrastructure() {
  info "Desplegando infraestructura en AWS..."
  cd "$TERRAFORM_DIR"
  
  terraform plan -out=tfplan
  log "Plan de Terraform creado"
  
  terraform apply tfplan
  log "Infraestructura desplegada"
  
  # Obtener outputs
  local cluster_name backend_ecr frontend_ecr
  cluster_name=$(get_tf_output cluster_name)
  backend_ecr=$(get_tf_output backend_despacho_ecr_url)
  frontend_ecr=$(get_tf_output frontend_despacho_ecr_url)
  
  info "Cluster: $cluster_name"
  info "Backend ECR: $backend_ecr"
  info "Frontend ECR: $frontend_ecr"
}

# Configurar kubeconfig
setup_kubeconfig() {
  info "Configurando kubeconfig..."
  local cluster_name
  cluster_name=$(get_tf_output cluster_name)
  
  if [[ -z "$cluster_name" ]]; then
    err "No se encontró el cluster. ¿Ya desplegaste la infraestructura?"
    exit 1
  fi
  
  aws eks update-kubeconfig --name "$cluster_name" --region us-east-1
  log "Kubeconfig configurado para: $cluster_name"
}

# Login en ECR
ecr_login() {
  info "Autenticando en ECR..."
  aws ecr get-login-password --region us-east-1 | \
    docker login --username AWS --password-stdin \
    "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.us-east-1.amazonaws.com"
  log "Login en ECR exitoso"
}

# Construir imágenes Docker
build_images() {
  info "Construyendo imágenes Docker..."
  local account_id region registry
  account_id=$(aws sts get-caller-identity --query Account --output text)
  region="us-east-1"
  registry="${account_id}.dkr.ecr.${region}.amazonaws.com"
  
  # Backend Despacho
  info "Backend Despacho..."
  docker buildx build --platform linux/amd64 \
    -t "${registry}/backend-despacho:latest" \
    "${PROJECT_ROOT}/back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO" \
    --load
  
  # Backend Ventas
  info "Backend Ventas..."
  docker buildx build --platform linux/amd64 \
    -t "${registry}/backend-ventas:latest" \
    "${PROJECT_ROOT}/back-Ventas_SpringBoot/Springboot-API-REST" \
    --load
  
  # Frontend
  info "Frontend..."
  docker buildx build --platform linux/amd64 \
    -t "${registry}/frontend-despacho:latest" \
    "${PROJECT_ROOT}/front_despacho" \
    --load
  
  log "Imágenes construidas"
}

# Push de imágenes a ECR
push_images() {
  info "Publicando imágenes en ECR..."
  local account_id registry
  account_id=$(aws sts get-caller-identity --query Account --output text)
  registry="${account_id}.dkr.ecr.us-east-1.amazonaws.com"
  
  docker push "${registry}/backend-despacho:latest"
  docker push "${registry}/backend-ventas:latest"
  docker push "${registry}/frontend-despacho:latest"
  
  log "Imágenes publicadas"
}

# Aplicar manifiestos Kubernetes
apply_k8s() {
  info "Aplicando manifiestos de Kubernetes..."
  local account_id region
  account_id=$(aws sts get-caller-identity --query Account --output text)
  region="us-east-1"
  
  export ACCOUNT_ID="$account_id"
  export AWS_REGION="$region"
  export IMAGE_TAG="latest"
  
  # Aplicar en orden
  for file in configmap.yml mysql.yml backend-ventas.yml backend.yml frontend.yml hpa.yml; do
    if [[ -f "${K8S_DIR}/${file}" ]]; then
      info "Aplicando: $file"
      envsubst < "${K8S_DIR}/${file}" | kubectl apply -f -
    fi
  done
  
  log "Manifiestos aplicados"
}

# Esperar a que los pods estén listos
wait_for_pods() {
  info "Esperando a que los pods estén listos..."
  
  for deployment in mysql backend-ventas backend-despacho frontend-despacho; do
    warn "Esperando: $deployment"
    kubectl rollout status deployment/$deployment --timeout=5m || {
      err "Timeout esperando $deployment"
      return 1
    }
  done
  
  log "Todos los pods están listos"
}

# Obtener Load Balancer endpoint
get_lb_endpoint() {
  info "Obteniendo Load Balancer endpoint..."
  local endpoint timeout elapsed
  timeout=300
  elapsed=0
  
  while [[ $elapsed -lt $timeout ]]; do
    endpoint=$(kubectl get svc frontend-despacho \
      -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [[ -n "$endpoint" ]]; then
      log "Frontend disponible en: http://${endpoint}"
      echo "$endpoint" > /tmp/despachos_endpoint.txt
      return 0
    fi
    
    sleep 10
    elapsed=$((elapsed + 10))
    echo -n "."
  done
  
  echo ""
  warn "Load Balancer aún no tiene endpoint. Intenta más tarde con: kubectl get svc frontend-despacho"
  return 1
}

# Mostrar status
show_status() {
  echo ""
  info "=== ESTADO DEL CLUSTER ==="
  echo ""
  
  info "Nodes:"
  kubectl get nodes
  
  echo ""
  info "Deployments:"
  kubectl get deployments
  
  echo ""
  info "Pods:"
  kubectl get pods
  
  echo ""
  info "Services:"
  kubectl get svc
  
  if [[ -f /tmp/despachos_endpoint.txt ]]; then
    local endpoint
    endpoint=$(cat /tmp/despachos_endpoint.txt)
    echo ""
    log "Frontend: http://${endpoint}"
  fi
}

# Comando: init
cmd_init() {
  info "=== INICIALIZACIÓN DE TERRAFORM ==="
  check_requirements
  init_terraform
  log "Listo para desplegar. Ejecuta: ./deploy-eks.sh deploy"
}

# Comando: deploy
cmd_deploy() {
  info "=== DESPLIEGUE COMPLETO ==="
  check_requirements
  init_terraform
  deploy_infrastructure
  setup_kubeconfig
  ecr_login
  build_images
  push_images
  apply_k8s
  wait_for_pods || true
  get_lb_endpoint || true
  show_status
  log "¡Despliegue completado!"
}

# Comando: destroy
cmd_destroy() {
  info "=== DESTRUIR INFRAESTRUCTURA ==="
  warn "Esto eliminará todos los recursos en AWS. ¿Continuar? (s/n)"
  read -r response
  if [[ ! "$response" =~ ^[sS]$ ]]; then
    info "Cancelado"
    return
  fi
  
  check_requirements
  cd "$TERRAFORM_DIR"
  terraform destroy -auto-approve
  log "Infraestructura destruida"
}

# Comando: status
cmd_status() {
  info "=== ESTADO ACTUAL ==="
  check_requirements
  setup_kubeconfig || true
  show_status
}

# Función de ayuda
show_help() {
  cat << EOF
Uso: ./deploy-eks.sh [COMANDO]

Comandos:
  init       Inicializar Terraform
  deploy     Desplegar infraestructura completa
  destroy    Destruir toda la infraestructura
  status     Mostrar estado actual del cluster
  help       Mostrar esta ayuda

Ejemplos:
  ./deploy-eks.sh init
  ./deploy-eks.sh deploy
  ./deploy-eks.sh status
  ./deploy-eks.sh destroy

EOF
}

# Main
main() {
  local cmd="${1:-help}"
  
  case "$cmd" in
    init)    cmd_init ;;
    deploy)  cmd_deploy ;;
    destroy) cmd_destroy ;;
    status)  cmd_status ;;
    help|-h|--help) show_help ;;
    *)
      err "Comando desconocido: $cmd"
      show_help
      exit 1
      ;;
  esac
}

main "$@"
