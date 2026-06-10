# 🚀 Proyecto DevOps - Sistema de Despachos en AWS EKS

**Grupo:** DevOps 2025 | **Encargo:** IE3-IE7 (Configuración AWS, Despliegue, Autoscaling, CI/CD)  
**Asignatura:** Infraestructura y DevOps | **Institución:** TAITE

Arquitectura de microservicios modernos con Kubernetes (EKS), Spring Boot 3.4.4, React 18 + Vite y MySQL 8.0. Despliegue completamente automatizado en AWS con CI/CD.

---

## 📋 Tabla de Contenidos

1. [Descripción del Proyecto](#descripción-del-proyecto)
2. [Arquitectura](#arquitectura)
3. [Requisitos del Sistema](#requisitos-del-sistema)
4. [Inicio Rápido Local](#inicio-rápido-local)
5. [Despliegue en AWS EKS](#despliegue-en-aws-eks)
6. [Configuración de Autoscaling](#configuración-de-autoscaling)
7. [Pipeline CI/CD](#pipeline-cicd)
8. [Validación y Pruebas](#validación-y-pruebas)
9. [Troubleshooting](#troubleshooting)
10. [Estructura de Commits](#estructura-de-commits)
11. [Consideraciones de Seguridad](#consideraciones-de-seguridad)

---

## 📝 Descripción del Proyecto

Este proyecto implementa un **sistema de gestión de despachos y ventas** con arquitectura de microservicios desplegada en **AWS EKS (Elastic Kubernetes Service)**.

### Componentes Principales:

| Componente | Tecnología | Puerto | Descripción |
|-----------|-----------|--------|------------|
| **Backend Despachos** | Spring Boot 3.4.4 | 8081 | API REST para gestión de despachos |
| **Backend Ventas** | Spring Boot 3.4.4 | 8080 | API REST para gestión de ventas |
| **Frontend** | React 18 + Vite | 3000 (local), 80 (prod) | Interfaz de usuario con Nginx |
| **Base de Datos** | MySQL 8.0 | 3306 | Base de datos centralizada |
| **Orquestación** | Kubernetes (EKS) | - | Orquestación de contenedores |
| **Registro** | Amazon ECR | - | Almacenamiento de imágenes Docker |
| **CI/CD** | GitHub Actions | - | Pipeline de despliegue automático |

---

## 🏗️ Arquitectura

### Diagrama General (AWS EKS)

```
┌───────────────────────────────────────────────────────────────────┐
│                        AWS ACCOUNT                                │
├───────────────────────────────────────────────────────────────────┤
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │                     AWS EKS CLUSTER                        │  │
│  │  (despachos-cluster, us-east-1)                           │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────┐     │  │
│  │  │            VPC (10.0.0.0/16)                    │     │  │
│  │  │                                                  │     │  │
│  │  │  Subnet Pub: 10.0.1.0/24  │  Subnet Priv: 10.0.10.0/24
│  │  │  (us-east-1a)             │  (us-east-1a)      │     │  │
│  │  │                                                  │     │  │
│  │  │  ┌──────────────────────┐                        │     │  │
│  │  │  │  Control Plane       │                        │     │  │
│  │  │  │  (AWS Managed)       │                        │     │  │
│  │  │  └──────────────────────┘                        │     │  │
│  │  │                                                  │     │  │
│  │  │  ┌──────────────────────────────────────────┐   │     │  │
│  │  │  │      Worker Nodes (2-4, t3.medium)      │   │     │  │
│  │  │  │                                          │   │     │  │
│  │  │  │  ┌─────────────────────────────────┐    │   │     │  │
│  │  │  │  │   Frontend Despacho (LB)       │    │   │     │  │
│  │  │  │  │   - 1 pod (HPA: 1-3)          │    │   │     │  │
│  │  │  │  │   - Nginx reverse proxy        │    │   │     │  │
│  │  │  │  │   - Escucha puerto 8080        │    │   │     │  │
│  │  │  │  └─────────────────────────────────┘    │   │     │  │
│  │  │  │                ↕ (DNS)                  │   │     │  │
│  │  │  │  ┌─────────────────────────────────┐    │   │     │  │
│  │  │  │  │ Backend Despacho (ClusterIP)   │    │   │     │  │
│  │  │  │  │ - 2 pods (HPA: 2-5)            │    │   │     │  │
│  │  │  │  │ - Spring Boot 3.4.4            │    │   │     │  │
│  │  │  │  │ - Puerto 8081                  │    │   │     │  │
│  │  │  │  └─────────────────────────────────┘    │   │     │  │
│  │  │  │                ↕ (DNS)                  │   │     │  │
│  │  │  │  ┌─────────────────────────────────┐    │   │     │  │
│  │  │  │  │  MySQL Service (ClusterIP)    │    │   │     │  │
│  │  │  │  │  - 1 pod (StatefulSet)         │    │   │     │  │
│  │  │  │  │  - Puerto 3306                 │    │   │     │  │
│  │  │  │  │  - PersistentVolume (EBS)      │    │   │     │  │
│  │  │  │  └─────────────────────────────────┘    │   │     │  │
│  │  │  │                                          │   │     │  │
│  │  │  └──────────────────────────────────────────┘   │     │  │
│  │  │                                                  │     │  │
│  │  └──────────────────────────────────────────────────┘     │  │
│  │                                                            │  │
│  │  ┌──────────────────────────────────────────────────┐     │  │
│  │  │      AWS Load Balancer (ALB)                    │     │  │
│  │  │      - Expone frontend-despacho Service         │     │  │
│  │  │      - URL pública: http://<ALB-Hostname>      │     │  │
│  │  └──────────────────────────────────────────────────┘     │  │
│  │                                                            │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │            Amazon ECR (Elastic Container Registry)         │  │
│  │  - backend-despacho:latest                                 │  │
│  │  - frontend-despacho:latest                                │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│                    GitHub & CI/CD Pipeline                        │
├───────────────────────────────────────────────────────────────────┤
│                                                                    │
│  Developer Push to 'develop' branch                               │
│           ↓                                                        │
│  GitHub Actions Triggered                                         │
│           ↓                                                        │
│  1. Build Docker Images                                           │
│  2. Push to Amazon ECR                                            │
│  3. Update EKS Deployment                                         │
│  4. Verify Services                                               │
│  5. Get Load Balancer URL                                         │
│           ↓                                                        │
│  Frontend Accessible: http://<ALB-Hostname>                       │
│                                                                    │
└───────────────────────────────────────────────────────────────────┘
```

### Diagrama de Flujo de Solicitudes

```
┌─────────────┐
│   Usuario   │ (Internet)
└──────┬──────┘
       │ HTTP/HTTPS
       ▼
┌─────────────────────────────────────┐
│  AWS Application Load Balancer      │
│  (ALB - Puerto 80/443)              │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Frontend Service (LoadBalancer)    │
│  Kubernetes Service Type: LoadBalancer
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│  Frontend Pod (Nginx)               │
│  Puerto 8080 (internal)             │
└──────┬──────────────────────────────┘
       │
       ├─ GET /api/ventas/*     ──→ Backend Ventas (8080)
       │                             │
       │                             └─→ MySQL (3306)
       │
       └─ GET /api/despachos/*  ──→ Backend Despacho (8081)
                                     │
                                     └─→ MySQL (3306)
```

### Componentes AWS Utilizados

| Componente | Tipo | Descripción | Justificación |
|-----------|------|-------------|--------------|
| **EKS Cluster** | Orquestación | Kubernetes Administrado | Escalable, managed, integrado con AWS |
| **VPC** | Red | Virtual Private Cloud 10.0.0.0/16 | Aislamiento y seguridad |
| **EC2 Nodes** | Compute | 2-4 nodos t3.medium (ASG) | Escalable, costo-efectivo |
| **ALB** | Balanceador | Application Load Balancer | Distribuye tráfico, URL pública |
| **ECR** | Registro | Amazon ECR Repositories | Almacena imágenes Docker |
| **CloudWatch** | Monitoreo | Logs y métricas | Observabilidad |
| **IAM Roles** | Seguridad | EKS Node Role, Task Roles | Control de acceso granular |
| **EBS** | Almacenamiento | Persistent Volumes | BD persistente |

---

## 🔧 Requisitos del Sistema

### Hardware Mínimo (Local)

- **CPU**: 4 cores
- **RAM**: 8 GB (recomendado 16 GB)
- **Disk**: 50 GB libres (para imágenes Docker)
- **Sistema Operativo**: Windows 10/11, macOS, Linux

### Software Requerido

#### 1. Docker Desktop

```bash
# Descargar desde: https://www.docker.com/products/docker-desktop

# Verificar instalación
docker --version
docker run hello-world
```

#### 2. AWS CLI v2

**Windows (PowerShell como Admin)**:
```powershell
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**macOS (Homebrew)**:
```bash
brew install awscli
```

**Linux (Ubuntu/Debian)**:
```bash
curl "https://awscli.amazonaws.com/awscliv2.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Verificar:
```bash
aws --version
```

#### 3. kubectl

**Windows (PowerShell)**:
```powershell
# Descargar desde: https://kubernetes.io/docs/tasks/tools/install-kubectl-on-windows/
# O via Chocolatey:
choco install kubernetes-cli
```

**macOS**:
```bash
brew install kubectl
```

**Linux**:
```bash
sudo snap install kubectl --classic
```

Verificar:
```bash
kubectl version --client
```

#### 4. Git

Descargar desde: https://git-scm.com/

```bash
git --version
```

#### 5. Visual Studio Code

Descargar desde: https://code.visualstudio.com/

Extensiones recomendadas:
- Docker
- Kubernetes
- AWS Toolkit
- Spring Boot Extension Pack
- REST Client

#### 6. Configurar AWS CLI

```bash
# Obtener credenciales desde AWS Academy
aws configure

# Ingresa cuando se te pida:
# AWS Access Key ID: [Tu Key]
# AWS Secret Access Key: [Tu Secret]
# Default region: us-east-1
# Default output format: json

# Verificar
aws sts get-caller-identity
```

---

## 🚀 Inicio Rápido Local

### Opción 1: Docker Compose (Desarrollo)

```bash
# 1. Clonar repositorio
git clone https://github.com/tu-usuario/despachos-devops.git
cd despachos-devops

# 2. Crear archivo .env
cat > .env << EOF
DB_NAME=despachos
DB_USERNAME=root
DB_PASSWORD=root
EOF

# 3. Construir imágenes (primera vez puede tardar 5-10 minutos)
docker-compose build

# 4. Iniciar servicios
docker-compose up -d

# 5. Verificar estado
docker-compose ps

# Esperado:
# STATUS              PORTS
# Up                  3306/tcp                                  (mysql)
# Up                  0.0.0.0:8080->8080/tcp                   (backend-ventas)
# Up                  0.0.0.0:8081->8081/tcp                   (backend-despachos)
# Up                  0.0.0.0:3000->8080/tcp                   (frontend)

# 6. Acceder a aplicaciones
echo "Frontend:             http://localhost:3000"
echo "Backend Ventas:       http://localhost:8080"
echo "Backend Despacho:     http://localhost:8081/swagger-ui.html"
echo "MySQL:                localhost:3306 (root/root)"

# 7. Ver logs en tiempo real
docker-compose logs -f

# 8. Detener servicios
docker-compose down

# Opcional: Limpiar volúmenes (elimina datos)
docker-compose down -v
```

### Verificación de Salud Local

```bash
# Test backend despacho
curl http://localhost:8081/actuator/health
# Esperado: {"status":"UP"}

# Test backend ventas
curl http://localhost:8080/actuator/health

# Test acceso al swagger del backend despacho
# Abrir navegador: http://localhost:8081/swagger-ui.html
```

---

## ☁️ Despliegue en AWS EKS

### FASE 1: Configuración Inicial AWS Academy

#### Paso 1.1: Obtener Credenciales AWS Academy

1. Ir a: https://awsacademy.instructure.com
2. Ingresar a "Learner Lab" o "Educate"
3. Copiar credenciales temporales (Access Key, Secret Key, Session Token)
4. Configurar en máquina local:

```bash
aws configure

# Pegar valores proporcionados por AWS Academy
# Región: us-east-1
# Output: json
```

#### Paso 1.2: Verificar Acceso AWS

```bash
# Verificar identidad AWS
aws sts get-caller-identity

# Salida esperada:
# {
#     "UserId": "AIDAI...",
#     "Account": "123456789012",
#     "Arn": "arn:aws:iam::123456789012:user/..."
# }
```

### FASE 2: Crear Infraestructura AWS

#### Paso 2.1: Crear VPC y Subnets

```bash
# 1. Crear VPC
aws ec2 create-vpc --cidr-block 10.0.0.0/16

# Guardar VPC ID de la salida
export VPC_ID="vpc-xxxxxxxxx"

# 2. Crear subnets públicas
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.1.0/24 \
  --availability-zone us-east-1a

aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.2.0/24 \
  --availability-zone us-east-1b

# 3. Crear subnets privadas
aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.10.0/24 \
  --availability-zone us-east-1a

aws ec2 create-subnet \
  --vpc-id $VPC_ID \
  --cidr-block 10.0.11.0/24 \
  --availability-zone us-east-1b

# Guardar IDs de subnets
export SUBNET_1="subnet-xxxxxxxxx"
export SUBNET_2="subnet-xxxxxxxxx"
export SUBNET_3="subnet-xxxxxxxxx"
export SUBNET_4="subnet-xxxxxxxxx"
```

#### Paso 2.2: Crear Internet Gateway

```bash
# Crear IGW
aws ec2 create-internet-gateway

# Guardar IGW ID
export IGW_ID="igw-xxxxxxxxx"

# Adjuntar a VPC
aws ec2 attach-internet-gateway \
  --vpc-id $VPC_ID \
  --internet-gateway-id $IGW_ID
```

#### Paso 2.3: Configurar Rutas

```bash
# Obtener Route Table de VPC
aws ec2 describe-route-tables \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'RouteTables[0].RouteTableId' \
  --output text

export ROUTE_TABLE_ID="rtb-xxxxxxxxx"

# Agregar ruta a Internet
aws ec2 create-route \
  --route-table-id $ROUTE_TABLE_ID \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id $IGW_ID
```

#### Paso 2.4: Crear Roles IAM

```bash
# Crear confianza policy para EKS
cat > trust-policy-eks.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Crear rol EKS
aws iam create-role \
  --role-name EksServiceRole \
  --assume-role-policy-document file://trust-policy-eks.json

# Adjuntar políticas
aws iam attach-role-policy \
  --role-name EksServiceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSServiceRolePolicy

aws iam attach-role-policy \
  --role-name EksServiceRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSVPCResourceController

# Guardar ARN
export EKS_ROLE_ARN=$(aws iam get-role \
  --role-name EksServiceRole \
  --query 'Role.Arn' \
  --output text)

echo "EKS Role ARN: $EKS_ROLE_ARN"
```

```bash
# Crear confianza policy para nodos EC2
cat > trust-policy-nodes.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Crear rol de nodos
aws iam create-role \
  --role-name EksNodeRole \
  --assume-role-policy-document file://trust-policy-nodes.json

# Adjuntar políticas
aws iam attach-role-policy \
  --role-name EksNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name EksNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name EksNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly

# Guardar ARN
export NODE_ROLE_ARN=$(aws iam get-role \
  --role-name EksNodeRole \
  --query 'Role.Arn' \
  --output text)

echo "Node Role ARN: $NODE_ROLE_ARN"
```

#### Paso 2.5: Crear EKS Cluster

```bash
# Crear cluster (tarda ~10-15 minutos)
aws eks create-cluster \
  --name despachos-cluster \
  --version 1.29 \
  --role-arn $EKS_ROLE_ARN \
  --resources-vpc-config \
    subnetIds=$SUBNET_1,$SUBNET_2,$SUBNET_3,$SUBNET_4 \
  --region us-east-1

# Esperar a que se cree
aws eks wait cluster-created \
  --name despachos-cluster \
  --region us-east-1

# Verificar estado
aws eks describe-cluster \
  --name despachos-cluster \
  --region us-east-1 \
  --query 'cluster.status'

# Actualizar kubeconfig
aws eks update-kubeconfig \
  --name despachos-cluster \
  --region us-east-1

# Verificar conexión a cluster
kubectl get nodes
# Esperado: No nodes yet (se agregan en paso siguiente)
```

#### Paso 2.6: Crear Node Group

```bash
# Crear grupo de nodos (tarda ~5-10 minutos)
aws eks create-nodegroup \
  --cluster-name despachos-cluster \
  --nodegroup-name despachos-nodes \
  --subnets $SUBNET_3 $SUBNET_4 \
  --node-role $NODE_ROLE_ARN \
  --scaling-config minSize=2,maxSize=4,desiredSize=2 \
  --instance-types t3.medium \
  --region us-east-1

# Esperar a que se creen nodos
aws eks wait nodegroup-active \
  --cluster-name despachos-cluster \
  --nodegroup-name despachos-nodes \
  --region us-east-1

# Verificar nodos
kubectl get nodes
kubectl get nodes -o wide

# Esperado:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-10-xxx.ec2.internal   Ready    <none>   2m    v1.29.0
# ip-10-0-11-xxx.ec2.internal   Ready    <none>   2m    v1.29.0
```

### FASE 3: Crear Repositorios ECR

```bash
# Obtener AWS Account ID
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=us-east-1

# Crear repositorio para backend-despacho
aws ecr create-repository \
  --repository-name backend-despacho \
  --region $AWS_REGION

# Crear repositorio para frontend-despacho
aws ecr create-repository \
  --repository-name frontend-despacho \
  --region $AWS_REGION

# Listar repositorios
aws ecr describe-repositories --region $AWS_REGION
```

### FASE 4: Construir y Pushear Imágenes a ECR

```bash
# Login a ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# ===== BUILD BACKEND DESPACHO =====
docker build \
  -t backend-despacho:latest \
  -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend-despacho:latest \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO

# Push Backend Despacho
docker push \
  $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/backend-despacho:latest

# ===== BUILD FRONTEND =====
docker build \
  -t frontend-despacho:latest \
  -t $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend-despacho:latest \
  ./front_despacho

# Push Frontend
docker push \
  $ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/frontend-despacho:latest

# Verificar imágenes en ECR
aws ecr describe-images --repository-name backend-despacho --region $AWS_REGION
aws ecr describe-images --repository-name frontend-despacho --region $AWS_REGION
```

### FASE 5: Actualizar Manifiestos Kubernetes

```bash
# Actualizar variable ACCOUNT_ID en manifiestos
sed -i.bak "s/\\\${ACCOUNT_ID}/$ACCOUNT_ID/g" infra/k8s/*.yml

# En macOS:
# sed -i '' "s/\\\${ACCOUNT_ID}/$ACCOUNT_ID/g" infra/k8s/*.yml

# Verificar cambios
grep "dkr.ecr" infra/k8s/*.yml
```

### FASE 6: Desplegar en EKS

```bash
# 1. Crear namespace (opcional)
kubectl create namespace despachos

# 2. Cambiar contexto (opcional)
kubectl config set-context --current --namespace=despachos

# 3. Aplicar manifiestos
kubectl apply -f infra/k8s/

# 4. Verificar deployments
kubectl get deployments -o wide
kubectl get services -o wide
kubectl get pods -w

# Esperado:
# NAME                     READY   UP-TO-DATE   AVAILABLE
# backend-despacho         2/2     2            2
# frontend-despacho        1/1     1            1
# mysql                    1/1     1            1

# 5. Obtener Load Balancer URL pública
kubectl get svc frontend-despacho -o wide

# Buscar en EXTERNAL-IP (puede tardar 2-3 minutos)
kubectl get svc frontend-despacho -w

# 6. Acceder a frontend
# http://<EXTERNAL-IP>
```

---

## 📊 Configuración de Autoscaling

### Componente 1: Horizontal Pod Autoscaler (HPA)

HPA escala automáticamente el número de pods basándose en métricas de CPU y memoria.

#### Instalación de Metrics Server (requerido para HPA)

```bash
# Instalar Metrics Server
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Verificar instalación
kubectl get deployment metrics-server -n kube-system

# Esperar a que esté ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/metrics-server -n kube-system
```

#### Crear HPA para Backend Despacho

Archivo: `infra/k8s/hpa.yml`

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-despacho-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-despacho
  minReplicas: 2
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 70
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 50
          periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
        - type: Percent
          value: 100
          periodSeconds: 30

---

apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-despacho-hpa
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend-despacho
  minReplicas: 1
  maxReplicas: 3
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 60
```

**Justificación de valores**:
- **Backend minReplicas: 2** - Mínimo 2 para alta disponibilidad
- **Backend maxReplicas: 5** - Máximo para controlar costos
- **CPU 50%** - Escalado agresivo para responder rápido a cargas
- **Memory 70%** - Margen de seguridad ante picos
- **Frontend minReplicas: 1** - Menos crítico, ahorra costos
- **Frontend maxReplicas: 3** - Raro que necesite más

Aplicar:
```bash
kubectl apply -f infra/k8s/hpa.yml

# Verificar
kubectl get hpa
kubectl describe hpa backend-despacho-hpa
```

#### Monitorear HPA en Tiempo Real

```bash
# Watch del HPA
kubectl get hpa -w

# Ver métricas de CPU/Memory
kubectl top pods

# Ver eventos de scaling
kubectl get events --sort-by='.lastTimestamp'

# Ver detalles del HPA
kubectl describe hpa backend-despacho-hpa
```

### Componente 2: Auto Scaling Group de Nodos

Los nodos EC2 se escalan automáticamente para soportar más pods.

```bash
# Actualizar Auto Scaling Group
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name eks-despachos-nodes-asg \
  --min-size 2 \
  --max-size 4 \
  --desired-capacity 2 \
  --region us-east-1

# Verificar
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names eks-despachos-nodes-asg \
  --region us-east-1
```

### Componente 3: Prueba de Autoscaling (Test de Carga)

```bash
# 1. Obtener nombre de un pod backend
BACKEND_POD=$(kubectl get pods -l app=backend-despacho -o jsonpath='{.items[0].metadata.name}')

# 2. Ejecutar generador de carga dentro del cluster
kubectl run -it --rm load-generator \
  --image=busybox:1.28 \
  --restart=Never \
  -- /bin/sh

# 3. Dentro del pod, ejecutar loops de requests (cuidado: puede costar recursos)
# while true; do \
#   wget -q -O- http://backend-despacho:8081/actuator/health; \
# done

# 4. En otra terminal, monitorear el escalado
watch kubectl get hpa,pods,nodes

# Esperado:
# - CPU sube encima de 50%
# - HPA aumenta replicas de backend-despacho
# - Si faltan recursos, nodos adicionales se crean
```

---

## 🔄 Pipeline CI/CD

### Visión General del Pipeline

```
GitHub commit en 'develop'
         │
         ▼
GitHub Actions Triggered
         │
         ├─▶ Checkout código
         │
         ├─▶ Configurar AWS credentials
         │
         ├─▶ Login a ECR
         │
         ├─▶ Build Backend
         │    └─▶ docker build -t backend-despacho:latest
         │
         ├─▶ Push Backend a ECR
         │    └─▶ docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/backend-despacho:latest
         │
         ├─▶ Build Frontend
         │    └─▶ docker build -t frontend-despacho:latest
         │
         ├─▶ Push Frontend a ECR
         │    └─▶ docker push $ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/frontend-despacho:latest
         │
         ├─▶ Configure kubectl
         │    └─▶ aws eks update-kubeconfig
         │
         ├─▶ Apply Kubernetes manifests
         │    └─▶ kubectl apply -f infra/k8s/
         │
         ├─▶ Update Deployment Images
         │    └─▶ kubectl set image deployment/backend-despacho
         │    └─▶ kubectl set image deployment/frontend-despacho
         │
         ├─▶ Wait for Rollout
         │    └─▶ kubectl rollout status
         │
         ├─▶ Verify Services
         │    └─▶ kubectl get svc frontend-despacho
         │
         └─▶ Get Load Balancer URL
              └─▶ kubectl get service frontend-despacho -o jsonpath
                 └─▶ Disponible en: http://<LB-HOSTNAME>
```

### Configuración del Pipeline

Archivo: `.github/workflows/ci.yml`

Características:
- **Triggers**: Push y Pull Request a rama `develop`
- **Build**: Docker Buildx con platform `linux/amd64`
- **Registry**: Amazon ECR
- **Deploy**: Kubectl update en EKS
- **Validación**: Verificación de servicios y obtención de URL pública

Para ver contenido completo del archivo, revisar [.github/workflows/ci.yml](.github/workflows/ci.yml)

### Activar Pipeline CI/CD

```bash
# 1. Crear rama develop si no existe
git checkout -b develop
git push -u origin develop

# 2. Realizar cambios al código

# 3. Hacer commit explicativo
git add .
git commit -m "feat: Actualizar configuración de despachos"
# Ver sección "Estructura de Commits" para más detalles

# 4. Push a develop
git push origin develop

# 5. GitHub Actions se ejecutará automáticamente
# Ver en: https://github.com/tu-usuario/despachos-devops/actions

# 6. Esperar a que termine (5-10 minutos típicamente)

# 7. Acceder a frontend con URL del Load Balancer
curl $(kubectl get svc frontend-despacho -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

### Monitorar Pipeline

```bash
# Ver workflow en GitHub Actions
# https://github.com/tu-usuario/despachos-devops/actions

# O en línea de comandos:
gh run list
gh run view <RUN_ID>

# Ver logs del deployment en EKS
kubectl logs -f deployment/backend-despacho
kubectl logs -f deployment/frontend-despacho
```

---

## 🧪 Validación y Pruebas

### Checklist de Validación

- [ ] Cluster EKS creado y con 2+ nodos running
- [ ] Imágenes en ECR
- [ ] MySQL pod running con datos persistentes
- [ ] Backend Despacho respondiendo en :8081
- [ ] Backend Ventas respondiendo en :8080
- [ ] Frontend accesible por URL pública
- [ ] Frontend se conecta a backends vía DNS interno
- [ ] HPA activo y monitoreando métricas
- [ ] Autoscaling responde a carga
- [ ] CI/CD pipeline ejecutando automáticamente

### Test 1: Verificar Cluster y Nodos

```bash
kubectl cluster-info
kubectl get nodes -o wide
kubectl describe nodes

# Esperado:
# - 2+ nodos en status "Ready"
# - Capacidad CPU y Memory disponible
```

### Test 2: Verificar Deployments y Pods

```bash
kubectl get deployments -o wide
kubectl get pods -o wide
kubectl describe pod <backend-pod-name>

# Esperado:
# - Todos los pods en status "Running"
# - Containers ready
# - Sin errores en eventos
```

### Test 3: Health Checks

```bash
# Dentro de cluster
kubectl exec -it <backend-pod> -- \
  curl http://backend-despacho:8081/actuator/health

# Esperado:
# {"status":"UP"}

# Conectividad a MySQL
kubectl exec -it <backend-pod> -- \
  bash -c "echo > /dev/tcp/mysql/3306 && echo 'MySQL OK' || echo 'MySQL FAIL'"
```

### Test 4: Acceso Público Frontend

```bash
# Obtener URL pública
ALB_URL=$(kubectl get svc frontend-despacho -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Acceder con curl
curl http://$ALB_URL
curl -I http://$ALB_URL

# Abrir en navegador
# http://$ALB_URL
```

### Test 5: Comunicación Front-Back

```bash
# 1. Desde navegador (Dev Tools F12)
# 2. Abrir Console tab
# 3. Ejecutar:
fetch('/api/despachos/despachos')
  .then(r => r.json())
  .then(d => console.log(d))

# Esperado: respuesta JSON desde backend
```

### Test 6: Prueba de Autoscaling

```bash
# Terminal 1: Monitor HPA y pods
watch 'kubectl get hpa,pods -o wide'

# Terminal 2: Generar carga
kubectl run --rm -it load-test --image=busybox -- \
  sh -c "for i in $(seq 1 1000); do \
    wget -q -O- http://backend-despacho:8081/despachos & \
  done; wait"

# Observar:
# - CPU sube en `kubectl top pods`
# - Replicas de backend-despacho aumentan
# - Después de parar carga, replicas disminuyen (con delay)
```

### Test 7: Verificar Persistencia de Datos

```bash
# 1. Insertar dato en DB
kubectl exec -it mysql-0 -- \
  mysql -u root -proot despachos -e \
  "INSERT INTO despachos (id, descripcion) VALUES (1, 'Test Despacho');"

# 2. Consultar dato
kubectl exec -it mysql-0 -- \
  mysql -u root -proot despachos -e \
  "SELECT * FROM despachos;"

# 3. Eliminar pod MySQL
kubectl delete pod mysql-0

# 4. Esperar a que se recree
kubectl get pods -w

# 5. Consultar dato nuevamente (debe existir)
kubectl exec -it mysql-0 -- \
  mysql -u root -proot despachos -e \
  "SELECT * FROM despachos;"
```

---

## 🛠️ Troubleshooting

### Error: Pod no inicia (ImagePullBackOff)

**Síntomas**: `kubectl get pods` muestra status ImagePullBackOff

**Causas posibles**:
1. Imagen no existe en ECR
2. Nodos no tienen credenciales ECR
3. Imagen tag incorrecto

**Soluciones**:
```bash
# 1. Verificar imagen en ECR
aws ecr describe-images --repository-name backend-despacho

# 2. Crear secret para ECR
kubectl create secret docker-registry ecr-secret \
  --docker-server=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)

# 3. Usar secret en deployment
spec:
  imagePullSecrets:
    - name: ecr-secret

# 4. Ver logs del pod
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Error: Backend no conecta a MySQL

**Síntomas**: Logs del backend muestran "Connection refused" a MySQL

**Soluciones**:
```bash
# 1. Verificar si MySQL está running
kubectl get pod -l app=mysql

# 2. Test de conectividad
kubectl exec -it <backend-pod> -- \
  bash -c "timeout 5 bash -c 'echo > /dev/tcp/mysql/3306' && echo 'OK' || echo 'FAIL'"

# 3. Verificar variables de entorno
kubectl exec <backend-pod> -- env | grep DB_

# 4. Ver logs de MySQL
kubectl logs -f <mysql-pod>

# 5. Aumentar timeout de Hikari en application.properties
spring.datasource.hikari.connectionTimeout=60000
```

### Error: Frontend no llega al backend (CORS)

**Síntomas**: Frontend carga, pero no ve datos. Console muestra CORS error.

**Soluciones**:
```bash
# 1. Verificar CORS en backend
# application.properties debe tener:
spring.web.allow-cors=true

# 2. Verificar configuración CORS en Spring
# Ver: CorsConfig.java

# 3. Test manual desde pod frontend
kubectl exec -it <frontend-pod> -- \
  curl http://backend-despacho:8081/actuator/health

# 4. Ver nginx config en frontend
kubectl exec -it <frontend-pod> -- \
  cat /etc/nginx/conf.d/default.conf
```

### Error: Load Balancer no tiene IP pública

**Síntomas**: `kubectl get svc frontend-despacho` muestra `<pending>` en EXTERNAL-IP

**Soluciones**:
```bash
# 1. Es normal que tarde 2-3 minutos
kubectl get svc frontend-despacho -w

# 2. Verificar que ALB Ingress Controller esté instalado
kubectl get pods -n kube-system | grep aws-load-balancer

# 3. Ver logs del ingress controller
kubectl logs -f -n kube-system deployment/aws-load-balancer-controller

# 4. Verificar que el servicio esté correctamente configurado
kubectl describe svc frontend-despacho

# 5. Verificar Security Groups en AWS
aws ec2 describe-security-groups --region us-east-1
```

### Error: HPA muestra "unknown" en métricas

**Síntomas**: `kubectl describe hpa` muestra `<unknown>` para CPU/Memory

**Soluciones**:
```bash
# 1. Verificar que Metrics Server esté instalado
kubectl get deployment -n kube-system metrics-server

# 2. Si no existe, instalar
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 3. Esperar a que esté ready (puede tardar 1-2 minutos)
kubectl wait --for=condition=available --timeout=300s \
  deployment/metrics-server -n kube-system

# 4. Verificar si pods reportan métricas
kubectl top pods

# 5. Ver logs de metrics-server
kubectl logs -f -n kube-system deployment/metrics-server
```

### Error: Recursos insuficientes (Pending pods)

**Síntomas**: Pods quedan en estado "Pending" indefinidamente

**Soluciones**:
```bash
# 1. Ver por qué está pending
kubectl describe pod <pod-name>

# 2. Ver recursos disponibles
kubectl top nodes
kubectl describe nodes

# 3. Agregar más nodos manualmente
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name eks-despachos-nodes-asg \
  --desired-capacity 3 \
  --region us-east-1

# 4. O reducir requests de pods
# En deployment, ajustar:
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

---

## 📝 Estructura de Commits

La dupla debe demostrar cambios incrementales con commits explicativos.

### Formato de Commits Recomendado

```
<tipo>(<scope>): <descripción corta>

<descripción detallada>

<footer>

# Tipos:
# feat: Nueva característica
# fix: Corrección de bug
# docs: Cambios de documentación
# ci: Cambios en pipeline CI/CD
# infra: Cambios en infraestructura (K8s, AWS)
# refactor: Refactorización sin cambiar funcionalidad

# Scopes:
# backend: Cambios en backend
# frontend: Cambios en frontend
# k8s: Manifiestos Kubernetes
# aws: Configuración AWS
# docker: Dockerfiles
```

### Ejemplos de Commits

```bash
# Ejemplo 1: Crear cluster EKS
git commit -m "infra(aws): Crear cluster EKS despachos-cluster

- Cluster version 1.29 con t3.medium nodes
- VPC 10.0.0.0/16 con subnets públicas/privadas
- 2 nodos iniciales, ASG 2-4 nodos
- IAM roles configurados para EKS y EC2"

# Ejemplo 2: Configurar autoscaling
git commit -m "infra(k8s): Implementar HPA para autoscaling

- Backend HPA: 2-5 replicas, CPU 50%, Memory 70%
- Frontend HPA: 1-3 replicas, CPU 60%
- Metrics Server instalado
- Comportamiento de scale up/down configurado"

# Ejemplo 3: Actualizar CI/CD
git commit -m "ci: Actualizar pipeline para EKS deployment

- Build y push a ECR desde GitHub Actions
- Deployment automático con kubectl set image
- Verificación de servicios al final
- Obtención de URL pública del Load Balancer"

# Ejemplo 4: Fix en backend
git commit -m "fix(backend): Resolver timeout en conexión MySQL

- Aumentar Hikari connection timeout a 60s
- Agregar validationTimeout de 5s
- Aumentar maximumPoolSize a 5
- Logs del error en /docs/TROUBLESHOOTING.md

Fixes #123"
```

### Flujo de Git Recomendado

```bash
# 1. Crear rama de feature
git checkout -b feat/hpa-autoscaling

# 2. Realizar cambios
# ... editar archivos ...

# 3. Commit local explicativo
git add infra/k8s/hpa.yml
git commit -m "feat(k8s): Agregar HPA configuration

- Backend: min 2, max 5 replicas
- Frontend: min 1, max 3 replicas
- CPU 50% para backend, 60% para frontend"

# 4. Push a feature branch
git push origin feat/hpa-autoscaling

# 5. Crear Pull Request en GitHub (opcional)

# 6. Merge a develop después de validar
git checkout develop
git pull origin develop
git merge feat/hpa-autoscaling
git push origin develop

# 7. GitHub Actions se ejecutará automáticamente
```

---

## 🔐 Consideraciones de Seguridad

### 1. Secrets Management

**Problema**: Credenciales hardcodeadas en manifiestos

**Solución**: Usar Kubernetes Secrets

```yaml
# 1. Crear secret
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  username: root
  password: secure_password_123

---

# 2. Usar en deployment
env:
  - name: DB_USERNAME
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: username
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
```

```bash
# Crear secret desde línea de comandos
kubectl create secret generic db-credentials \
  --from-literal=username=root \
  --from-literal=password=secure_password

# Verificar secrets
kubectl get secrets
kubectl describe secret db-credentials
```

### 2. RBAC (Role-Based Access Control)

```yaml
# Role para backend
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backend-role
rules:
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["get", "list"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]

---

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: backend-role
subjects:
  - kind: ServiceAccount
    name: default
    namespace: default
```

### 3. Network Policies

```yaml
# Permitir solo frontend a backend
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
spec:
  podSelector:
    matchLabels:
      app: backend-despacho
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend-despacho
      ports:
        - protocol: TCP
          port: 8081

---

# Permitir backend a MySQL
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: mysql-network-policy
spec:
  podSelector:
    matchLabels:
      app: mysql
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: backend-despacho
      ports:
        - protocol: TCP
          port: 3306
```

### 4. Security Context

```yaml
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: backend
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop:
            - ALL
```

### 5. Image Scanning

```bash
# Escanear vulnerabilidades en ECR
aws ecr start-image-scan \
  --repository-name backend-despacho \
  --image-id imageTag=latest \
  --region us-east-1

# Ver resultados
aws ecr describe-image-scan-findings \
  --repository-name backend-despacho \
  --image-id imageTag=latest \
  --region us-east-1
```

---

## 📞 Información de Contacto y Soporte

**Para problemas o preguntas:**

1. Revisar sección [Troubleshooting](#troubleshooting)
2. Consultar logs: `kubectl logs -f <pod-name>`
3. Ver eventos: `kubectl get events --all-namespaces --sort-by='.lastTimestamp'`
4. AWS CloudWatch: Dashboards y métricas
5. GitHub Issues: Reportar bugs

**Recursos útiles:**
- [Documentación EKS](https://docs.aws.amazon.com/eks/)
- [Documentación Kubernetes](https://kubernetes.io/docs/)
- [Spring Boot Docs](https://spring.io/projects/spring-boot)

---

## 📄 Licencia

Proyecto educativo para curso de **Infraestructura y DevOps** - 2025

**Autores**: [Tu Grupo]

**Última actualización**: 2025-06-10


- Terraform con 2 etapas
- Etapa 1: Recursos de red e infraestructura
- Etapa 2: Aplicaciones y servicios
- ECS, RDS, ALB, ECR en AWS

✅ **Base de Datos**
- MySQL 8.0
- Inicialización automática
- Volúmenes persistentes

✅ **Seguridad**
- .gitignore completo
- Variables de entorno
- Red interna Docker

---

## Inicio Rápido - Desarrollo Local

### Opción 1: Docker Compose (Recomendado)

```bash
# Copiar archivo de configuración de variables
cp .env.example .env

# Editar .env con tus valores
# DB_PASSWORD=tu_contraseña_segura
# DB_NAME=asistencia_db

# Levantar todos los servicios
docker-compose up --build

# La aplicación estará disponible en:
# - Frontend: http://localhost:3000
# - Backend Ventas: http://localhost:8080
# - Backend Despachos: http://localhost:8081
# - MySQL: localhost:3306
```

### Opción 2: Desarrollo Manual

```bash
# Backend Ventas
cd back-Ventas_SpringBoot/Springboot-API-REST
mvn clean package -DskipTests
java -jar target/ventas-api.jar

# Backend Despachos (otra terminal)
cd back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
mvn clean package -DskipTests
java -jar target/despachos-api.jar

# Frontend (otra terminal)
cd front_despacho
npm install
npm run dev
```

---

## Despliegue en AWS

Para desplegar la aplicación completa en AWS con infraestructura como código, consulta la guía detallada:

[DEPLOY_PASO_A_PASO.md](DEPLOY_PASO_A_PASO.md)

### Resumen del Proceso

1. Configurar AWS CLI: `aws configure`
2. Definir variables de entorno (credenciales, key pairs)
3. Terraform Init: `terraform init` en `infra/etapa_1`
4. Terraform Plan: `terraform plan` para revisar cambios
5. Terraform Apply: `terraform apply` para crear infraestructura
6. Docker Build & Push: Subir imágenes a Amazon ECR
7. Terraform Apply Etapa 2: Desplegar aplicaciones en ECS
8. Acceder a través del ALB (Application Load Balancer)

**Tiempo aproximado de despliegue:** 15-20 minutos

---

## Estructura del Proyecto

**Opción B: Estándar**
```bash
docker-compose up --build
```
✔ Configuración lista para usar

**Opción C: Producción con Nginx**
```bash
docker-compose -f docker-compose.pro.yml up --build
```
✔ Reverse proxy centralizado
✔ URLs unificadas

### 3️⃣ Verificar

```bash
# Ver contenedores activos
docker ps

# Backend Ventas
curl http://localhost:8080/swagger-ui.html

# Backend Despachos
curl http://localhost:8081/swagger-ui.html

# Frontend
open http://localhost:3000

# phpMyAdmin
open http://localhost:8888
# Usuario: root | Contraseña: example
```

---

## 📁 Estructura del Proyecto

```
Devops_Project/
├── back-Ventas_SpringBoot/
│   └── Springboot-API-REST/
│       ├── src/
│       ├── pom.xml
│       └── Dockerfile
├── back-Despachos_SpringBoot/
│   └── Springboot-API-REST-DESPACHO/
│       ├── src/
│       ├── pom.xml
│       └── Dockerfile
├── front_despacho/
│   ├── src/
│   ├── package.json
│   ├── Dockerfile
│   └── vite.config.js
├── infra/
│   ├── etapa_1/          # Terraform stage 1
│   │   └── *.tf
│   ├── etapa_2/          # Terraform stage 2
│   │   └── *.tf
│   └── mysql-init/
│       └── init.sql
├── .github/
│   └── workflows/
│       ├── ci-cd.yml     # Pipeline GitHub Actions
│       └── deploy-azure.yml
├── docker-compose.yml    # Estándar
├── docker-compose.dev.yml    # Desarrollo
├── docker-compose.pro.yml    # Producción
├── nginx.conf            # Reverse proxy config
├── DEPLOYMENT.md         # Guía de despliegue
├── BEST_PRACTICES.md     # Mejores prácticas
└── .gitignore           # Archivos a ignorar
```

---

## 🔧 Configuración

### Variables de Entorno

Crear `.env` en la raíz (NO commitar):
```env
# MySQL
MYSQL_ROOT_PASSWORD=example
MYSQL_DATABASE=ventas_db

# APIs
SPRING_DATASOURCE_URL=jdbc:mysql://db:3306/ventas_db
SPRING_DATASOURCE_USERNAME=root
SPRING_DATASOURCE_PASSWORD=example

# Frontend
VITE_VENTAS_API_URL=http://localhost:8080
VITE_DESPACHOS_API_URL=http://localhost:8081
```

### Puertos

| Servicio | Puerto | URL |
|----------|--------|-----|
| Ventas Backend | 8080 | http://localhost:8080 |
| Despacho Backend | 8081 | http://localhost:8081 |
| Frontend | 3000 | http://localhost:3000 |
| Nginx Gateway | 80 | http://localhost:80 |
| phpMyAdmin | 8888 | http://localhost:8888 |
| MySQL | 3306 | localhost:3306 |

---

## 🧪 Testing

### Tests Unitarios
```bash
# Ventas
cd back-Ventas_SpringBoot/Springboot-API-REST
mvn test

# Despachos
cd back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
mvn test

# Frontend
cd front_despacho
npm run test
```

### Tests de Integración
```bash
# Con contenedores corriendo
docker-compose -f docker-compose.dev.yml up

# Tests contra APIs
curl -X GET http://localhost:8080/api/ventas
curl -X GET http://localhost:8081/api/despachos
```

---

## 🚀 CI/CD con GitHub Actions

### Flujo Automático

```
Push a main/develop
    ↓
├─ Build Ventas Backend
├─ Build Despacho Backend
├─ Build Frontend
├─ Security Scan (Trivy)
├─ Integration Tests
└─ Code Quality (SonarCloud)
    ↓
Push Docker Images (main only)
    ↓
Deploy to Azure (main only)
```

### Secrets Necesarios
```
GITHUB_TOKEN              # Automático
AZURE_CREDENTIALS         # Para deploy
SONARCLOUD_TOKEN         # Code quality
```

---

## 📦 Docker

### Imágenes

- `ventas-backend:latest` - Spring Boot Ventas
- `despacho-backend:latest` - Spring Boot Despachos
- `despacho-frontend:latest` - React + Nginx
- `mysql:8.0` - Base de Datos
- `phpmyadmin:latest` - Gestor BD

### Build Manual
```bash
# Ventas
docker build -t ventas-backend:latest back-Ventas_SpringBoot/Springboot-API-REST

# Despachos
docker build -t despacho-backend:latest back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO

# Frontend
docker build -t despacho-frontend:latest front_despacho
```

---

## 🔐 Seguridad

⚠️ **En desarrollo:** OK usar credenciales simples

✅ **En producción, hacer:**
```
☐ Usar .env con secretos reales
☐ Configurar Azure Key Vault
☐ Usar usuario MySQL específico (no root)
☐ Activar SSL/TLS
☐ Agregar WAF (Web Application Firewall)
☐ Implementar rate limiting
☐ Auditoría de logs
```

---

## 🐛 Troubleshooting

| Problema | Solución |
|----------|----------|
| Frontend en blanco | `npm run build` y `docker build` |
| Backend no responde | Revisar logs: `docker logs ventas-backend` |
| Error conexión BD | Esperar 40s (start_period), revisar credenciales |
| Puerto ocupado | `netstat -ano` (Windows) o `lsof -i :8080` (Linux) |
| Healthcheck fallando | Revisar status: `docker ps` y `docker logs` |

---

## 📚 Documentación Adicional

- [DEPLOYMENT.md](./DEPLOYMENT.md) - Guía completa de despliegue
- [BEST_PRACTICES.md](./BEST_PRACTICES.md) - Mejores prácticas DevOps
- [.github/workflows/](./github/workflows/) - Configuración CI/CD

---

## 👤 Contacto & Soporte

Para issues o preguntas:
1. Revisar [BEST_PRACTICES.md](./BEST_PRACTICES.md)
2. Consultar logs: `docker logs <contenedor>`
3. Crear issue en GitHub

---

## 📄 Licencia

MIT

---

## 🎓 Nivel Académico

✅ Microservicios de producción
✅ DevOps completo
✅ CI/CD automático
✅ Infraestructura como código (Terraform)
✅ Best practices Docker
✅ Seguridad y monitoreo

**Nota:** Este proyecto cumple con estándares empresariales reales.
