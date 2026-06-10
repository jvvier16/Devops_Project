# Guía de Test de Autoscaling y Validación

## 1. Configurar Ambiente de Test

### 1.1 Prerequisitos

```bash
# Verificar acceso a cluster
kubectl get nodes

# Verificar HPA instalado
kubectl get hpa

# Verificar Metrics Server
kubectl get deployment -n kube-system metrics-server

# Si no existe Metrics Server, instalar:
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Esperar a que esté ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/metrics-server -n kube-system
```

### 1.2 Verificar Configuración de HPA

```bash
# Listar HPAs
kubectl get hpa

# Ver detalles de HPA
kubectl describe hpa backend-despacho-hpa

# Resultado esperado:
# Name:                                            backend-despacho-hpa
# Namespace:                                       default
# Labels:                                          <none>
# Annotations:                                     <none>
# CreationTimestamp:                               Mon, 10 Jun 2025 14:30:00 +0000
# Reference:                                       Deployment/backend-despacho
# Metrics:                                         ( current / target )
#   resource cpu on pods  ( 20m / 50% ):           40%
#   resource memory on pods  ( 128Mi / 70% ):      18%
# Min replicas:                                    2
# Max replicas:                                    5
# Deployment pods:                                 2 current / 2 desired
# Conditions:
#   Type            Status  Reason              Message
#   ----            ------  ------              -------
#   AbleToScale     True    DesiredWithinRange  the desired count is within the acceptable range
#   ScalingActive   True    ValidMetricsFound   the HPA was able to compute the desired number of replicas
#   ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
# Events:           <none>
```

---

## 2. Test 1: Validar Recolección de Métricas

### Objetivo

Verificar que Metrics Server está recolectando métricas de CPU/Memory correctamente.

### Procedimiento

```bash
# Terminal 1: Ver métricas de nodos
watch kubectl top nodes

# Terminal 2: Ver métricas de pods
watch kubectl top pods

# Terminal 3: Ver estado de HPA
watch kubectl get hpa

# Esperado después de 1-2 minutos:
# NAME                          CPU(cores)   MEMORY(Mi)
# ip-10-0-10-100.ec2.internal   150m         512Mi
# ip-10-0-11-100.ec2.internal   80m          256Mi

# y

# NAME                        REFERENCE                         TARGETS            MINPODS   MAXPODS   REPLICAS   AGE
# backend-despacho-hpa        Deployment/backend-despacho       20%/50%, 18%/70%   2         5         2          5m
```

### Validación

✅ Si muestra valores de CPU/Memory → **Metrics recolectando correctamente**  
❌ Si muestra `<unknown>` → Ver [Troubleshooting: HPA muestra "unknown"](TROUBLESHOOTING.md)

---

## 3. Test 2: Validar Escalado Ascendente (Scale Up)

### Objetivo

Generar carga que suba CPU por encima de 50% y verificar que HPA escala.

### Procedimiento

```bash
# Terminal 1: Monitor HPA y pods (actualización cada 2 segundos)
watch -n 2 'kubectl get hpa,deployment backend-despacho'

# Terminal 2: Monitor de recursos
watch -n 2 'kubectl top pods -l app=backend-despacho'

# Terminal 3: Generar carga de prueba

# Opción A: Usar generador de carga simple
kubectl run -it --rm load-generator \
  --image=busybox:1.28 \
  --restart=Never \
  -- /bin/bash

# Dentro del pod load-generator:
# for i in {1..1000}; do \
#   wget -q -O- http://backend-despacho:8081/actuator/health & \
# done; wait

# Opción B: Usar Apache Bench (ab) si disponible
# kubectl run -it --rm load-generator \
#   --image=httpd \
#   --restart=Never \
#   -- ab -n 10000 -c 50 http://backend-despacho:8081/actuator/health

# Opción C: Script Python en pod
kubectl run -it --rm load-generator \
  --image=python:3.9-slim \
  --restart=Never \
  -- python3 << 'EOF'
import urllib.request
import threading
import time

url = 'http://backend-despacho:8081/actuator/health'
duration = 120  # segundos
num_threads = 20

def make_requests():
    end_time = time.time() + duration
    while time.time() < end_time:
        try:
            urllib.request.urlopen(url, timeout=2)
        except:
            pass

threads = []
for _ in range(num_threads):
    t = threading.Thread(target=make_requests)
    t.start()
    threads.append(t)

for t in threads:
    t.join()
print("Load test completed")
EOF
```

### Monitoreo

```bash
# Observar cambios en tiempo real:

# Minuto 0: Estado inicial
# backend-despacho         2/2         2           2
# CPU: 15%

# Minuto 1: Carga genera CPU > 50%
# CPU sube: 45% → 55% → 65%

# Minuto 2: HPA detecta CPU > 50%
# backend-despacho         2/4         4           4  (replicas aumentan!)

# Minuto 3: Nuevos pods initialized
# backend-despacho         4/4         4           4

# Minuto 4: Carga distribuida, CPU normaliza
# CPU: 50%

# Después: Fin de carga
# CPU comienza a bajar
```

### Validación

✅ **Scale-up exitoso si:**
- Replicas aumentan de 2 a más de 2
- Nuevos pods pasan a "Running" dentro de 1-2 minutos
- CPU se estabiliza alrededor de 50%

❌ **Si no escala:**
- Ver eventos: `kubectl describe hpa backend-despacho-hpa`
- Ver logs metrics-server: `kubectl logs -n kube-system deployment/metrics-server`
- Ver si hay recursos disponibles: `kubectl describe nodes`

---

## 4. Test 3: Validar Escalado Descendente (Scale Down)

### Objetivo

Verificar que HPA reduce replicas cuando la carga baja.

### Procedimiento

```bash
# Nota: Este test requiere tiempo (5+ minutos)

# Terminal 1: Monitor el escalado (actualización cada 30 segundos)
watch -n 30 'kubectl get hpa,deployment backend-despacho'

# Terminal 2: Generar carga (como en Test 2)
kubectl run -it --rm load-generator --image=busybox --restart=Never \
  -- wget -q -O- http://backend-despacho:8081/actuator/health

# Esperar ~60 segundos mientras se genera carga

# Terminal 3: Detener la carga
# (Presionar Ctrl+C en Terminal 2 o esperar a que termine)

# Observar:
# - CPU baja de 50% a 30-40%
# - Replicas se mantienen durante 5 minutos (stabilization window)
# - Después de 5 minutos, replicas reducen gradualmente
```

### Monitoreo

```
Minuto 0: Carga activa
backend-despacho      4/4      4           4
CPU: 50%

Minuto 1: Carga termina, CPU baja
backend-despacho      4/4      4           4
CPU: 30%

Minuto 5: Stabilization window termina, HPA reduce
backend-despacho      3/3      3           3  (reduce 50%: de 4 a 2)
CPU: 25%

Minuto 6: Continúa reduciendo
backend-despacho      2/2      2           2  (min replicas alcanzado)
CPU: 20%
```

### Validación

✅ **Scale-down exitoso si:**
- Replicas se mantienen durante ~5 minutos después de carga
- Luego reducen gradualmente
- Se estabilizan en 2 replicas (min)

⚠️ **Nota:** El scale-down es intencionalmente lento para evitar oscilaciones.

---

## 5. Test 4: Validar Escalado de Nodos

### Objetivo

Verificar que EC2 Auto Scaling Group agrega nodos cuando faltan recursos.

### Procedimiento

```bash
# Terminal 1: Monitor de nodos
watch -n 10 'kubectl get nodes; echo "---"; kubectl top nodes'

# Terminal 2: Monitor de pods y HPA
watch -n 10 'kubectl get hpa,pods | grep -E "(HPA|backend|NAME)"'

# Terminal 3: Crear muchos pods (generar demanda de recursos)

# Opción A: Escalar manualmente deployments
kubectl scale deployment backend-despacho --replicas=10
kubectl scale deployment backend-despacho --replicas=10
kubectl scale deployment backend-despacho --replicas=10

# Opción B: Generar carga agresiva que escale automáticamente
# (debe generar suficiente carga para que HPA escale a máximo)

# Esperar 5-10 minutos y observar:
```

### Monitoreo

```
Fase 1: Nodos iniciales
Nodos: 2 (ip-10-0-10-100, ip-10-0-11-100)
CPU total: 4 cores
Pods: 2 backend

Fase 2: HPA escala a 5 replicas por demanda
Pods: 5 (3 pending, sin recursos)

Fase 3: ASG detecta pods pending
Auto Scaling Group agrega nodo

Fase 4: Nuevo nodo se une al cluster
Nodos: 3 (ip-10-0-10-100, ip-10-0-11-100, ip-10-0-12-100)
Pods pending se asignan al nuevo nodo

Resultado final:
Nodos: 3
Pods: 5 (todos running)
CPU: ~50% en cada nodo
```

### Validación

✅ **Escalado de nodos exitoso si:**
- New node aparece en `kubectl get nodes`
- Pending pods se asignan al nuevo nodo
- Todos los pods pasan a "Running"

⚠️ **Puede tomar 3-5 minutos:** Los nodos EC2 tardan en lanzarse

---

## 6. Test 5: Validar Recuperación ante Fallos

### Objetivo

Verificar que el sistema se recupera cuando pods fallan o se eliminan.

### Procedimiento

```bash
# Terminal 1: Monitor de pods
watch -n 2 'kubectl get pods -l app=backend-despacho'

# Terminal 2: Eliminar un pod
POD_NAME=$(kubectl get pods -l app=backend-despacho -o jsonpath='{.items[0].metadata.name}')
kubectl delete pod $POD_NAME

# Observar:
# - Pod desaparece
# - Controlador ReplicaSet crea nuevo pod
# - Nuevo pod pasa a "Running"
# - Servicio siguen funcionando sin interrupción

# Terminal 3: Enviar requests durante el cambio
kubectl run -it --rm curl --image=curlimages/curl --restart=Never \
  -- -H "Host: backend-despacho" \
  http://backend-despacho:8081/actuator/health
```

### Validación

✅ **Recuperación exitosa si:**
- Pod nuevo se crea automáticamente
- No hay downtime de servicio (requests siguen respondiendo)
- Aplicación recupera estado (si la BD tiene datos)

---

## 7. Test 6: Validar Persistencia de Datos

### Objetivo

Verificar que datos en MySQL persisten incluso si pod se elimina.

### Procedimiento

```bash
# 1. Obtener nombre del pod MySQL
MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')
echo "MySQL Pod: $MYSQL_POD"

# 2. Insertar datos de prueba
kubectl exec -it $MYSQL_POD -- \
  mysql -u root -proot despachos -e \
  "INSERT INTO despachos (id, descripcion) VALUES (99, 'TEST DESPACHO 99');"

# 3. Verificar que los datos existen
kubectl exec -it $MYSQL_POD -- \
  mysql -u root -proot despachos -e \
  "SELECT * FROM despachos WHERE id = 99;"

# Esperado: 1 row

# 4. Eliminar pod MySQL
kubectl delete pod $MYSQL_POD

# 5. Esperar a que se recree (10-20 segundos)
kubectl get pods -l app=mysql -w

# 6. Verificar datos aún existen
sleep 30  # Esperar a que MySQL se inicialice
NEW_MYSQL_POD=$(kubectl get pods -l app=mysql -o jsonpath='{.items[0].metadata.name}')

kubectl exec -it $NEW_MYSQL_POD -- \
  mysql -u root -proot despachos -e \
  "SELECT * FROM despachos WHERE id = 99;"

# Esperado: 1 row (mismo de antes)
```

### Validación

✅ **Persistencia exitosa si:**
- Datos existen después de recrear pod
- Significa que PersistentVolume mantiene datos
- Base de datos verdaderamente persistente

❌ **Si datos desaparecen:**
- Ver archivo [TROUBLESHOOTING: MySQL pierde datos](TROUBLESHOOTING.md)
- Revisar si PVC está configurado

---

## 8. Test 7: Validar Comunicación Frontend-Backend

### Objetivo

Verificar que frontend puede acceder APIs del backend a través del proxy.

### Procedimiento

```bash
# 1. Obtener URL del Load Balancer
LB_URL=$(kubectl get svc frontend-despacho \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Frontend URL: http://$LB_URL"

# 2. Acceder a frontend
curl -I http://$LB_URL
# Esperado: HTTP/1.1 200 OK

# 3. Testear proxy a backend despacho
curl http://$LB_URL/api/despachos/despachos
# Esperado: JSON response

# 4. Testear proxy a backend ventas
curl http://$LB_URL/api/ventas/ventas
# Esperado: JSON response

# 5. Test desde navegador
# Abrir: http://$LB_URL
# Abrir DevTools (F12)
# Console tab
# Ejecutar:
# fetch('/api/despachos/despachos').then(r => r.json()).then(d => console.log(d))
```

### Validación

✅ **Comunicación exitosa si:**
- Frontend carga (HTTP 200)
- Llamadas a /api/despachos/* responden
- Llamadas a /api/ventas/* responden
- DevTools console muestra datos JSON

---

## 9. Test 8: Validar Balanceador de Carga

### Objetivo

Verificar que ALB distribuye tráfico correctamente entre replicas.

### Procedimiento

```bash
# Terminal 1: Monitor de replicas con identificadores
kubectl get pods -l app=backend-despacho \
  -o custom-columns=NAME:.metadata.name,IP:.status.podIP

# Terminal 2: Generar requests y ver cuál pod los maneja

# Agregar logging a Spring Boot:
# En logs, verá requests llegando a diferentes pods

kubectl logs -f deployment/backend-despacho

# Terminal 3: Hacer múltiples requests desde client
for i in {1..10}; do
  curl http://backend-despacho:8081/actuator/health
  sleep 1
done

# Esperado en logs:
# Pod-1: 4 requests
# Pod-2: 3 requests
# Pod-3: 3 requests
# (distribución uniforme, no todo a un solo pod)
```

### Validación

✅ **Balanceador funcionando si:**
- Requests se distribuyen entre diferentes pods
- No hay un solo pod recibiendo todo el tráfico

---

## 10. Checklist Final de Validación

```
Test                              Resultado   Fecha
─────────────────────────────────────────────────────
Métricas recolectadas             ☐           ____
Scale-up automático               ☐           ____
Scale-down automático             ☐           ____
Escalado de nodos                 ☐           ____
Recuperación ante fallos           ☐           ____
Persistencia de datos              ☐           ____
Frontend-Backend comunicación      ☐           ____
Balanceador de carga               ☐           ____
Load Balancer accesible público    ☐           ____
CI/CD pipeline automático          ☐           ____
─────────────────────────────────────────────────────
TODOS LOS TESTS PASADOS            ☐           ____
```

---

## 11. Generación de Reporte

### Comando para generar reporte de cluster

```bash
# Crear directorio de reporte
mkdir -p reports
DATE=$(date +%Y-%m-%d_%H-%M-%S)

# Cluster info
kubectl cluster-info > reports/cluster_info_$DATE.txt

# Nodos
kubectl describe nodes > reports/nodes_$DATE.txt

# Deployments
kubectl get deployments -o yaml > reports/deployments_$DATE.yaml

# Services
kubectl get svc -o yaml > reports/services_$DATE.yaml

# HPA status
kubectl get hpa -o yaml > reports/hpa_$DATE.yaml

# Pods
kubectl get pods -o wide > reports/pods_$DATE.txt

# Events
kubectl get events --all-namespaces --sort-by='.lastTimestamp' > reports/events_$DATE.txt

# Metrics
kubectl top nodes > reports/nodes_metrics_$DATE.txt
kubectl top pods > reports/pods_metrics_$DATE.txt

echo "Reporte generado en: reports/"
ls -la reports/
```

---

## 12. Métricas Esperadas de Éxito

| Métrica | Valor Esperado | Rango Aceptable |
|---------|---|---|
| Response Time (p50) | <500ms | <1s |
| Response Time (p95) | <1s | <2s |
| Availability | 99.9% | >99% |
| Scaling Time (scale-up) | <2 min | <5 min |
| Scaling Time (scale-down) | <10 min | <15 min |
| CPU Utilization | 50% | 40-70% |
| Memory Utilization | 50% | 40-80% |
| Node Count | 2-4 | 2-4 |
| Pod Count | 4-10 | 2-10 |

---

**Última Actualización:** 2025-06-10

