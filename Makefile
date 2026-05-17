.PHONY: help build up down logs test clean lint format

# Variables
DOCKER_COMPOSE := docker-compose
ENV_DEV := -f docker-compose.dev.yml
ENV_STD := 
ENV_PRO := -f docker-compose.pro.yml

help:
	@echo "🚀 DEVOPS PROJECT - Comandos Disponibles"
	@echo ""
	@echo "DESARROLLO:"
	@echo "  make dev-up              Levantar ambiente de desarrollo"
	@echo "  make dev-down            Detener desarrollo"
	@echo "  make dev-logs            Ver logs en tiempo real"
	@echo ""
	@echo "PRODUCCIÓN:"
	@echo "  make prod-up             Levantar con Nginx"
	@echo "  make prod-down           Detener producción"
	@echo ""
	@echo "BUILD:"
	@echo "  make build               Build todos los servicios"
	@echo "  make build-ventas        Build solo backend ventas"
	@echo "  make build-despacho      Build solo backend despachos"
	@echo "  make build-frontend      Build solo frontend"
	@echo ""
	@echo "TESTS:"
	@echo "  make test                Correr todos los tests"
	@echo "  make test-ventas         Tests backend ventas"
	@echo "  make test-despacho       Tests backend despachos"
	@echo "  make test-frontend       Tests frontend"
	@echo ""
	@echo "LINTING:"
	@echo "  make lint                Linting de todo"
	@echo "  make format              Formatear código"
	@echo ""
	@echo "UTILIDADES:"
	@echo "  make status              Ver estado de contenedores"
	@echo "  make clean               Limpiar volúmenes y contenedores"
	@echo "  make db-backup           Backup de BD"
	@echo "  make shell-db            Acceder a MySQL"
	@echo ""

# =====================================================
# DESARROLLO
# =====================================================

dev-up:
	$(DOCKER_COMPOSE) $(ENV_DEV) up --build
.PHONY: dev-up

dev-down:
	$(DOCKER_COMPOSE) $(ENV_DEV) down
.PHONY: dev-down

dev-logs:
	$(DOCKER_COMPOSE) $(ENV_DEV) logs -f
.PHONY: dev-logs

# =====================================================
# PRODUCCIÓN
# =====================================================

prod-up:
	$(DOCKER_COMPOSE) $(ENV_PRO) up --build
.PHONY: prod-up

prod-down:
	$(DOCKER_COMPOSE) $(ENV_PRO) down
.PHONY: prod-down

# =====================================================
# BUILD
# =====================================================

build:
	@echo "🔨 Build Ventas..."
	cd back-Ventas_SpringBoot/Springboot-API-REST && mvn clean package -DskipTests
	@echo "✅ Build Despachos..."
	cd back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO && mvn clean package -DskipTests
	@echo "✅ Build Frontend..."
	cd front_despacho && npm install && npm run build
	@echo "✅ Todos los builds completados"
.PHONY: build

build-ventas:
	cd back-Ventas_SpringBoot/Springboot-API-REST && mvn clean package -DskipTests
	docker build -t ventas-backend:latest back-Ventas_SpringBoot/Springboot-API-REST
.PHONY: build-ventas

build-despacho:
	cd back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO && mvn clean package -DskipTests
	docker build -t despacho-backend:latest back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO
.PHONY: build-despacho

build-frontend:
	cd front_despacho && npm install && npm run build
	docker build -t despacho-frontend:latest front_despacho
.PHONY: build-frontend

# =====================================================
# TESTS
# =====================================================

test: test-ventas test-despacho test-frontend
.PHONY: test

test-ventas:
	cd back-Ventas_SpringBoot/Springboot-API-REST && mvn test
.PHONY: test-ventas

test-despacho:
	cd back-Despachos_SpringBoot/Springboot-API-REST-DESPACHO && mvn test
.PHONY: test-despacho

test-frontend:
	cd front_despacho && npm test
.PHONY: test-frontend

# =====================================================
# LINTING
# =====================================================

lint: lint-frontend
.PHONY: lint

lint-frontend:
	cd front_despacho && npm run lint
.PHONY: lint-frontend

format:
	cd front_despacho && npm run lint --fix
.PHONY: format

# =====================================================
# UTILIDADES
# =====================================================

status:
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
.PHONY: status

shell-db:
	docker exec -it despacho-db mysql -u root -pexample
.PHONY: shell-db

db-backup:
	@echo "📦 Backup de BD..."
	docker exec despacho-db mysqldump -u root -pexample --all-databases > db-backup-$$(date +%Y%m%d_%H%M%S).sql
	@echo "✅ Backup completado"
.PHONY: db-backup

clean:
	@echo "🧹 Limpiando..."
	$(DOCKER_COMPOSE) down -v
	$(DOCKER_COMPOSE) $(ENV_DEV) down -v
	$(DOCKER_COMPOSE) $(ENV_PRO) down -v
	docker system prune -f
	@echo "✅ Limpieza completada"
.PHONY: clean

# =====================================================
# VERIFICACIÓN RÁPIDA
# =====================================================

check-apis:
	@echo "🧪 Verificando APIs..."
	@echo "Ventas Backend:"
	curl -s http://localhost:8080/swagger-ui.html | head -1 && echo "✅" || echo "❌"
	@echo "Despacho Backend:"
	curl -s http://localhost:8081/swagger-ui.html | head -1 && echo "✅" || echo "❌"
	@echo "Frontend:"
	curl -s http://localhost:3000 | head -1 && echo "✅" || echo "❌"
.PHONY: check-apis

# =====================================================
# CI/CD LOCAL
# =====================================================

ci: build test lint
	@echo "✅ CI pipeline local completado"
.PHONY: ci

# =====================================================
# DOCKER REGISTRY
# =====================================================

docker-push:
	docker tag ventas-backend:latest ghcr.io/yourorg/ventas-backend:latest
	docker tag despacho-backend:latest ghcr.io/yourorg/despacho-backend:latest
	docker tag despacho-frontend:latest ghcr.io/yourorg/despacho-frontend:latest
	docker push ghcr.io/yourorg/ventas-backend:latest
	docker push ghcr.io/yourorg/despacho-backend:latest
	docker push ghcr.io/yourorg/despacho-frontend:latest
.PHONY: docker-push

# =====================================================
# TERRAFORM
# =====================================================

tf-plan:
	cd infra/etapa_2 && terraform plan -out=tfplan
.PHONY: tf-plan

tf-apply:
	cd infra/etapa_2 && terraform apply tfplan
.PHONY: tf-apply

tf-destroy:
	cd infra/etapa_2 && terraform destroy
.PHONY: tf-destroy
