# DevOps Project - Despachos & Ventas

Arquitectura de microservicios modernos con Docker, Spring Boot, React y MySQL. Listo para AWS/Azure con Terraform.

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                      Frontend (React/Vite)                  │
│                    http://localhost:3000                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
┌───────▼────────┐  ┌──────▼────────┐  ┌────▼───────────┐
│  Nginx Gateway │  │ Ventas API    │  │ Despacho API   │
│  (Reverse Proxy)  │ :8080         │  │ :8081          │
└─────────────────┘  └──────┬────────┘  └────┬───────────┘
                            │                 │
                      ┌─────▼─────────────────▼─────┐
                      │    MySQL Database           │
                      │    (ventas_db, despachos_db)│
                      └─────────────────────────────┘
```

---

## ✨ Características

✅ **Características**
- Backend Ventas (Spring Boot 3.x, Puerto 8080)
- Backend Despachos (Spring Boot 3.x, Puerto 8081)
- Frontend React (Vite, Nginx)

✅ **DevOps Ready**
- Docker Compose (desarrollo local)
- Healthchecks automáticos
- Nginx reverse proxy
- phpMyAdmin integrado
- Terraform IaC para AWS

✅ **CI/CD**
- GitHub Actions pipeline
- Build automático con Docker Buildx
- Tests automáticos
- Docker Registry (ECR)

✅ **Infraestructura como Código**
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
