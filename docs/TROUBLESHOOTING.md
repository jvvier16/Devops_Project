# Guía de Troubleshooting - DevOps Project

## 1. Problemas Generales del Cluster

### Problema: "Unable to connect to the server"

```bash
# Error: Unable to connect to the server: dial tcp: lookup on ...: no such host

# Solución:
# 1. Verificar que el cluster EKS existe
aws eks describe-cluster --name despachos-cluster --region us-east-1

# 2. Actualizar kubeconfig
aws eks update-kubeconfig --name despachos-cluster --region us-east-1

# 3. Verificar contexto activo
kubectl config get-contexts
kubectl config use-context arn:aws:eks:us-east-1:ACCOUNT_ID:cluster/despachos-cluster

# 4. Verificar credenciales AWS
aws sts get-caller-identity
```

### Problema: "The server doesn't have a resource type 'nodes'"

```bash
# Error: The server doesn't have a resource type 'nodes'

# Solución:
# 1. Verificar permisos IAM (role tiene AmazonEKSWorkerNodePolicy)
aws iam list-attached-role-policies --role-name EksNodeRole

# 2. Verificar nodos en AWS
aws ec2 describe-instances --region us-east-1

# 3. Si no hay nodos, crear nodegroup
aws eks create-nodegroup --cluster-name despachos-cluster \
  --nodegroup-name despachos-nodes --subnets subnet-xxx \
  --node-role arn:aws:iam::ACCOUNT_ID:role/EksNodeRole \
  --scaling-config minSize=2,maxSize=4,desiredSize=2 \
  --instance-types t3.medium
```

---

## 2. Problemas de Deployment

### Problema: Pod en estado "ImagePullBackOff"

```bash
# Síntomas:
kubectl get pods
# STATUS: ImagePullBackOff

# Causas posibles:
# 1. Imagen no existe en ECR
# 2. Nodos no tienen credenciales ECR
# 3. Imagen tag incorrecto en deployment

# Soluciones:

# 1. Verificar imagen en ECR
export ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr describe-images --repository-name backend-despacho --region us-east-1

# 2. Verificar tag de imagen en deployment
kubectl get deployment backend-despacho -o yaml | grep image

# 3. Describir pod para ver detalle del error
kubectl describe pod <pod-name>

# 4. Si falta credencial ECR, crear secret:
kubectl create secret docker-registry ecr-secret \
  --docker-server=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1)

# 5. Agregar secret al deployment:
spec:
  imagePullSecrets:
    - name: ecr-secret

# 6. Re-aplicar deployment
kubectl apply -f infra/k8s/backend.yml
```

### Problema: Pod en estado "CrashLoopBackOff"

```bash
# Síntomas:
kubectl get pods
# STATUS: CrashLoopBackOff

# Significa: Pod inicia pero falla, intenta reiniciar en loop

# Soluciones:

# 1. Ver logs del pod
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # Logs del pod anterior

# 2. Ver más detalles
kubectl describe pod <pod-name>

# 3. Ver eventos
kubectl get events --sort-by='.lastTimestamp'

# Causas comunes:
# - Backend no conecta a MySQL (DB_ENDPOINT incorrecto)
# - MySQL no está running
# - Puertos ocupados
# - Variables de entorno faltantes

# 4. Verificar que MySQL está running
kubectl get pods -l app=mysql
kubectl logs <mysql-pod>

# 5. Verificar conectividad backend a MySQL
kubectl exec -it <backend-pod> -- \
  bash -c "echo > /dev/tcp/mysql/3306 && echo 'OK' || echo 'FAIL'"

# 6. Ver configuración de variables
kubectl exec <backend-pod> -- env | grep DB_
```

### Problema: Pod en estado "Pending"

```bash
# Síntomas:
kubectl get pods
# STATUS: Pending (se queda así indefinidamente)

# Causas:
# 1. Recursos insuficientes (CPU/Memory)
# 2. PersistentVolume no disponible
# 3. ImagePullSecret faltante

# Soluciones:

# 1. Ver por qué está pending
kubectl describe pod <pod-name>
# Buscar "Events" al final

# 2. Verificar recursos disponibles en nodos
kubectl top nodes
kubectl describe nodes

# 3. Ver requests/limits del pod
kubectl get pod <pod-name> -o yaml | grep -A 5 resources

# 4. Si faltan recursos, agregar nodos
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name eks-despachos-nodes-asg \
  --desired-capacity 3 \
  --region us-east-1

# 5. O reducir requests del pod:
# En deployment.yml, ajustar:
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

### Problema: Pod en estado "Terminating"

```bash
# Síntomas:
kubectl get pods
# STATUS: Terminating (se queda así)

# Soluciones:

# 1. Ver logs de finalización
kubectl describe pod <pod-name>

# 2. Si se queda mucho tiempo, forzar eliminación
kubectl delete pod <pod-name> --grace-period=0 --force

# 3. Verificar logs de la aplicación para entiender por qué tarda
kubectl logs <pod-name>
```

---

## 3. Problemas de Conectividad

### Problema: Backend no conecta a MySQL

```bash
# Síntomas:
# - Pod backend en CrashLoopBackOff
# - Logs muestran "Connection refused" o "Cannot connect to MySQL"

# Test de conectividad:

# 1. Verificar que MySQL está running
kubectl get pods -l app=mysql
kubectl logs <mysql-pod> | head -20

# 2. Verificar variables de entorno en backend
kubectl exec <backend-pod> -- env | grep DB_

# 3. Test de conectividad dentro del cluster
kubectl exec -it <backend-pod> -- bash

# Dentro del pod:
# - Verificar DNS:
nslookup mysql
# Esperado: IP interna del pod MySQL

# - Test de puerto:
echo > /dev/tcp/mysql/3306 && echo 'MySQL OK' || echo 'MySQL FAIL'

# - Intentar conectar con mysql client:
mysql -h mysql -u root -proot -e "SHOW DATABASES;"

# 4. Si falla DNS, verificar CoreDNS:
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl logs -n kube-system -l k8s-app=kube-dns

# 5. Aumentar timeout en application.properties:
spring.datasource.hikari.connectionTimeout=60000
spring.datasource.hikari.validationTimeout=10000
```

### Problema: Frontend no conecta a Backend

```bash
# Síntomas:
# - Frontend carga OK
# - Dev console muestra errores CORS o conexión rechazada
# - No se muestran datos de API

# Test de conectividad:

# 1. Verificar que backend está running
kubectl get pods -l app=backend-despacho
kubectl logs <backend-pod> | head -20

# 2. Test desde frontend pod:
kubectl exec -it <frontend-pod> -- bash

# Dentro del pod:
# - DNS lookup:
nslookup backend-despacho
# Esperado: IP interna del servicio

# - Test HTTP:
curl http://backend-despacho:8081/actuator/health
# Esperado: {"status":"UP"}

# 3. Verificar nginx config en frontend
kubectl exec -it <frontend-pod> -- cat /etc/nginx/conf.d/default.conf

# Debe tener:
# location /api/despachos/ {
#     proxy_pass http://backend-despacho:8081/;
# }

# 4. Test manual del proxy:
curl http://frontend-despacho:8080/api/despachos/despachos

# 5. Si CORS error, verificar backend tiene:
spring.web.allow-cors=true

# 6. Ver logs de nginx en frontend
kubectl logs <frontend-pod>
```

### Problema: Service no tiene IP externa (LoadBalancer Pending)

```bash
# Síntomas:
kubectl get svc frontend-despacho
# EXTERNAL-IP muestra <pending>

# Soluciones:

# 1. Es normal que tarde 2-3 minutos
kubectl get svc frontend-despacho -w

# 2. Verificar que AWS Load Balancer Controller esté instalado
kubectl get pods -n kube-system | grep aws-load-balancer

# Si no está, instalar:
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system

# 3. Ver logs del controller
kubectl logs -f -n kube-system deployment/aws-load-balancer-controller

# 4. Describir servicio
kubectl describe svc frontend-despacho

# 5. Buscar errores en eventos
kubectl get events --sort-by='.lastTimestamp'

# 6. Verificar Security Groups en AWS:
aws ec2 describe-security-groups --region us-east-1 \
  --filters "Name=tag:kubernetes.io/cluster/despachos-cluster,Values=owned"

# 7. Si sigue sin aparecer, forzar re-creación:
kubectl delete svc frontend-despacho
kubectl apply -f infra/k8s/frontend.yml
```

---

## 4. Problemas de Autoscaling

### Problema: HPA muestra "unknown" en métricas

```bash
# Síntomas:
kubectl describe hpa backend-despacho-hpa
# METRICS muestra: <unknown>

# Soluciones:

# 1. Verificar Metrics Server instalado
kubectl get deployment -n kube-system metrics-server
# Si no existe:
kubectl apply -f \
  https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 2. Esperar a que Metrics Server esté ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/metrics-server -n kube-system

# 3. Verificar métricas de pods
kubectl top pods
# Si muestra "error: metrics not available"
# - Esperar 1-2 minutos más
# - Ver logs de metrics-server:
kubectl logs -f -n kube-system deployment/metrics-server

# 4. Ver logs completos
kubectl logs -n kube-system deployment/metrics-server --all-containers=true

# 5. Ver eventos de HPA
kubectl describe hpa backend-despacho-hpa
# Buscar en "Events"
```

### Problema: HPA no escala aunque haya carga

```bash
# Síntomas:
# - Pods con CPU alta (> 50%)
# - Replicas no aumentan

# Soluciones:

# 1. Verificar HPA configurado correctamente
kubectl get hpa
kubectl describe hpa backend-despacho-hpa

# 2. Ver métricas de CPU
kubectl top pods -l app=backend-despacho

# 3. Ver si hay eventos de scaling
kubectl get events --field-selector involvedObject.kind=HorizontalPodAutoscaler

# 4. Aumentar CPU limit si es muy bajo:
# En deployment, los pods deben tener CPU request:
resources:
  requests:
    cpu: 100m  # Necesario para HPA
    memory: 128Mi

# 5. Ver logs de HPA controller
kubectl logs -n kube-system deployment/metrics-server

# 6. Verificar no hay suficientes nodos:
kubectl describe nodes
# Si uno tiene allocatable muy bajo, agregar nodo
```

### Problema: HPA no escala hacia abajo

```bash
# Síntomas:
# - Replicas bajaron después de carga
# - Pero quedan más replicas de lo esperado

# Soluciones:

# 1. Es normal tener delay de 5 minutos (stabilizationWindowSeconds)
# Ver configuración en hpa.yml

# 2. Verificar que CPU bajó por debajo de threshold
kubectl top pods

# 3. Forzar evaluación manual:
# No se puede, pero kubectl apply -f hpa.yml puede ayudar

# 4. Aumentar agresividad de scale-down:
# En hpa.yml, cambiar scaleDown.policies
scaleDown:
  stabilizationWindowSeconds: 60  # En lugar de 300
  policies:
    - type: Percent
      value: 100  # En lugar de 50 (elimina todas)

# 5. Re-aplicar:
kubectl apply -f infra/k8s/hpa.yml
```

---

## 5. Problemas de Persistencia

### Problema: MySQL pierde datos después de redeploy

```bash
# Síntomas:
# - Datos desaparecen cuando se elimina pod
# - mysql.yml no tiene PersistentVolume

# Soluciones:

# 1. Verificar si hay PersistentVolume
kubectl get pv
kubectl get pvc

# 2. Ver si MySQL está usando volumeMounts:
kubectl get deployment mysql -o yaml | grep -A 10 volumeMounts

# 3. Si no existe, agregar PersistentVolume a mysql.yml:
spec:
  containers:
  - name: mysql
    volumeMounts:
    - name: mysql-storage
      mountPath: /var/lib/mysql
  volumes:
  - name: mysql-storage
    persistentVolumeClaim:
      claimName: mysql-pvc

# 4. Crear PersistentVolumeClaim:
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: ebs-sc
  resources:
    requests:
      storage: 10Gi

# 5. Crear StorageClass:
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com

# 6. Re-aplicar:
kubectl apply -f infra/k8s/
```

---

## 6. Problemas de CI/CD

### Problema: GitHub Actions falla en "Build Image"

```bash
# Síntomas:
# - Pipeline en GitHub Actions falla en "Build Docker Image"
# - Error: "failed to solve with frontend dockerfile.v0"

# Soluciones:

# 1. Verificar Dockerfile existe en ruta correcta
ls ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO/Dockerfile

# 2. Verificar sintaxis del Dockerfile
docker build \
  -t test-build \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO

# 3. Ver logs de la action en GitHub
# - Ir a: https://github.com/tu-usuario/repo/actions
# - Hacer click en el workflow fallido
# - Ver logs completos

# 4. Verificar archivo workflow (.github/workflows/ci.yml):
# - Rutas correctas
# - Variables de entorno definidas
# - Permisos adecuados

# 5. Test local del build:
docker buildx build \
  --platform linux/amd64 \
  -t backend-despacho:test \
  ./back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
```

### Problema: GitHub Actions falla en "Deploy to EKS"

```bash
# Síntomas:
# - Pipeline falla en "Apply Kubernetes manifests"
# - Error: "error: unable to recognize..."

# Soluciones:

# 1. Verificar que AWS credentials están configurados
# En GitHub Secrets: https://github.com/tu-usuario/repo/settings/secrets/actions
# Debe tener:
# - AWS_ACCESS_KEY_ID
# - AWS_SECRET_ACCESS_KEY
# - AWS_SESSION_TOKEN (si es temporal)

# 2. Verificar kubeconfig en action:
# - El command `aws eks update-kubeconfig` debe ser correcto
# - El nombre del cluster debe ser: despachos-cluster

# 3. Verificar manifiestos Kubernetes están correctos:
kubectl apply -f infra/k8s/ --dry-run=client

# 4. Ver logs completos del workflow:
# En GitHub Actions, ver "View job logs"

# 5. Si imágenes no se encuentran:
# - Verificar que ECR repositories existen
aws ecr describe-repositories --region us-east-1

# - Verificar tags en ECR:
aws ecr describe-images --repository-name backend-despacho --region us-east-1
```

---

## 7. Problemas de Rendimiento

### Problema: Pods lentos o timeouts

```bash
# Síntomas:
# - Respuestas lentas de API
# - Timeouts en el frontend

# Soluciones:

# 1. Ver recursos disponibles
kubectl top pods
kubectl top nodes

# 2. Ver CPU/Memory usage
kubectl describe node <node-name>

# 3. Ver logs de aplicación
kubectl logs <pod-name>

# 4. Aumentar resources requests/limits:
resources:
  requests:
    cpu: 200m  # En lugar de 100m
    memory: 256Mi
  limits:
    cpu: 1000m
    memory: 1Gi

# 5. Aumentar replicas manualmente:
kubectl scale deployment backend-despacho --replicas=4

# 6. Ver si hay pending requests:
kubectl describe deployment backend-despacho
```

### Problema: Base de datos lenta

```bash
# Síntomas:
# - MySQL tardío en responder
# - Queries lentas

# Soluciones:

# 1. Ver logs de MySQL
kubectl logs <mysql-pod>

# 2. Conectar a MySQL y chequear:
kubectl exec -it <mysql-pod> -- mysql -u root -proot

# En MySQL:
SHOW PROCESSLIST;  # Queries en ejecución
SHOW STATUS;       # Estadísticas

# 3. Ver si hay queries long-running:
SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST \
  WHERE TIME > 30;  # Más de 30 segundos

# 4. Verificar indexes:
EXPLAIN SELECT * FROM despachos WHERE id = 1;

# 5. Aumentar MySQL limits:
# En deployment:
env:
  - name: MYSQL_MAX_CONNECTIONS
    value: "1000"

# 6. Ver tamaño de base de datos:
du -sh /var/lib/mysql
```

---

## 8. Comandos Útiles para Debug

```bash
# Ver todo lo que está corriendo:
kubectl get all

# Ver eventos de cluster:
kubectl get events --all-namespaces --sort-by='.lastTimestamp'

# Ver logs de múltiples pods:
kubectl logs -f -l app=backend-despacho

# Port-forward para acceso local:
kubectl port-forward svc/backend-despacho 8081:8081
# Luego: curl http://localhost:8081/health

# Ejecutar comando en pod:
kubectl exec -it <pod-name> -- bash

# Copiar archivo desde/hacia pod:
kubectl cp <pod-name>:/ruta/archivo archivo-local
kubectl cp archivo-local <pod-name>:/ruta/archivo

# Ver configuración de pod:
kubectl get pod <pod-name> -o yaml

# Editar deployment en vivo:
kubectl edit deployment <deployment-name>

# Watch de recursos:
watch kubectl top pods
watch kubectl get hpa

# Describir recurso con eventos:
kubectl describe pod <pod-name>
kubectl describe deployment <deployment-name>

# Ver labels y selectors:
kubectl get pods --show-labels
kubectl get pods -l app=backend-despacho

# Scales:
kubectl scale deployment backend-despacho --replicas=3
```

---

## 9. Checklist de Validación

- [ ] Cluster EKS creado y accesible
- [ ] 2+ nodos en estado Ready
- [ ] ECR repositorios creados
- [ ] Imágenes buildadas y pusheadas
- [ ] MySQL pod running con datos persistentes
- [ ] Backend Despacho pod running
- [ ] Backend Ventas pod running
- [ ] Frontend pod running
- [ ] Services creados correctamente
- [ ] Frontend LoadBalancer tiene IP externa
- [ ] Frontend accesible por HTTP
- [ ] Nginx proxy configurado correctamente
- [ ] Frontend → Backend comunicación OK
- [ ] Backend → MySQL comunicación OK
- [ ] Metrics Server instalado
- [ ] HPA status OK (no "unknown")
- [ ] CI/CD pipeline ejecutando
- [ ] Logs accesibles en CloudWatch

---

## 10. Contactos y Recursos

**Recursos:**
- [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [Kubernetes Debugging](https://kubernetes.io/docs/tasks/debug-application-cluster/)
- [Spring Boot Logs](https://spring.io/guides/gs/centralized-configuration/)

**Para preguntas:**
- Revisar logs: `kubectl logs -f <pod-name>`
- Describir recurso: `kubectl describe <resource>`
- Ver eventos: `kubectl get events --sort-by='.lastTimestamp'`

