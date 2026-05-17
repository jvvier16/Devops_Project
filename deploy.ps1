#!/usr/bin/env pwsh

param(
    [string]$AwsRegion = "us-east-1",
    [string]$AccountId = "404971863212",
    [string]$ProjectName = "devops-u2"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Iniciando despliegue automatizado..." -ForegroundColor Green
Write-Host "Region: $AwsRegion | Account: $AccountId | Project: $ProjectName" -ForegroundColor Cyan

# 1. Login en ECR
Write-Host "`n📦 [1/5] Conectando a ECR..." -ForegroundColor Yellow
$loginPassword = aws ecr get-login-password --region $AwsRegion
$loginPassword | docker login --username AWS --password-stdin "$AccountId.dkr.ecr.$AwsRegion.amazonaws.com" 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Autenticación ECR exitosa" -ForegroundColor Green
} else {
    Write-Host "❌ Error en autenticación ECR" -ForegroundColor Red
    exit 1
}

# 2. Build Backend
Write-Host "`n🔨 [2/5] Construyendo Backend..." -ForegroundColor Yellow
$backendImage = "$AccountId.dkr.ecr.$AwsRegion.amazonaws.com/$ProjectName-backend:latest"
docker buildx build --platform linux/amd64 -t $backendImage ./back-Ventas_SpringBoot/Springboot-API-REST --push
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Backend construido: $backendImage" -ForegroundColor Green
} else {
    Write-Host "❌ Error construyendo Backend" -ForegroundColor Red
    exit 1
}

# 3. Build Frontend
Write-Host "`n🎨 [3/5] Construyendo Frontend..." -ForegroundColor Yellow
$frontendImage = "$AccountId.dkr.ecr.$AwsRegion.amazonaws.com/$ProjectName-frontend:latest"
docker buildx build --platform linux/amd64 -t $frontendImage ./front_despacho --push
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Frontend construido: $frontendImage" -ForegroundColor Green
} else {
    Write-Host "❌ Error construyendo Frontend" -ForegroundColor Red
    exit 1
}

# 4. Update ECS Service
Write-Host "`n🐳 [4/5] Actualizando ECS Service..." -ForegroundColor Yellow

# Verificar que el servicio existe primero
$serviceExists = aws ecs describe-services --cluster "$ProjectName-cluster" --services "$ProjectName-service" --region $AwsRegion --query 'services[0].serviceName' --output text 2>$null

if ($null -eq $serviceExists -or $serviceExists -eq "None") {
    Write-Host "⚠️  Servicio no encontrado. Creando servicio..." -ForegroundColor Yellow
    # El servicio debe existir desde Terraform, saltamos este paso
    Write-Host "❌ El servicio debe estar creado por Terraform primero" -ForegroundColor Red
    exit 1
}

# Actualizar servicio sin redirecciones que puedan causar bloqueos
$updateResult = aws ecs update-service --cluster "$ProjectName-cluster" --service "$ProjectName-service" --force-new-deployment --region $AwsRegion 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ ECS Service actualizado correctamente" -ForegroundColor Green
    Start-Sleep -Seconds 3
} else {
    Write-Host "❌ Error actualizando ECS Service: $updateResult" -ForegroundColor Red
    exit 1
}

# 5. Mostrar estado
Write-Host "`n📊 [5/5] Mostrando estado del despliegue..." -ForegroundColor Yellow
aws ecs describe-services `
    --cluster "$ProjectName-cluster" `
    --services "$ProjectName-service" `
    --region $AwsRegion | ConvertFrom-Json | Select-Object -ExpandProperty services | Select-Object @{
    Name       = "ServiceName"
    Expression = { $_.serviceName }
}, @{
    Name       = "Status"
    Expression = { $_.status }
}, @{
    Name       = "RunningCount"
    Expression = { $_.runningCount }
}, @{
    Name       = "DesiredCount"
    Expression = { $_.desiredCount }
} | Format-Table -AutoSize

Write-Host "`n✅ ¡Despliegue completado exitosamente!" -ForegroundColor Green
Write-Host "🔗 Espera 2-3 minutos para que ECS lance las nuevas tareas..." -ForegroundColor Cyan
