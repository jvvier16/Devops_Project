# Script para configurar credenciales de AWS Academy interactivamente

Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║     Configurador de Credenciales AWS Academy             ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Pedir credenciales
$accessKey = Read-Host "Ingresa tu AWS Access Key ID"
$secretKey = Read-Host "Ingresa tu AWS Secret Access Key" -AsSecureString
$secretKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($secretKey))
$sessionToken = Read-Host "Ingresa tu AWS Session Token (presiona Enter si no tienes)"
$region = Read-Host "Ingresa la región AWS (default: us-east-1)" 

if ([string]::IsNullOrWhitespace($region)) {
    $region = "us-east-1"
}

if ([string]::IsNullOrWhitespace($sessionToken)) {
    $sessionToken = ""
}

# Crear archivo terraform.tfvars
$tfvarsContent = @"
aws_access_key_id     = "$accessKey"
aws_secret_access_key = "$secretKeyPlain"
aws_session_token     = "$sessionToken"
aws_region            = "$region"
"@

$tfvarsPath = Join-Path (Split-Path $PSCommandPath -Parent) "terraform.tfvars"
$tfvarsContent | Out-File -FilePath $tfvarsPath -Encoding UTF8 -Force

Write-Host ""
Write-Host "✅ Archivo terraform.tfvars creado exitosamente" -ForegroundColor Green
Write-Host "📁 Ruta: $tfvarsPath" -ForegroundColor Green
Write-Host ""
Write-Host "Ahora ejecuta:" -ForegroundColor Cyan
Write-Host "  terraform init" -ForegroundColor Yellow
Write-Host "  terraform plan" -ForegroundColor Yellow
Write-Host "  terraform apply" -ForegroundColor Yellow
