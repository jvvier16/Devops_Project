# Documento de Arquitectura - Sistema de Despachos en AWS EKS

**Proyecto:** DevOps - Sistema de Despachos y Ventas  
**Versión:** 1.0  
**Fecha:** 2025-06-10  
**Estado:** En Producción (AWS Academy)

---

## 1. Descripción General de la Arquitectura

### 1.1 Propósito

Este proyecto implementa un sistema de gestión de despachos y ventas con arquitectura de microservicios altamente disponible, escalable y automatizada. Se despliega en AWS EKS (Kubernetes administrado) con autoscaling, CI/CD automático y monitoreo.

### 1.2 Beneficios de la Arquitectura

| Beneficio | Descripción |
|-----------|------------|
| **Escalabilidad** | HPA escala automáticamente pods, ASG escala nodos |
| **Alta Disponibilidad** | 2+ replicas, balanceador de carga, DNS interno |
| **Automation** | CI/CD pipeline automático, deployments con zero-downtime |
| **Seguridad** | IAM roles, security groups, secrets management |
| **Observabilidad** | CloudWatch logs, métricas de pods, eventos de cluster |
| **Cost Efficiency** | Autoscaling reduce costos cuando no hay carga |

---

## 2. Componentes de la Arquitectura

### 2.1 Capas de la Solución

```
┌─────────────────────────────────────────────────────┐
│         PRESENTATION LAYER (Frontend)               │
│  React 18 + Vite + Nginx (Reverse Proxy)            │
│  - Interfaz responsive                              │
│  - Proxy de APIs                                    │
│  - SPA routing                                      │
└──────────────────┬──────────────────────────────────┘
                   │ HTTP/REST
┌──────────────────▼──────────────────────────────────┐
│    APPLICATION LAYER (Microservicios Backend)       │
│  ┌─────────────────────┐ ┌─────────────────────┐   │
│  │ Backend Despachos   │ │ Backend Ventas      │   │
│  │ Spring Boot 3.4.4   │ │ Spring Boot 3.4.4   │   │
│  │ - REST API (8081)   │ │ - REST API (8080)   │   │
│  │ - Actuator Health   │ │ - Actuator Health   │   │
│  │ - Swagger Docs      │ │ - Swagger Docs      │   │
│  └─────────────────────┘ └─────────────────────┘   │
└──────────────────┬──────────────────────────────────┘
                   │ JDBC/MySQL
┌──────────────────▼──────────────────────────────────┐
│    DATA LAYER (Persistencia)                        │
│  MySQL 8.0                                          │
│  - Base de datos relacional                         │
│  - PersistentVolume (EBS)                           │
│  - Backups automáticos                              │
└─────────────────────────────────────────────────────┘
```

### 2.2 Componentes Kubernetes

#### 2.2.1 Frontend Deployment

```yaml
Deployment Name: frontend-despacho
Replicas: 1-3 (HPA enabled)
Container: Nginx reverse proxy
Exposed: LoadBalancer service (puerto 80)
Resources: 
  - Request: 100m CPU, 128Mi Memory
  - Limit: 500m CPU, 512Mi Memory
```

**Funciones:**
- Sirve aplicación React compilada
- Proxy HTTP a backends
- Manejo de rutas SPA

#### 2.2.2 Backend Despacho Deployment

```yaml
Deployment Name: backend-despacho
Replicas: 2-5 (HPA enabled)
Container: Spring Boot 3.4.4
Exposed: ClusterIP service (puerto 8081)
Resources:
  - Request: 100m CPU, 256Mi Memory
  - Limit: 500m CPU, 1Gi Memory
Health Check: /actuator/health
```

**Funciones:**
- API REST para gestión de despachos
- Persistencia en MySQL
- Autenticación/Autorización
- Swagger documentation

#### 2.2.3 MySQL StatefulSet (opcional, puede ser RDS)

```yaml
StatefulSet Name: mysql
Replicas: 1
Container: MySQL 8.0
Storage: PersistentVolume (10Gi EBS)
Service: ClusterIP (puerto 3306, solo interno)
Environment:
  - MYSQL_DATABASE: despachos
  - MYSQL_ROOT_PASSWORD: root (cambiar en prod)
```

**Funciones:**
- Base de datos centralizada
- Volumen persistente para datos
- Health checks de conectividad

### 2.3 Servicios Kubernetes

| Servicio | Tipo | Propósito | Puertos |
|----------|------|----------|--------|
| frontend-despacho | LoadBalancer | Acceso público | 80:8080 |
| backend-despacho | ClusterIP | DNS interno | 8081:8081 |
| backend-ventas | ClusterIP | DNS interno | 8080:8080 |
| mysql | ClusterIP | DNS interno | 3306:3306 |

### 2.4 Autoscaling

#### 2.4.1 Horizontal Pod Autoscaler (HPA)

**Backend Despacho:**
- Min replicas: 2 (alta disponibilidad)
- Max replicas: 5 (control de costos)
- CPU threshold: 50%
- Memory threshold: 70%
- Scale-up: Inmediato (30s)
- Scale-down: Lento (300s = 5min)

**Justificación:**
- CPU 50%: Detecta carga rápidamente
- Scale-up rápido: Mejora experiencia usuario
- Scale-down lento: Evita oscilación

#### 2.4.2 Auto Scaling Group (EC2 Nodos)

**Configuración:**
- Min: 2 nodos (HA)
- Max: 4 nodos (costos)
- Desired: 2 nodos (baseline)
- Tipo: t3.medium (2 vCPU, 4Gi RAM)

**Escalado:**
- Se agregan nodos cuando HPA necesita crear pods pero no hay recursos
- Se eliminan nodos después de 10 min sin utilización

---

## 3. Componentes AWS

### 3.1 Compute (EKS)

**Cluster EKS:**
- Nombre: despachos-cluster
- Region: us-east-1
- Versión: 1.29
- Endpoint: Managed by AWS
- Master nodes: AWS-managed (sin costo)

**Worker Nodes:**
- Tipo: EC2 t3.medium (2 vCPU, 4Gi RAM)
- Cantidad: 2-4 (ASG)
- OS: Amazon Linux 2
- Container Runtime: containerd

**Node Group:**
- Nombre: despachos-nodes
- Subnets: Privadas 10.0.10.0/24, 10.0.11.0/24

### 3.2 Networking

**VPC (Virtual Private Cloud):**
- CIDR: 10.0.0.0/16
- Nombre: despachos-vpc

**Subnets:**
```
Públicas (Internet accesible):
  - Subnet-1: 10.0.1.0/24 (us-east-1a) - ALB
  - Subnet-2: 10.0.2.0/24 (us-east-1b) - ALB

Privadas (Solo cluster):
  - Subnet-3: 10.0.10.0/24 (us-east-1a) - Nodos
  - Subnet-4: 10.0.11.0/24 (us-east-1b) - Nodos
```

**Internet Gateway:**
- Nombre: despachos-igw
- Adjunto a VPC
- Permite tráfico 0.0.0.0/0 desde subnets públicas

**NAT Gateway:**
- En subnet pública
- Permite que subnets privadas accedan internet
- Importante para descargar imágenes

**Route Tables:**
```
Pública (Subnets 1,2):
  - 0.0.0.0/0 -> Internet Gateway
  - 10.0.0.0/16 -> local

Privada (Subnets 3,4):
  - 0.0.0.0/0 -> NAT Gateway
  - 10.0.0.0/16 -> local
```

### 3.3 Security Groups

**ALB Security Group:**
- Entrada: Puerto 80, 443 desde 0.0.0.0/0
- Salida: Todo permitido
- Propósito: Acepta tráfico de internet

**EKS Nodos Security Group:**
- Entrada:
  - Puerto 1025-65535 desde ALB SG (tráfico ALB)
  - Puerto 10250 desde Control Plane (kubelet)
- Salida: Todo permitido
- Propósito: Comunica con ALB y nodos

### 3.4 Application Load Balancer (ALB)

**Función:** Expone servicios Kubernetes al internet

**Configuración:**
- Tipo: Application Load Balancer (Layer 7)
- Subnets: Públicas (1,2)
- Security Group: ALB SG
- Target Group: 
  - Tipo: IP
  - Protocolo: HTTP
  - Puerto: 8080
  - Health Check: /

**DNS:**
- URL: `<ALB-ID>.elb.us-east-1.amazonaws.com`
- Redirige todo el tráfico al servicio frontend-despacho

### 3.5 Container Registry (ECR)

**Repositorios:**
```
- backend-despacho (URI: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/backend-despacho)
- frontend-despacho (URI: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/frontend-despacho)
```

**Política de imágenes:**
- Tagging: `latest`, `v1.0`, `SHA`
- Retention: Keep last 10 images
- Scan: Enabled (vulnerabilidades)

### 3.6 Identity & Access Management (IAM)

**EKS Service Role:**
- Nombre: EksServiceRole
- Políticas:
  - AmazonEKSServiceRolePolicy
  - AmazonEKSVPCResourceController
- Propósito: Permite que AWS cree/gestione cluster

**EKS Node Role:**
- Nombre: EksNodeRole
- Políticas:
  - AmazonEKSWorkerNodePolicy
  - AmazonEKS_CNI_Policy
  - AmazonEC2ContainerRegistryReadOnly
- Propósito: Permite que nodos accedan ECR, comuniquen con master

### 3.7 Monitoreo (CloudWatch)

**Logs:**
- Cluster logs habilitados
- Grupos de log: /aws/eks/despachos-cluster
- Retención: 7 días

**Métricas:**
- CPU, Memory, Network por nodo
- Dashboards por deployment
- Alertas por anomalías

---

## 4. Flujo de Datos

### 4.1 Request Frontend

```
User (Browser)
   │ HTTP GET /despachos
   ▼
ALB (Internet-facing)
   │ Forwarding rule: * -> Target Group
   ▼
Frontend Service (LoadBalancer)
   │ Port 80 -> ClusterIP 80
   ▼
Frontend Pod (Nginx)
   │ /api/despachos/* -> proxy_pass backend-despacho:8081
   ▼
Backend Service (ClusterIP)
   │ Port 8081 -> Pod 8081
   ▼
Backend Pod (Spring Boot)
   │ GET /despachos
   ▼
MySQL (via pool conexiones)
   │ SELECT * FROM despachos
   ▼
Response (JSON)
```

### 4.2 Request Backend a Backend

```
Frontend
   │ GET /api/ventas/
   ▼
Nginx proxy_pass backend-ventas:8080
   │ DNS lookup: backend-ventas (CoreDNS)
   │ IP: 10.0.x.x (ClusterIP)
   ▼
Backend Ventas Service
   │ Load balance entre replicas
   ▼
Backend Ventas Pod
   │ Response
```

### 4.3 Request Backend a MySQL

```
Backend Pod
   │ DataSource connection pool
   │ jdbc:mysql://mysql:3306/despachos
   ▼
CoreDNS
   │ Resolv mysql -> 10.0.x.x
   ▼
MySQL Service (ClusterIP)
   │ Port 3306
   ▼
MySQL Pod
   │ SELECT/INSERT/UPDATE/DELETE
   ▼
PersistentVolume (EBS)
   │ /var/lib/mysql
```

---

## 5. Flujo de Deployments

### 5.1 CI/CD Pipeline

```
Developer Push (develop branch)
   │
   ▼
GitHub Actions Triggered
   ├─▶ Checkout code
   ├─▶ Configure AWS CLI
   ├─▶ Login ECR
   ├─▶ Build Backend (docker buildx)
   ├─▶ Push Backend ECR
   ├─▶ Build Frontend (npm run build + docker build)
   ├─▶ Push Frontend ECR
   ├─▶ Update kubeconfig
   ├─▶ Apply manifests (kubectl apply)
   ├─▶ Update images (kubectl set image)
   ├─▶ Wait rollout (kubectl rollout status)
   ├─▶ Check services (kubectl get svc)
   └─▶ Get LB URL
        │
        └─▶ Frontend available: http://<LB-URL>
```

### 5.2 Rolling Deployment (Zero-downtime)

```
Deployment Trigger (kubectl set image):
   │
   ├─ Old pod 1 ──┐
   ├─ Old pod 2 ──┼─ Still serving traffic
   └─ Old pod 3 ──┘
   
   ▼ Inicia pod nuevo
   
   ├─ Old pod 1 ──┐
   ├─ Old pod 2 ──┼─ Serving traffic
   ├─ Old pod 3 ──┤
   └─ New pod 1 ──┘
   
   ▼ Termina pod viejo 1
   
   ├─ Old pod 2 ──┐
   ├─ Old pod 3 ──┼─ Serving traffic
   └─ New pod 1 ──┘
   
   ▼ Continúa...
   
   └─ New pod 1 ──┐
      New pod 2 ──┤ Todos los pods nuevos activos
      New pod 3 ──┘
```

---

## 6. Estrategia de Autoscaling

### 6.1 Métricas Monitoreadas

**Horizontal Pod Autoscaler:**
```
Métrica 1: CPU Utilization
  - Target: 50%
  - Si CPU > 50% → Aumenta replicas
  - Si CPU < 50% por 5 min → Reduce replicas

Métrica 2: Memory Utilization
  - Target: 70%
  - Si Memory > 70% → Aumenta replicas
  - Si Memory < 70% por 5 min → Reduce replicas
```

**Auto Scaling Group (Nodos EC2):**
```
Métrica: Pending Pods
  - Si HPA crea pods pero no hay recursos → Agrega nodo
  - Si nodo utilizado < 10% por 10 min → Elimina nodo
```

### 6.2 Escenarios de Escalado

**Escenario 1: Pico de tráfico**
```
Hora: 10:00
Usuarios: 100
Pods Backend: 2 → CPU 45%

Hora: 10:05
Usuarios: 500
Pods Backend: 2 → CPU 85%

Hora: 10:06
HPA detecta CPU > 50%
Pods Backend: 2 → 4 (duplica)

Hora: 10:07
Usuarios: 500
Pods Backend: 4 → CPU 50% (target alcanzado)
Respuesta mejorada, usuarios felices
```

**Escenario 2: Baja demanda**
```
Hora: 22:00
Usuarios: 50
Pods Backend: 4 → CPU 15%

Hora: 22:05
HPA detecta CPU < 50% por 5 min
Pods Backend: 4 → 3 (reduce)

Hora: 22:10
Pods Backend: 3 → 2 (min alcanzado)
Costo reducido sin perder disponibilidad
```

---

## 7. Justificación de Decisiones

### 7.1 ¿Por qué EKS en lugar de EC2?

| Aspecto | EKS | EC2 |
|--------|-----|-----|
| **Gestión** | Administrado AWS | Manual |
| **Updates** | Automáticos | Manual |
| **Scaling** | HPA + ASG | Manual scripting |
| **HA** | Multi-AZ built-in | Requiere config |
| **Costo** | $0.10/hora cluster | Solo instancias |

**Decisión:** EKS es mejor para producción.

### 7.2 ¿Por qué HPA con CPU 50%?

**Alternativas:**
- 70% CPU → Reacciona lento a picos
- 30% CPU → Sobreescala, costo alto
- 50% CPU → Balance medio, 10-20 seg respuesta a picos

### 7.3 ¿Por qué 2 replicas mínimo?

**Motivos:**
- 1 replica: Si pod falla, no hay servicio
- 2 replicas: Redundancia, tolera 1 fallo
- 3 replicas: Overhead de costo sin beneficio

### 7.4 ¿Por qué LoadBalancer para frontend?

**Alternativas:**
- ClusterIP: Solo acceso interno (no viable)
- NodePort: Expone puerto alto (3xxxx)
- LoadBalancer: ALB expone puerto 80 (estándar)

### 7.5 ¿Por qué ClusterIP para backends?

**Motivos:**
- Solo necesitan DNS interno
- Frontend los accede por hostname (backend-despacho)
- No necesitan IP pública

---

## 8. Consideraciones de Seguridad

### 8.1 Red

- **Nodos en subnets privadas**: No accesibles desde internet
- **ALB en subnets públicas**: Único punto de entrada
- **Security Groups**: Restricción de puertos
- **Network Policies**: Control de tráfico pod-to-pod

### 8.2 Identidad

- **IAM Roles**: Control granular de permisos
- **Service Accounts**: Autenticación pod-to-AWS
- **RBAC**: Control de acceso a Kubernetes API

### 8.3 Datos

- **Secrets K8s**: Credenciales encriptadas
- **PersistentVolume**: EBS con encriptación
- **Backups**: RDS automated backups (si usamos RDS)

### 8.4 Imágenes

- **ECR Scanning**: Detecta vulnerabilidades
- **Admission Controllers**: Bloquea imágenes no permitidas
- **Image Pull Secrets**: Autenticación privada

---

## 9. Métricas y Alertas

### 9.1 Métricas de Cluster

```
Nodos:
  - Estado (Ready/NotReady)
  - CPU disponible
  - Memory disponible
  - Disk disponible

Pods:
  - Replicas deseadas vs actuales
  - Estado (Running/Pending/Failed)
  - CPU/Memory usage
  - Restart count

Services:
  - Endpoints activos
  - Tráfico entrante
  - Latencia
  - Errores (5xx)
```

### 9.2 Alertas Recomendadas

```
Critical:
  - Nodo no ready → Investigar
  - Pod crash loop → Debug
  - Base de datos no disponible → Page SRE
  
Warning:
  - CPU > 80% → Investigar
  - Memory > 85% → Investigar
  - HPA max replicas alcanzado → Escalar nodos
  
Info:
  - HPA scaling event → Log
  - Deployment rollout → Log
  - Node added/removed → Log
```

---

## 10. Disaster Recovery

### 10.1 Backups

```
MySQL Data:
  - EBS snapshots cada 6 horas
  - Retención: 30 días
  - Costo: ~$0.50/snapshot

Configuración:
  - Git backups (todos los manifiestos)
  - ECR image retention: 10+ images
```

### 10.2 Recovery Plan

```
Escenario: Pod MySQL se corrompe
  1. Detectar: Error en logs, queries fallan
  2. Analizar: Ver si es pod o dato
  3. Recuperar:
     - Opción 1: Usar snapshot EBS
     - Opción 2: Restore desde backup RDS (si disponible)
     - Opción 3: Rebuild desde migración

Escenario: Cluster completamente muere
  1. Crear nuevo cluster EKS
  2. Restaurar base de datos desde snapshot
  3. Re-deploypppppppppear manifiestos (kubectl apply -f)
  4. Pull imágenes de ECR
  5. Verificar salud
  Tiempo estimado: 20-30 minutos
```

---

## 11. Roadmap Futuro

### 11.1 Mejoras Próximas

- [ ] Usar AWS RDS para MySQL (en lugar de pod)
- [ ] Agregar Redis para caching
- [ ] Implementar API Gateway
- [ ] Service Mesh (Istio)
- [ ] Multi-region deployment
- [ ] Blue-Green deployment strategy

### 11.2 Monitoreo Avanzado

- [ ] Prometheus + Grafana
- [ ] ELK Stack (logs centralizados)
- [ ] Jaeger (distributed tracing)
- [ ] Custom metrics

### 11.3 Seguridad

- [ ] OAuth2 / OIDC
- [ ] Vault para secrets
- [ ] Pod Security Policies
- [ ] Network Policies avanzadas

---

## 12. Apéndices

### A. Comandos Clave

```bash
# Ver arquitectura actual
kubectl get all

# Ver recursos por nodo
kubectl describe nodes

# Ver métricas
kubectl top nodes
kubectl top pods

# Ver logs
kubectl logs -f deployment/backend-despacho

# Ver eventos
kubectl get events --sort-by='.lastTimestamp'
```

### B. Archivos de Configuración

- `infra/k8s/backend.yml` - Deployment backend
- `infra/k8s/frontend.yml` - Deployment frontend + LoadBalancer
- `infra/k8s/mysql.yml` - MySQL deployment
- `infra/k8s/hpa.yml` - Horizontal Pod Autoscaler
- `.github/workflows/ci.yml` - CI/CD Pipeline

### C. Contactos

- Documentación: README.md
- Troubleshooting: docs/TROUBLESHOOTING.md
- Issues: GitHub Issues

---

**Última Actualización:** 2025-06-10

