@echo off
REM Simple Minecraft Server Management Batch File

if "%1"=="" goto help
if "%1"=="help" goto help

if "%1"=="start" (
    echo [*] Starting Minecraft server...
    docker-compose up -d
    goto end
)

if "%1"=="stop" (
    echo [*] Stopping Minecraft server...
    docker-compose down
    goto end
)

if "%1"=="restart" (
    echo [*] Restarting Minecraft server...
    docker-compose restart
    goto end
)

if "%1"=="status" (
    echo [*] Server status:
    echo.
    docker-compose ps
    goto end
)

if "%1"=="logs" (
    echo [*] Viewing server logs (press Ctrl+C to exit)...
    docker-compose logs -f
    goto end
)

if "%1"=="update" (
    echo [*] Updating server images...
    docker-compose pull
    docker-compose up -d
    goto end
)

if "%1"=="rcon" (
    if "%2"=="" (
        echo [!] Usage: manage.bat rcon [command]
        goto end
    )
    echo [*] Executing RCON command: %2
    docker-compose exec minecraft rcon-cli %2
    goto end
)

echo [!] Unknown command: %1
goto help

:help
echo.
echo [*] Minecraft Server Management
echo ====================================
echo.
echo Available commands:
echo   start     - Start the server
echo   stop      - Stop the server
echo   restart   - Restart the server
echo   status    - Show server status
echo   logs      - View server logs
echo   update    - Update Docker images
echo   rcon      - Execute RCON command
echo.
echo Examples:
echo   manage.bat start
echo   manage.bat status
echo   manage.bat logs
echo   manage.bat rcon list
echo.
echo Web UI: http://localhost:8080
echo Minecraft: localhost:25565
echo.

:end
