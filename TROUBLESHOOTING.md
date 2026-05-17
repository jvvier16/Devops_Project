# 🔧 TROUBLESHOOTING - Guía de Problemas y Soluciones

## 🎯 Búsqueda Rápida por Síntoma

```
Contenedor no inicia → #1
Frontend en blanco → #2
API no responde → #3
BD no conecta → #4
Puerto ocupado → #5
Healthcheck falla → #6
Logs confusos → #7
Conexión lenta → #8
```

---

## 1️⃣ CONTENEDOR NO INICIA O CRASHEA

### Síntoma
```
ERROR: Container exited with code 1
Status: Exited (1)
```

### Soluciones

**A) Ver qué salió mal**
```bash
docker logs <nombre-contenedor> --tail 50

# Ejemplos:
docker logs ventas-backend --tail 50
docker logs despacho-backend --tail 50
docker logs despacho-db --tail 50
```

**B) Errores comunes por servicio**

#### Backend Ventas/Despacho crashea
```bash
# Error típico: "error executing DDL"
# Causa: BD no está lista o schema incompatible

Solución 1: Esperar más tiempo
- El container espera 40 segundos por startup_period
- Algunos sistemas necesitan 60-90 segundos

Solución 2: Destruir volumen y reintentar
docker-compose down -v
docker-compose up --build

Solución 3: Revisar properties
- Verificar application.properties
- Confirmar SPRING_DATASOURCE_URL correcta
```

#### Base de datos no inicia
```bash
# Ver logs
docker logs despacho-db

# Error típico: "error initializing InnoDB"
Causa: Corrupción de volumen

Solución:
docker volume ls
docker volume rm <nombre_db_data>
docker-compose down -v
docker-compose up --build
```

#### Frontend no inicia
```bash
# Error típico: npm ERR!
Causa: package-lock.json inconsistente

Solución:
docker-compose down
rm -rf front_despacho/node_modules
npm install
npm run build
docker-compose up --build
```

**C) Ver recursos**
```bash
# ¿Poco RAM?
docker stats

# Si algún contenedor usa >512MB:
# Aumentar límites en docker-compose.yml
resources:
  limits:
    memory: 1G
    cpus: '1'
```

---

## 2️⃣ FRONTEND EN BLANCO

### Síntoma
```
Navegas a http://localhost:3000
Ves página en blanco
```

### Soluciones

**A) Paso 1: Verificar build**
```bash
# En front_despacho/
npm run build

# Debe crear carpeta dist/ con archivos
ls -la dist/
```

**B) Paso 2: Revisar logs**
```bash
docker logs despacho-frontend

# Error típico: 
# "VITE_VENTAS_API_URL is undefined"
```

**C) Paso 3: Variables de entorno**
```dockerfile
# Verify Dockerfile tiene esto:
ARG VITE_VENTAS_API_URL
ARG VITE_DESPACHOS_API_URL
ENV VITE_VENTAS_API_URL=${VITE_VENTAS_API_URL}
ENV VITE_DESPACHOS_API_URL=${VITE_DESPACHOS_API_URL}

# Y docker-compose.yml:
build:
  args:
    VITE_VENTAS_API_URL: http://localhost:8080
    VITE_DESPACHOS_API_URL: http://localhost:8081
```

**D) Paso 4: Consola del navegador**
```javascript
// Abre F12 → Console
// Verifica:
console.log(import.meta.env.VITE_VENTAS_API_URL)
// Debe mostrar: http://localhost:8080
```

**E) Verificar nginx.conf**
```nginx
# En front_despacho/nginx.conf debe tener:
server {
    listen 80;
    location / {
        root /usr/share/nginx/html;
        try_files $uri /index.html;
    }
}
```

**F) Última solución: Rebuild limpio**
```bash
docker-compose down
docker system prune -f
npm --prefix front_despacho ci
npm --prefix front_despacho run build
docker-compose up --build
```

---

## 3️⃣ API NO RESPONDE

### Síntoma
```
curl: (7) Failed to connect to localhost port 8080: Connection refused
O
curl: (52) Empty reply from server
```

### Soluciones

**A) Verificar container running**
```bash
docker ps | grep backend

# Debe salir algo como:
# ventas-backend    java ...    Up 2 minutes    0.0.0.0:8080->8080/tcp
```

**B) Ver logs**
```bash
docker logs ventas-backend -f

# Esperar a ver algo como:
# Tomcat started on port 8080
# Started SpringbootApiRestDespachoApplication in X seconds
```

**C) Esperar al healthcheck**
```bash
# El healthcheck espera 40 segundos
# Antes de eso, APIs puede no estar lista

docker ps --format "table {{.Names}}\t{{.Status}}"

# Buscar:
# ventas-backend    Up 45 seconds (healthy)
```

**D) Problema: Puerto correcto?**
```bash
# Verificar application.properties

# back-Ventas/application.properties:
server.port=8080

# back-Despachos/application.properties:
server.port=8081
```

**E) Error 503 Service Unavailable**
```bash
# Causa típica: BD no está conectando
docker logs ventas-backend | grep -i "connection\|unable\|failed"

# Solución:
# Esperar más (BD tarda en estar lista)
# Revisar: docker logs despacho-db
```

**F) Curl test correcto**
```bash
# Esperar 60+ segundos después de up
docker-compose up --build
sleep 60

# Luego test
curl http://localhost:8080/swagger-ui.html
curl http://localhost:8081/swagger-ui.html
```

---

## 4️⃣ BASE DE DATOS NO CONECTA

### Síntoma
```
error: Access denied for user 'root'@'172.20.0.2' (using password: YES)
unable to connect to database
Connection timeout
```

### Soluciones

**A) BD está corriendo?**
```bash
docker ps | grep despacho-db

# Si no aparece: está down
# Revisar logs:
docker logs despacho-db
```

**B) Credenciales correctas**
```yaml
# En docker-compose.yml:
environment:
  MYSQL_ROOT_PASSWORD: example
  MYSQL_DATABASE: ventas_db

# Backends deben usar:
SPRING_DATASOURCE_USERNAME: root
SPRING_DATASOURCE_PASSWORD: example
```

**C) Network connectivity**
```bash
# Ver si pueden comunicarse
docker exec ventas-backend ping db

# Debe responder
# Si no: problema de red

Solución:
docker-compose down
docker network rm app-network
docker-compose up --build
```

**D) Base de datos no creada**
```bash
# Ver bases existentes
docker exec despacho-db mysql -u root -pexample -e "SHOW DATABASES;"

# Debe mostrar: ventas_db, despachos_db
# Si no: init.sql no ejecutó

Solución:
docker-compose down -v
cat infra/mysql-init/init.sql
# Verificar que tiene CREATE DATABASE ventas_db, despachos_db
docker-compose up --build
```

**E) Port mapping correcto**
```yaml
# docker-compose.yml:
db:
  ports:
    - "3306:3306"  # Solo para desarrollo!

# Pero internamente:
SPRING_DATASOURCE_URL: jdbc:mysql://db:3306/...
# Usa nombre de servicio "db", NO localhost
```

**F) Test directo**
```bash
# Entrar a MySQL desde host
mysql -h 127.0.0.1 -u root -pexample

# Desde otro contenedor
docker exec ventas-backend bash
mysql -h db -u root -pexample
```

---

## 5️⃣ PUERTO OCUPADO

### Síntoma
```
ERROR: for despacho-frontend: ports are not available
Error response from daemon: Ports are not available
Address already in use
```

### Soluciones

**A) Windows - Encontrar proceso**
```bash
netstat -ano | findstr :8080
# Output: TCP    0.0.0.0:8080    0.0.0.0:0    LISTENING    12345

taskkill /PID 12345 /F
```

**B) Linux/Mac - Encontrar proceso**
```bash
lsof -i :8080
# Output: COMMAND   PID   USER    FD  TYPE DEVICE SIZE/OFF NODE NAME
#         chrome  12345  user   123u  IPv6 ...      ...

kill -9 12345
```

**C) Cambiar puerto temporalmente**
```yaml
# docker-compose.yml
services:
  ventas-backend:
    ports:
      - "8090:8080"  # Usar 8090 en lugar de 8080
```

**D) Docker mismo usa puerto**
```bash
docker ps
docker stop <container-usando-puerto>

# O si es otro compose:
docker-compose -f <otro-compose>.yml down
```

**E) Detener todo Docker**
```bash
docker-compose down
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.pro.yml down
docker-compose -f docker-compose.monitoring.yml down
```

---

## 6️⃣ HEALTHCHECK FAILING

### Síntoma
```
unhealthy (exitCode: 7, timeout: true)
health: starting
health: unhealthy
```

### Soluciones

**A) Entender healthcheck**
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8080"]
  interval: 30s       # Cada 30 segundos
  timeout: 10s        # Espera máx 10s
  retries: 5          # Falla tras 5 intentos fallidos
  start_period: 40s   # Ignora fallos los primeros 40s
```

**B) Problema: Timeout**
```bash
# El servicio tarda >10 segundos en responder
# Solución: Aumentar timeout

healthcheck:
  timeout: 30s        # De 10s a 30s
```

**C) Problema: start_period corto**
```bash
# El servicio necesita >40 segundos para arrancar
# Solución: Aumentar start_period

healthcheck:
  start_period: 60s   # De 40s a 60s
```

**D) Verificar manualmente**
```bash
# Esperar 60 segundos, luego:
docker exec ventas-backend curl -f http://localhost:8080/swagger-ui.html

# Si funciona: healthcheck está configurado mal
# Si no funciona: API realmente no responde
```

**E) Test en vivo**
```bash
docker-compose logs despacho-db
# Buscar: ready for connections

docker-compose logs ventas-backend
# Buscar: Tomcat started on port
```

---

## 7️⃣ LOGS CONFUSOS O DEMASIADOS

### Soluciones

**A) Ver logs de un servicio**
```bash
docker logs ventas-backend

# Últimas 100 líneas:
docker logs ventas-backend --tail 100

# En vivo (con -f):
docker logs -f ventas-backend

# Con timestamps:
docker logs -t ventas-backend
```

**B) Filtrar errores**
```bash
docker logs ventas-backend 2>&1 | grep -i error
docker logs ventas-backend 2>&1 | grep -i exception
docker logs ventas-backend 2>&1 | grep -i failed
```

**C) Ver todos los logs a la vez**
```bash
docker-compose logs

# O en vivo:
docker-compose logs -f
```

**D) Reducir verbosidad en application.properties**
```properties
logging.level.root=WARN
logging.level.com.citt=DEBUG
logging.level.org.springframework.web=WARN
```

**E) Exportar logs a archivo**
```bash
docker logs ventas-backend > ventas-backup.log
docker logs despacho-backend > despacho-backup.log
docker logs despacho-db > database-backup.log
```

---

## 8️⃣ CONEXIÓN LENTA O TIMEOUTS

### Síntoma
```
timeout after 30s waiting for ...
Connection timeout
Request timeout
```

### Soluciones

**A) CPU/RAM insuficientes**
```bash
docker stats

# Si ves >90% CPU o RAM:
Cerrar otros programas
Aumentar recursos Docker (Settings)
```

**B) Red saturada**
```bash
docker network ls
docker network inspect app-network

# Verificar driver: debe ser bridge
```

**C) DB lenta**
```bash
docker exec despacho-db mysql -u root -pexample -e "SELECT @@max_connections, @@wait_timeout;"

# Aumentar en docker-compose.yml:
command: --max_connections=500 --wait_timeout=28800
```

**D) Spring Boot timeout**
```properties
# application.properties
spring.datasource.hikari.maximum-pool-size=20
spring.datasource.hikari.minimum-idle=5
spring.datasource.hikari.connection-timeout=20000
```

**E) Nginx timeout**
```nginx
# nginx.conf
proxy_connect_timeout 60s;
proxy_send_timeout    60s;
proxy_read_timeout    60s;
```

---

## 🆘 ÚLTIMA OPCIÓN: Reset Completo

Si nada funciona:

```bash
# 1. Detener todo
docker-compose down
docker-compose -f docker-compose.dev.yml down
docker-compose -f docker-compose.pro.yml down

# 2. Limpiar
docker system prune -a -f
docker volume prune -f
docker network prune -f

# 3. Rebuild
docker-compose build --no-cache

# 4. Levantar
docker-compose up

# 5. Esperar 90 segundos
sleep 90

# 6. Verificar
docker ps
curl http://localhost:8080
curl http://localhost:3000
```

---

## 📞 SI AÚN NO FUNCIONA

**Recopila información:**
```bash
# 1. Versiones
docker --version
docker-compose --version
java -version
node --version

# 2. Logs completos
docker logs ventas-backend > ventas.log
docker logs despacho-backend > despacho.log
docker logs despacho-db > db.log

# 3. Estado
docker ps --all > docker-status.log
docker network inspect app-network > network.log

# 4. Comparte estos logs en tu reporte
```

---

## ✅ VERIFICACIÓN FINAL

Cuando todo funcione:

```bash
# Check 1: Contenedores
docker ps
# Todos deben estar "Up" y "healthy"

# Check 2: APIs
curl http://localhost:8080/swagger-ui.html
curl http://localhost:8081/swagger-ui.html
# Deben retornar 200 OK

# Check 3: Frontend
open http://localhost:3000
# No debe estar en blanco

# Check 4: BD
mysql -h 127.0.0.1 -u root -pexample -e "USE ventas_db; SHOW TABLES;"
# Debe mostrar tablas de la aplicación

# Check 5: phpMyAdmin
open http://localhost:8888
# Debe cargar interfaz
```

**Si todo esto funciona: ¡ÉXITO! 🎉**
