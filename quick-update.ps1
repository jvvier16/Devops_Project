#!/usr/bin/env pwsh
# Script simple para actualizar ECS sin bloqueos

Write-Host "🚀 Actualizando servicio ECS..." -ForegroundColor Cyan

# Ejecutar comando sin capturar output que pueda causar bloqueos
& aws ecs update-service --cluster devops-u2-cluster --service devops-u2-service --force-new-deployment --region us-east-1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Actualización iniciada. Espera 30 segundos..." -ForegroundColor Green
    Start-Sleep -Seconds 5
    
    # Mostrar estado de forma no bloqueante
    & aws ecs describe-services --cluster devops-u2-cluster --services devops-u2-service --region us-east-1 --query 'services[0].[serviceName,status,runningCount,desiredCount]' --output text
} else {
    Write-Host "❌ Error en la actualización" -ForegroundColor Red
}
