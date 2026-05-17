@echo off
REM Script para limpiar ECS antes de terraform destroy
REM Uso: cleanup-ecs.bat

setlocal enabledelayedexpansion

set CLUSTER=devops-u2-cluster
set SERVICE=devops-u2-service
set REGION=us-east-1

echo.
echo ==================================================
echo   Limpiando recursos ECS
echo ==================================================
echo.

REM 1. Eliminar servicio
echo [INFO] Eliminando servicio ECS: %SERVICE%...
aws ecs delete-service --cluster %CLUSTER% --service %SERVICE% --force --region %REGION% 2>nul

if %ERRORLEVEL% EQU 0 (
    echo [OK] Servicio marcado para eliminacion
) else (
    echo [WARN] El servicio podria no existir, continuando...
)

echo.
echo [INFO] Esperando 30 segundos a que se elimine el servicio...
timeout /t 30 /nobreak

echo.
echo [INFO] Deteniendo tareas activas...
for /f "tokens=*" %%A in ('aws ecs list-tasks --cluster %CLUSTER% --region %REGION% --query "taskArns[]" --output text 2^>nul') do (
    set TASK=%%A
    if not "!TASK!"=="" (
        echo   Deteniendo: !TASK!
        aws ecs stop-task --cluster %CLUSTER% --task !TASK! --region %REGION% 2>nul
    )
)

echo.
echo ==================================================
echo   [OK] Cleanup completado
echo   Ahora puedes ejecutar: terraform destroy
echo ==================================================
echo.

pause
