#!/usr/bin/env pwsh

<#
.SYNOPSIS
Actualiza el servicio ECS con nuevas imágenes Docker

.PARAMETER Cluster
Nombre del cluster ECS

.PARAMETER Service
Nombre del servicio ECS

.PARAMETER Region
Región de AWS
#>

param(
    [string]$Cluster = "devops-u2-cluster",
    [string]$Service = "devops-u2-service",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "🔄 Actualizando servicio ECS..." -ForegroundColor Green

try {
    # Verificar que el cluster existe
    Write-Host "📋 Verificando cluster: $Cluster" -ForegroundColor Cyan
    $clusterInfo = aws ecs describe-clusters --clusters $Cluster --region $Region --output json
    
    # Actualizar servicio
    Write-Host "🚀 Forzando nuevo despliegue en $Service..." -ForegroundColor Cyan
    $output = aws ecs update-service `
        --cluster $Cluster `
        --service $Service `
        --force-new-deployment `
        --region $Region `
        --output json
    
    Write-Host "✅ Servicio actualizado exitosamente" -ForegroundColor Green
    
    # Esperar y mostrar estado
    Write-Host "`n⏳ Esperando a que ECS lance las nuevas tareas (espera 15 segundos)..." -ForegroundColor Yellow
    Start-Sleep -Seconds 15
    
    # Mostrar estado
    Write-Host "`n📊 Estado actual:" -ForegroundColor Cyan
    aws ecs describe-services `
        --cluster $Cluster `
        --services $Service `
        --region $Region `
        --query 'services[0].[serviceName,status,runningCount,desiredCount,deployments[0].status]' `
        --output table
    
    Write-Host "`n✅ ¡Actualización completa!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    exit 1
}
