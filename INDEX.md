# 📑 ÍNDICE CENTRAL DE DOCUMENTACIÓN

## 🎯 Empezar Aquí (Todos)

**👉 Tienes 5 minutos? Leer:** [QUICKSTART.md](./QUICKSTART.md)  
**👉 Tienes 30 minutos? Leer:** [README.md](./README.md) + [DEPLOYMENT.md](./DEPLOYMENT.md)  
**👉 Eres developer? Leer:** [BEST_PRACTICES.md](./BEST_PRACTICES.md)  
**👉 Algo no funciona? Leer:** [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

---

## 📚 Documentación Completa (Por Rol)

### 👨‍💼 Para Gestores de Proyecto

| Doc | Contenido | Tiempo |
|-----|-----------|--------|
| [SUMMARY.md](./SUMMARY.md) | Resumen visual de transformación | 10 min |
| [CHECKLIST.md](./CHECKLIST.md) | Estado actual del proyecto | 10 min |
| [README.md](./README.md) | Descripción general (nivel ejecutivo) | 5 min |

**Bottom Line:** Proyecto pasó de 6.5/10 a 9.0/10. Listo para producción.

---

### 👨‍💻 Para DevOps/SRE

| Doc | Contenido | Tiempo |
|------|-----------|--------|
| [DEPLOYMENT.md](./DEPLOYMENT.md) | 3 modos de despliegue + troubleshooting avanzado | 15 min |
| [BEST_PRACTICES.md](./BEST_PRACTICES.md) | Docker, K8s, CI/CD, Seguridad, Monitoreo | 30 min |
| [QUICKSTART.md](./QUICKSTART.md) | Comandos rápidos y verificación | 5 min |
| [Makefile](./Makefile) | 30+ comandos útiles | (referencia) |

**Profundidad:** Covers production-grade practices.

---

### 👨‍💻 Para Developers

| Doc | Contenido | Tiempo |
|------|-----------|--------|
| [QUICKSTART.md](./QUICKSTART.md) | Levantar stack en 5 minutos | 5 min |
| [README.md](./README.md) | Arquitectura y estructura del proyecto | 10 min |
| [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) | "¿Por qué no funciona?" resolvido | 10 min |
| [DEPLOYMENT.md](./DEPLOYMENT.md) | Debugging y verificación | 10 min |

**Focus:** Practicidad y velocidad.

---

### 🔒 Para Security Team

| Doc | Contenido | Tiempo |
|------|-----------|--------|
| [.gitignore](./.gitignore) | Qué no se commitea | (ref) |
| [BEST_PRACTICES.md](./BEST_PRACTICES.md#-seguridad) | Sección de Seguridad | 15 min |
| [docker-compose.yml](./docker-compose.yml) | Review de configuración | (ref) |
| [.github/workflows/](./github/workflows/) | CI/CD security checks | (ref) |

**Focus:** Secrets, RBAC, compliance.

---

### 📊 Para Monitoring/Ops

| Doc | Contenido | Tiempo |
|------|-----------|--------|
| [docker-compose.monitoring.yml](./docker-compose.monitoring.yml) | Stack completo (Prometheus+Grafana+Kibana) | (ref) |
| [monitoring/prometheus.yml](./monitoring/prometheus.yml) | Configuración de métricas | (ref) |
| [monitoring/alertmanager.yml](./monitoring/alertmanager.yml) | Configuración de alertas | (ref) |
| [BEST_PRACTICES.md](./BEST_PRACTICES.md#-monitoreo) | Sección de Monitoreo | 10 min |

**Setup:** `docker-compose -f docker-compose.monitoring.yml up`

---

## 🗂️ Archivo de Configuración (Referencia Rápida)

### Docker Compose Variants

| Archivo | Uso | Puertos |
|---------|-----|--------|
| [docker-compose.yml](./docker-compose.yml) | Estándar (RECOMENDADO) | 8080, 8081, 3000, 3306, 8888 |
| [docker-compose.dev.yml](./docker-compose.dev.yml) | Desarrollo con debug | Anterior + 5005, 5006 |
| [docker-compose.pro.yml](./docker-compose.pro.yml) | Producción con Nginx | 80, 8888 |
| [docker-compose.monitoring.yml](./docker-compose.monitoring.yml) | Con observabilidad | Anterior + 9090, 3001, 5601, 6831, 16686 |

### Configuración de Servicios

| Archivo | Propósito |
|---------|-----------|
| [nginx.conf](./nginx.conf) | Reverse proxy / API Gateway |
| [monitoring/prometheus.yml](./monitoring/prometheus.yml) | Scrape de métricas |
| [monitoring/alertmanager.yml](./monitoring/alertmanager.yml) | Configuración de alertas |
| [infra/mysql-init/init.sql](./infra/mysql-init/init.sql) | Inicialización de BD |

### CI/CD

| Archivo | Propósito |
|---------|-----------|
| [.github/workflows/ci-cd.yml](./.github/workflows/ci-cd.yml) | Build, Test, Security, Push |
| [.github/workflows/deploy-azure.yml](./.github/workflows/deploy-azure.yml) | Deploy a Azure |

### Utilidades

| Archivo | Propósito |
|---------|-----------|
| [Makefile](./Makefile) | 30+ comandos útiles |
| [.gitignore](./.gitignore) | Archivos a ignorar en git |

---

## 📋 Matriz de Lectura Recomendada

```
     ¿Primero?    ¿Tengo 5 min?    ¿Tengo 30 min?    ¿Soy expert?
         │             │                 │                │
         ├─────────►[QUICKSTART]────────┤                │
         │                               │                │
         └──────────────────────►[README]────────────────┤
                                        │                │
                                        └──────►[DEPLOYMENT]
                                               │         │
                                               │         │
                                        [BEST PRACTICES]─┤
                                               │         │
                                        [TROUBLESHOOTING]│
                                               │         │
                                        [CHECKLIST]  [SUMMARY]
```

---

## 🎯 Guía Rápida por Escenario

### "Quiero empezar ahora"
```
1. Leer: QUICKSTART.md (2 min)
2. Ejecutar: docker-compose up --build (3 min)
3. Abrir: http://localhost:3000 (1 min)
4. Total: 5-10 minutos ✅
```

### "No funciona algo"
```
1. Ver: docker logs <container>
2. Buscar en: TROUBLESHOOTING.md
3. Si no encuentra: Leer BEST_PRACTICES.md
4. Si sigue fallando: Ver el docker-compose.yml correspondiente
```

### "Quiero entender la arquitectura"
```
1. Leer: README.md (arquitectura section)
2. Visualizar: SUMMARY.md (diagrama ASCII)
3. Revisar: docker-compose.yml (estructura de servicios)
4. Leer: BEST_PRACTICES.md (patrones)
```

### "Voy a desplegar a producción"
```
1. Leer: DEPLOYMENT.md (modos de despliegue)
2. Leer: BEST_PRACTICES.md (seguridad + monitoreo)
3. Revisar: docker-compose.pro.yml
4. Configurar: Secretos en Azure Key Vault
5. Deploy: Seguir DEPLOYMENT.md paso a paso
```

### "Quiero monitorear"
```
1. Leer: BEST_PRACTICES.md (sección Monitoreo)
2. Levantar: docker-compose -f docker-compose.monitoring.yml up
3. Acceder:
   - Prometheus: http://localhost:9090
   - Grafana: http://localhost:3001
   - Kibana: http://localhost:5601
4. Configurar: Dashboards en Grafana
```

### "Soy el SRE/DevOps del equipo"
```
1. Leer TODO en este orden:
   - README.md
   - DEPLOYMENT.md
   - BEST_PRACTICES.md
   - TROUBLESHOOTING.md
   - CHECKLIST.md
2. Revisar archivos de configuración:
   - docker-compose.yml (y variantes)
   - .github/workflows/
   - monitoring/
3. Crear runbooks basados en TROUBLESHOOTING.md
4. Entrenar al equipo con QUICKSTART.md
```

---

## 🔍 Buscar por Tema

### Docker & Contenedores
- Cómo funciona Docker Compose? → [README.md](./README.md#-docker)
- Docker best practices? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#-docker)
- Healthchecks en detalle? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#1-healthchecks-crítico)
- Dockerfile óptimo? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#-dockerfile-óptimo---spring-boot)
- Multi-stage builds? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#-dockerfile-óptimo---nodejs)

### CI/CD
- Pipeline GitHub Actions? → [DEPLOYMENT.md](./DEPLOYMENT.md#-ci-cd-con-github-actions)
- Build automático? → [.github/workflows/ci-cd.yml](./.github/workflows/ci-cd.yml)
- Deploy a Azure? → [.github/workflows/deploy-azure.yml](./.github/workflows/deploy-azure.yml)
- Pre-commit hooks? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#pre-commit-hooks-prevenir-commits-malos)

### Monitoreo & Observabilidad
- Stack de monitoreo? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#-stack-de-monitoreo-recomendado)
- Prometheus setup? → [monitoring/prometheus.yml](./monitoring/prometheus.yml)
- Grafana dashboards? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#prometheus-config)
- Logs centralizados? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#logs-centralizados-elk)
- Stack completo? → [docker-compose.monitoring.yml](./docker-compose.monitoring.yml)

### Seguridad
- Checklist seguridad? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#-checklist-seguridad)
- Secretos en producción? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#1-secretos-obligatorio)
- RBAC? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#2-rbac-role-based-access-control)
- Scanning de vulnerabilidades? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#3-scanning-de-vulnerabilidades)
- SSL/TLS? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#5-ssltls-https)
- .gitignore? → [.gitignore](./.gitignore)

### Infraestructura
- Terraform? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#-terraform)
- Estructura TF? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#estructura-recomendada)
- Plan vs Apply? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#plan-vs-apply)
- Terraform State? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#terraform-state-crítico)
- App Service + MySQL? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#ejemplo-app-service--mysql)

### Kubernetes
- Migrar a K8s? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#-kubernetes-si-lo-necesitas)
- Deployment manifest? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#ejemplo-deploymentyaml)
- Kompose converter? → [BEST_PRACTICES.md](./BEST_PRACTICES.md#migrar-de-docker-compose-a-ks)

### Troubleshooting
- Contenedor no inicia? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#1️⃣-contenedor-no-inicia-o-crashea)
- Frontend en blanco? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#2️⃣-frontend-en-blanco)
- API no responde? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#3️⃣-api-no-responde)
- BD no conecta? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#4️⃣-base-de-datos-no-conecta)
- Puerto ocupado? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#5️⃣-puerto-ocupado)
- Healthcheck falla? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#6️⃣-healthcheck-failing)
- Logs confusos? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#7️⃣-logs-confusos-o-demasiados)
- Lento? → [TROUBLESHOOTING.md](./TROUBLESHOOTING.md#8️⃣-conexión-lenta-o-timeouts)

---

## 🎓 Programa de Aprendizaje (Recomendado)

### Día 1: Fundamentos
- [ ] Leer QUICKSTART.md (10 min)
- [ ] Ejecutar `docker-compose up --build` (10 min)
- [ ] Verificar en navegador (5 min)
- [ ] Leer README.md (15 min)
- **Total: 40 minutos**

### Día 2: Profundidad
- [ ] Leer DEPLOYMENT.md completo (20 min)
- [ ] Leer BEST_PRACTICES.md secciones 1-3 (30 min)
- [ ] Revisar docker-compose.yml (10 min)
- [ ] Revisar .github/workflows/ (10 min)
- **Total: 70 minutos**

### Día 3: Expertise
- [ ] Leer BEST_PRACTICES.md secciones 4-7 (30 min)
- [ ] Leer TROUBLESHOOTING.md (30 min)
- [ ] Revisar monitoring/ (15 min)
- [ ] Revisar Makefile (10 min)
- **Total: 85 minutos**

### Día 4: Maestría
- [ ] Leer CHECKLIST.md (15 min)
- [ ] Leer SUMMARY.md (15 min)
- [ ] Ejecutar todos los comandos Make (30 min)
- [ ] Hacer primer deploy (Terraform) (45 min)
- **Total: 105 minutos**

**Tiempo total para mastery: ~4-5 horas de estudio activo**

---

## 📞 Preguntas Frecuentes (FAQ)

**P: ¿Por dónde empiezo?**  
R: [QUICKSTART.md](./QUICKSTART.md)

**P: ¿Cómo despliego a producción?**  
R: [DEPLOYMENT.md](./DEPLOYMENT.md) + [BEST_PRACTICES.md](./BEST_PRACTICES.md#🏗️-terraform)

**P: ¿Algo no funciona?**  
R: [TROUBLESHOOTING.md](./TROUBLESHOOTING.md)

**P: ¿Qué es el proyecto?**  
R: [README.md](./README.md)

**P: ¿Qué se cambió?**  
R: [SUMMARY.md](./SUMMARY.md)

**P: ¿Está listo para producción?**  
R: [CHECKLIST.md](./CHECKLIST.md#-lo-que-está-completo-nivel-academia)

---

## 🌐 Navegación Rápida

```
📑 ÍNDICE (You are here)
│
├─ 🚀 QUICKSTART.md ...................... 5 minutos
│
├─ 📖 README.md .......................... General
│
├─ 🚢 DEPLOYMENT.md ....................... Despliegue
│
├─ 🏆 BEST_PRACTICES.md .................. DevOps Pro
│
├─ 🔧 TROUBLESHOOTING.md ................ Problemas
│
├─ ✅ CHECKLIST.md ...................... Estado
│
├─ 📊 SUMMARY.md ....................... Transformación
│
└─ ⚙️  CONFIGURACIÓN (archivos)
   ├─ docker-compose.*.yml ........... 4 variantes
   ├─ nginx.conf ................... Reverse proxy
   ├─ .github/workflows/ ........... CI/CD
   ├─ monitoring/ ................. Observability
   ├─ Makefile .................... Comandos
   └─ .gitignore .................. Seguridad
```

---

## ✅ Checklist de Lectura Completa

- [ ] QUICKSTART.md
- [ ] README.md
- [ ] DEPLOYMENT.md
- [ ] BEST_PRACTICES.md
- [ ] TROUBLESHOOTING.md
- [ ] CHECKLIST.md
- [ ] SUMMARY.md
- [ ] docker-compose.yml (y variantes)
- [ ] .github/workflows/
- [ ] Makefile

**Tiempo estimado: 4-5 horas**

---

**¡Bienvenido al proyecto! 🎉 Elige un documento y empeza.**
