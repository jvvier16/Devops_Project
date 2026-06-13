# Terraform AWS Infrastructure

## 🚀 Setup Inicial

### Opción 1: Script Interactivo (RECOMENDADO)

Ejecuta el script que te pedirá las credenciales interactivamente:

```powershell
cd c:\Users\javie\OneDrive\Escritorio\Devops_Project\infra\terraform
.\setup-credentials.ps1
```

El script creará automáticamente el archivo `terraform.tfvars` con tus credenciales.

### Opción 2: Manual

1. Copia el archivo de ejemplo:
```powershell
cp terraform.tfvars.example terraform.tfvars
```

2. Edita `terraform.tfvars` con tus credenciales de AWS Academy:
```hcl
aws_access_key_id     = "tu_access_key_id"
aws_secret_access_key = "tu_secret_access_key"
aws_session_token     = "tu_session_token"
aws_region            = "us-east-1"
```

## 📝 Flujo de Terraform

```powershell
# Inicializar Terraform
terraform init

# Ver el plan de infraestructura que se creará
terraform plan

# Aplicar los cambios
terraform apply

# Destruir la infraestructura (cuando sea necesario)
terraform destroy
```

## ⚠️ IMPORTANTE: Seguridad

- ❌ **NUNCA** subas `terraform.tfvars` a Git (contiene secretos)
- ✅ El archivo `.gitignore` está configurado para protegerse automáticamente
- 🔐 Las credenciales se marcan como `sensitive` en Terraform
- ⏰ Los tokens de AWS Academy expiran después de ~4 horas

## 🔄 Renovar Credenciales

Cuando tus credenciales de AWS Academy expiren:

```powershell
# Simplemente ejecuta de nuevo el setup
.\setup-credentials.ps1
```

O edita manualmente `terraform.tfvars` con las nuevas credenciales.

## 📋 Estructura de Archivos

```
terraform/
├── main.tf                    # Configuración principal de AWS
├── variables.tf               # Variables de entrada (credenciales, región, etc)
├── terraform.tfvars           # TUS CREDENCIALES (NO SUBIR A GIT)
├── terraform.tfvars.example   # Plantilla de ejemplo
├── setup-credentials.ps1      # Script interactivo de setup
├── .gitignore                 # Protege archivos sensibles
└── README.md                  # Este archivo
```

## 🐛 Troubleshooting

### Error: InvalidClientTokenId
- Las credenciales son inválidas o han expirado
- Obtén nuevas credenciales de AWS Academy
- Ejecuta `.\setup-credentials.ps1` nuevamente

### Error: No AWS credentials configured
- Asegúrate de haber ejecutado `setup-credentials.ps1`
- Verifica que `terraform.tfvars` existe y tiene contenido

### Error: Token has expired
- Los tokens de AWS Academy duran ~4 horas
- Obtén un nuevo token de tu dashboard de AWS Academy
- Actualiza `terraform.tfvars` con el nuevo token
