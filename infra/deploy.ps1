# Script de despliegue para Terraform en AWS (PowerShell)
# Uso: .\deploy.ps1 -Etapa etapa_1 -Accion plan

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("etapa_1", "etapa_2")]
    [string]$Etapa = "etapa_1",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("init", "plan", "apply", "destroy", "validate")]
    [string]$Accion = "plan"
)

$ErrorActionPreference = "Stop"

Write-Host "========================================" -ForegroundColor Yellow
Write-Host "DevOps Project - Terraform Deployer" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

$rutaInfra = Join-Path -Path $PSScriptRoot -ChildPath "infra" -ChildPath $Etapa

Write-Host "Directorio: $rutaInfra" -ForegroundColor Green
Write-Host "Acción: $Accion" -ForegroundColor Green

Push-Location $rutaInfra

try {
    switch ($Accion) {
        "init" {
            Write-Host "Inicializando Terraform..." -ForegroundColor Yellow
            terraform init
        }
        "validate" {
            Write-Host "Validando sintaxis..." -ForegroundColor Yellow
            terraform validate
        }
        "plan" {
            Write-Host "Generando plan..." -ForegroundColor Yellow
            terraform plan -out=tfplan
        }
        "apply" {
            Write-Host "Aplicando cambios..." -ForegroundColor Yellow
            if (Test-Path tfplan) {
                terraform apply tfplan
                Remove-Item tfplan
            } else {
                Write-Host "Error: Ejecuta 'plan' primero" -ForegroundColor Red
                exit 1
            }
        }
        "destroy" {
            Write-Host "⚠️  Esto destruirá todos los recursos en $Etapa" -ForegroundColor Red
            $respuesta = Read-Host "¿Estás seguro? (s/n)"
            if ($respuesta -eq "s") {
                terraform destroy -auto-approve
            } else {
                Write-Host "Cancelado" -ForegroundColor Yellow
            }
        }
    }
    
    Write-Host "✓ Completado" -ForegroundColor Green
}
finally {
    Pop-Location
}
