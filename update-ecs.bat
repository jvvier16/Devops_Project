@echo off
REM Script simple para actualizar ECS sin PowerShell complications
REM Uso: update-ecs.bat

echo.
echo ========================================
echo   Actualizando servicio ECS
echo ========================================
echo.

REM Comando sin backslash (el \ estaba causando problemas)
aws ecs update-service --cluster devops-u2-cluster --service devops-u2-service --force-new-deployment --region us-east-1

if %ERRORLEVEL% EQU 0 (
    echo.
    echo [OK] Servicio actualizado correctamente
    echo [INFO] Esperando 5 segundos...
    timeout /t 5 /nobreak
    
    echo.
    echo [INFO] Estado del servicio:
    aws ecs describe-services --cluster devops-u2-cluster --services devops-u2-service --region us-east-1 --query "services[0].[serviceName,status,runningCount,desiredCount]" --output text
    
    echo.
    echo [OK] Actualización completada
) else (
    echo [ERROR] Fallo al actualizar el servicio
    exit /b 1
)

pause
