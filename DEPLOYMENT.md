# 🚀 DEPLOYMENT GUIDE

## 📋 Opciones de Despliegue

### 1️⃣ **PRODUCCIÓN (Con Nginx Gateway)**
```bash
docker-compose -f docker-compose.pro.yml up --build
```

**Puertos:**
- Frontend + API Gateway: `http://localhost:80`
- phpMyAdmin: `http://localhost:8888`

**Ventajas:**
✔ Nginx como reverse proxy centralizado
✔ URLs unificadas `/api/ventas` y `/api/despachos`
✔ Production-ready

---

### 2️⃣ **DESARROLLO (Puertos Directos + Debug)**
```bash
docker-compose -f docker-compose.dev.yml up --build
```

**Puertos:**
- Ventas Backend: `http://localhost:8080`
- Despacho Backend: `http://localhost:8081`
- Frontend: `http://localhost:3000`
- phpMyAdmin: `http://localhost:8888`
- Debug Ventas: `localhost:5005`
- Debug Despacho: `localhost:5006`

**Ventajas:**
✔ Acceso directo a cada servicio
✔ Debug JDWP activado
✔ Ideal para desarrollo

---

### 3️⃣ **ESTÁNDAR (docker-compose.yml)**
```bash
docker-compose up --build
```

**Puertos:**
- Ventas Backend: `http://localhost:8080`
- Despacho Backend: `http://localhost:8081`
- Frontend: `http://localhost:3000`

---

## 🔧 Primeros Pasos

### Build inicial
```bash
# En cada backend Spring Boot
mvn clean package -DskipTests

# En frontend React
npm install && npm run build
```

### Verificar estado
```bash
# Ver todos los contenedores
docker ps

# Ver logs de un servicio
docker logs ventas-backend
docker logs despacho-backend
docker logs despacho-frontend

# Entrar a una BD
mysql -h localhost -u root -pexample ventas_db
```

---

## 🧪 TESTS RÁPIDOS

### APIs
```bash
# Ventas
curl http://localhost:8080/swagger-ui.html

# Despachos
curl http://localhost:8081/swagger-ui.html
```

### Base de Datos (phpMyAdmin)
```
http://localhost:8888
Usuario: root
Contraseña: example
```

---

## 🛑 Detener todo
```bash
docker-compose down
docker-compose -f docker-compose.pro.yml down
docker-compose -f docker-compose.dev.yml down
```

### Limpiar volúmenes (cuidado: borra BD)
```bash
docker-compose down -v
```

---

## 📊 Salud de los Servicios

Todos los servicios tienen healthchecks automáticos:
```bash
# Ver estado de healthchecks
docker ps --format "table {{.Names}}\t{{.Status}}"
```

---

## 🐛 Troubleshooting

### Frontend en blanco
→ Verificar que `npm run build` se ejecutó correctamente
→ Revisar logs: `docker logs despacho-frontend`

### Backend no responde
→ Revisar logs: `docker logs ventas-backend`
→ Verificar BD: `docker logs despacho-db`
→ Confirmar puerto en `application.properties`

### Conexión BD fallida
→ Esperar 40 segundos para que MySQL esté listo (start_period)
→ Verificar credenciales en `.env` o `docker-compose.yml`

### Puerto ocupado
```bash
# Liberar puerto (Windows)
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# Liberar puerto (Linux/Mac)
lsof -i :8080
kill -9 <PID>
```

---

## 🔐 Seguridad (ANTES de producción real)

⚠️ **NO uses en producción real:**
- `MYSQL_ROOT_PASSWORD: example`
- Credenciales hardcodeadas

✔ **Usa en producción:**
- Variables de entorno desde `.env` (en .gitignore)
- Azure Key Vault / AWS Secrets Manager
- Usuario MySQL específico (no root)
- SSL/TLS en todas las conexiones

---

## 📦 Archivos de Configuración

| Archivo | Propósito |
|---------|-----------|
| `docker-compose.yml` | Configuración estándar |
| `docker-compose.dev.yml` | Desarrollo con puertos directos |
| `docker-compose.pro.yml` | Producción con Nginx |
| `nginx.conf` | Configuración reverse proxy |
| `infra/mysql-init/init.sql` | Inicialización BD |

---

## 🎯 Resumen Nivel Academia ✅

✔ Microservicios aislados
✔ Healthchecks automáticos
✔ Reverse proxy Nginx (pro)
✔ phpMyAdmin para BD
✔ Múltiples configuraciones
✔ .gitignore correcto
✔ Variables de entorno
✔ Documentación clara
