#!/usr/bin/env pwsh

# Script para limpiar ECS y luego destruir con Terraform

param(
    [string]$Cluster = "devops-u2-cluster",
    [string]$Service = "devops-u2-service",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Continue"

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Limpiando recursos ECS" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Eliminar servicio
Write-Host "🔄 [1/3] Eliminando servicio ECS: $Service..." -ForegroundColor Yellow
aws ecs delete-service --cluster $Cluster --service $Service --force --region $Region 2>&1 | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Servicio marcado para eliminación" -ForegroundColor Green
} else {
    Write-Host "⚠️  El servicio podría no existir, continuando..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "⏳ [2/3] Esperando 30 segundos a que se elimine..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 2. Detener tareas
Write-Host ""
Write-Host "🛑 [3/3] Deteniendo tareas activas..." -ForegroundColor Yellow
$tasks = aws ecs list-tasks --cluster $Cluster --region $Region --query 'taskArns[]' --output text 2>&1

if ($tasks -and $tasks -ne "") {
    foreach ($task in $tasks.Split()) {
        Write-Host "   Deteniendo: $task" -ForegroundColor Gray
        aws ecs stop-task --cluster $Cluster --task $task --region $Region 2>&1 | Out-Null
    }
    Write-Host "✅ Tareas detenidas" -ForegroundColor Green
} else {
    Write-Host "✅ No hay tareas activas" -ForegroundColor Green
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  ✅ Cleanup completado" -ForegroundColor Green
Write-Host "  Ahora ejecutando: terraform destroy" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# 3. Ejecutar terraform destroy
Push-Location ./infra/etapa_2
Write-Host "📋 Ejecutando terraform destroy..." -ForegroundColor Yellow
terraform destroy -auto-approve
Pop-Location

Write-Host ""
Write-Host "✅ ¡Destrucción completada!" -ForegroundColor Green
