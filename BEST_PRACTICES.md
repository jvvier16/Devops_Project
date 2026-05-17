# 🏆 MEJORES PRÁCTICAS DEVOPS - Guía Completa

## 📋 Índice

1. [Docker](#docker)
2. [Kubernetes (si lo necesitas)](#kubernetes)
3. [CI/CD](#cicd)
4. [Seguridad](#seguridad)
5. [Monitoreo](#monitoreo)
6. [Terraform](#terraform)
7. [Checklist Final](#checklist-final)

---

## 🐳 Docker

### ✅ Lo que estás haciendo bien

```yaml
✔ Multi-stage builds (Dockerfile)
✔ Imágenes Alpine (ligeras)
✔ Healthchecks implementados
✔ Redes internas (app-network)
✔ Volúmenes persistentes para BD
✔ Variables de entorno
```

### 🚀 Mejoras Implementadas

#### 1. Healthchecks (CRÍTICO)
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080/swagger-ui.html"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 40s
```

**Por qué importa:**
- Docker Compose espera a que esté listo antes de iniciar dependencias
- `start_period`: Permite al servicio tiempo para arrancar
- Evita errores de conexión por servicios no listos

#### 2. Restart Policies
```yaml
restart: unless-stopped
```

**Diferencia de policies:**
- `no`: No reinicia (default)
- `always`: Reinicia siempre (riesgoso en bucles)
- `unless-stopped`: Reinicia a menos que se paró manualmente ✅ (MEJOR)
- `on-failure`: Reinicia solo si falla

#### 3. Expose vs Ports
```yaml
# Interno (solo otros contenedores)
expose:
  - "8080"

# Externo (desde host)
ports:
  - "8080:8080"
```

**Para producción con Nginx:**
Usar `expose` en backends, `ports` solo en frontend + Nginx

### 📝 Dockerfile Óptimo - Spring Boot

```dockerfile
# ✅ Multi-stage
FROM maven:3.9.9-eclipse-temurin-17-alpine AS build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:resolve
COPY src ./src
RUN mvn -B -DskipTests package

# ✅ Runtime pequeño
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar

# ✅ Non-root user
RUN addgroup -S spring && adduser -S spring -G spring
USER spring

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 📝 Dockerfile Óptimo - Node.js

```dockerfile
# ✅ Build stage
FROM node:20-alpine AS builder
WORKDIR /build
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# ✅ Runtime stage
FROM nginx:alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /build/dist /usr/share/nginx/html
EXPOSE 80
```

---

## ☸️ Kubernetes (Si lo necesitas)

### Migrar de Docker Compose a K8s

**Herramientas:**
```bash
# Convertir docker-compose a K8s manifests
kompose convert -f docker-compose.yml -o k8s/

# O usar Helm para más control
helm create despacho-app
```

**Ejemplo deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ventas-backend
  labels:
    app: ventas-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: ventas-backend
  template:
    metadata:
      labels:
        app: ventas-backend
    spec:
      containers:
      - name: ventas-backend
        image: ghcr.io/yourorg/ventas-backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: url
        livenessProbe:
          httpGet:
            path: /swagger-ui.html
            port: 8080
          initialDelaySeconds: 40
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /swagger-ui.html
            port: 8080
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

---

## 🔄 CI/CD

### Pipeline Recomendado (Ya implementado)

```
Triggers:
├─ push to main/develop
├─ pull_request
└─ manual dispatch

Jobs paralelos:
├─ Build Ventas
├─ Build Despachos
├─ Build Frontend
├─ Security Scan
└─ Integration Tests

Post-build:
├─ Push Docker Registry
└─ Deploy (main only)
```

### GitHub Actions - Secrets Necesarios

1. **GITHUB_TOKEN** (Automático)
2. **AZURE_CREDENTIALS**
```json
{
  "clientId": "...",
  "clientSecret": "...",
  "subscriptionId": "...",
  "tenantId": "..."
}
```

3. **SONARCLOUD_TOKEN** (Opcional, code quality)

### Pre-commit Hooks (Prevenir commits malos)

Crear `.husky/pre-commit`:
```bash
#!/bin/sh
npm run lint
npm run build
```

Instalar:
```bash
npm install husky --save-dev
npx husky install
npx husky add .husky/pre-commit "npm run lint"
```

---

## 🔐 Seguridad

### 🚨 Lo que NO hacer en Producción

```yaml
❌ Credenciales en código
❌ docker-compose.yml con secretos
❌ MYSQL_ROOT_PASSWORD visible
❌ terraform.tfstate en repo
❌ Imágenes sin escanear CVEs
❌ Puertos 3306 abiertos al mundo
```

### ✅ Checklist Seguridad

#### 1. Secretos (OBLIGATORIO)
```bash
# Usar Azure Key Vault
az keyvault secret set \
  --vault-name despacho-kv \
  --name "db-password" \
  --value "$(openssl rand -base64 32)"

# Usar en docker-compose
docker run \
  -e DB_PASSWORD=$(az keyvault secret show --vault-name despacho-kv --name db-password --query value -o tsv) \
  myapp
```

#### 2. RBAC (Role-Based Access Control)
```bash
# Azure
az role assignment create \
  --assignee <app-id> \
  --role "Contributor" \
  --scope /subscriptions/<sub-id>/resourceGroups/despacho-rg

# Kubernetes
kubectl create serviceaccount app-user
kubectl create rolebinding app-role --clusterrole=view --serviceaccount=default:app-user
```

#### 3. Scanning de Vulnerabilidades
```bash
# Trivy (Automático en CI/CD)
trivy image ghcr.io/yourorg/ventas-backend:latest

# Snyk
snyk monitor --file=pom.xml

# GitHub Dependabot
# Automático si enabled en Settings → Code security
```

#### 4. Seguridad de Red
```yaml
# docker-compose.yml - Usar redes privadas
networks:
  app-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

# No expongas MySQL al exterior
db:
  # ❌ NO hacer esto
  # ports:
  #   - "3306:3306"
  
  # ✅ Hacer esto (interna)
  expose:
    - "3306"
```

#### 5. SSL/TLS (Https)
```nginx
# nginx.conf
server {
    listen 443 ssl http2;
    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    
    # A+
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
}
```

---

## 📊 Monitoreo

### Stack de Monitoreo (Recomendado)

```yaml
Prometheus:      # Métricas
Grafana:         # Visualización
ELK Stack:       # Logs
Jaeger:          # Tracing
AlertManager:    # Alertas
```

### Prometheus Config

```yaml
# prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'ventas-api'
    static_configs:
      - targets: ['ventas-backend:8080']
  
  - job_name: 'despacho-api'
    static_configs:
      - targets: ['despacho-backend:8081']
  
  - job_name: 'mysql'
    static_configs:
      - targets: ['db:3306']
```

### Métricas Spring Boot (Micrometer)

```xml
<!-- pom.xml -->
<dependency>
    <groupId>io.micrometer</groupId>
    <artifactId>micrometer-registry-prometheus</artifactId>
</dependency>

<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

```properties
# application.properties
management.endpoints.web.exposure.include=health,metrics,prometheus
management.endpoint.metrics.enabled=true
management.endpoint.prometheus.enabled=true
```

Acceder a:
```
http://localhost:8080/actuator/prometheus
```

### Logs Centralizados (ELK)

```yaml
# docker-compose.yml
elasticsearch:
  image: docker.elastic.co/elasticsearch/elasticsearch:8.0.0
  environment:
    - discovery.type=single-node
  ports:
    - "9200:9200"

kibana:
  image: docker.elastic.co/kibana/kibana:8.0.0
  ports:
    - "5601:5601"
```

---

## 🏗️ Terraform

### Estructura Recomendada

```
infra/
├── etapa_1/            # Networking, VPC, etc
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
├── etapa_2/            # Apps, BD, etc
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars
└── modules/            # Reutilizable
    ├── app_service
    ├── mysql
    └── networking
```

### Plan vs Apply

```bash
# SIEMPRE revisar primero
terraform plan -out=tfplan

# Luego aplicar
terraform apply tfplan

# Para destroy (cuidado)
terraform plan -destroy -out=tfplan_destroy
terraform apply tfplan_destroy
```

### Terraform State (CRÍTICO)

```bash
# Nunca en repo
echo "*.tfstate*" >> .gitignore

# Guardar en Azure
terraform {
  backend "azurerm" {
    resource_group_name  = "despacho-rg"
    storage_account_name = "despachotfstate"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### Ejemplo: App Service + MySQL

```hcl
# main.tf
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "despacho-rg"
  location = var.location
}

resource "azurerm_app_service" "main" {
  name                = "despacho-app"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  app_service_plan_id = azurerm_app_service_plan.main.id

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"      = "https://ghcr.io"
    "DOCKER_ENABLE_CI"                = "true"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
  }
}

resource "azurerm_mysql_server" "main" {
  name                = "despacho-mysql"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  sku_name   = "B_Gen5_1"
  storage_mb = 51200
  
  administrator_login          = var.db_admin
  administrator_login_password = var.db_password
  
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
}
```

---

## ✅ Checklist Final

### Antes de Producción

- [ ] Todos los tests pasan (`mvn test`, `npm test`)
- [ ] Docker builds sin errores
- [ ] Healthchecks configurados
- [ ] Variables de entorno en `.env` (gitignored)
- [ ] `terraform.tfstate` ignorado en git
- [ ] `.gitignore` completo
- [ ] CI/CD pipeline funciona
- [ ] Secrets en Azure Key Vault, no en código
- [ ] HTTPS habilitado
- [ ] Monitoreo configurado
- [ ] Logs centralizados
- [ ] Backup de BD automático
- [ ] Documentación actualizada
- [ ] Rate limiting en APIs
- [ ] CORS configurado correctamente

### Seguridad

- [ ] No hay credenciales en código
- [ ] MySQL user NO es root
- [ ] Puertos internos no expuestos
- [ ] WAF activo en producción
- [ ] Trivy scan sin CRITICAL
- [ ] Dependencias actualizadas

### Monitoreo

- [ ] Prometheus scraping metrics
- [ ] Grafana dashboards
- [ ] Alertas configuradas
- [ ] ELK recolectando logs
- [ ] SLA monitoreado

---

## 🚀 Pasos Siguientes (En Orden de Prioridad)

### Nivel 1 (Hoy)
```
✅ Docker optimizado
✅ CI/CD básico
✅ Healthchecks
```

### Nivel 2 (Esta semana)
```
☐ Secrets en Key Vault
☐ HTTPS con Let's Encrypt
☐ Monitoreo con Prometheus + Grafana
```

### Nivel 3 (Este mes)
```
☐ Kubernetes si necesitas scale
☐ Terraform completo para AWS/Azure
☐ Pipeline de Blue-Green Deployment
```

### Nivel 4 (Mantenimiento)
```
☐ Autoscaling
☐ Disaster Recovery
☐ DR testing mensual
```

---

## 📚 Referencias

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Spring Boot Production](https://spring.io/guides/gs/spring-boot/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Azure DevOps](https://azure.microsoft.com/en-us/products/devops/)
- [Terraform Azure](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

---

## 💡 Resumen en Una Línea

**Tu proyecto ahora es nivel academia/profesional. Lo falta es escalar, monitorear y asegurar en producción.**
