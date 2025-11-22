@echo off
REM Minecraft Server Management Batch File for Windows
REM Common server management commands

echo 🎮 Minecraft Server Management
echo ==============================

REM If no command provided or help requested, show help
if "%1"=="" goto :show_help
if "%1"=="help" goto :show_help

if "%1"=="start" (
    echo 🚀 Starting Minecraft server...
    docker-compose up -d
    echo ✅ Server started!
    goto :end
)

if "%1"=="stop" (
    echo ⏹️  Stopping Minecraft server...
    docker-compose down
    echo ✅ Server stopped!
    goto :end
)

if "%1"=="restart" (
    echo 🔄 Restarting Minecraft server...
    docker-compose restart
    echo ✅ Server restarted!
    goto :end
)

if "%1"=="status" (
    echo 📊 Server status:
    docker-compose ps
    goto :end
)

if "%1"=="logs" (
    echo 📋 Server logs (press Ctrl+C to exit):
    docker-compose logs -f
    goto :end
)

if "%1"=="backup" (
    echo 💾 Creating backup...
    if not exist "backups" mkdir backups
    set BACKUP_NAME=backup-%date:~-4,4%%date:~-10,2%%date:~-7,2%-%time:~0,2%%time:~3,2%%time:~6,2%
    set BACKUP_NAME=%BACKUP_NAME: =0%
    docker-compose exec minecraft tar -czf /backups/%BACKUP_NAME%.tar.gz /data
    echo ✅ Backup created: backups\%BACKUP_NAME%.tar.gz
    goto :end
)

if "%1"=="rcon" (
    if "%2"=="" (
        echo Usage: manage.bat rcon [command]
        echo Example: manage.bat rcon list
    ) else (
        echo 🔧 Executing RCON command: %2
        docker-compose exec minecraft rcon-cli %2
    )
    goto :end
)

if "%1"=="update" (
    echo 🔄 Updating server images...
    docker-compose pull
    echo 🚀 Recreating containers with new images...
    docker-compose up -d
    echo ✅ Update complete!
    goto :end
)

if "%1"=="rebuild" (
    echo 🔨 Rebuilding server images...
    docker-compose down
    docker-compose build --no-cache
    echo 🚀 Starting with rebuilt containers...
    docker-compose up -d
    echo ✅ Server rebuilt and started!
    goto :end
)

if "%1"=="shell" (
    echo 🐚 Opening server shell...
    docker-compose exec minecraft bash
    goto :end
)

echo Error: Unknown command '%1'
goto :show_help

:show_help
echo.
echo 📖 Available Commands:
echo.
echo   🍎 General Commands:
echo   help        - Show this help message
echo   status      - Show server status
echo   logs        - View server logs (follow mode)
echo.
echo   ⚡ Server Control:
echo   start       - Start the Minecraft server
echo   stop        - Stop the Minecraft server
echo   restart     - Restart the Minecraft server
echo.
echo   🛠️  Server Management:
echo   backup      - Create a backup of server data
echo   rcon        - Execute RCON command (usage: rcon [command])
echo   shell       - Open interactive shell in server container
echo.
echo   🔄 Container Management:
echo   update      - Update Docker images and recreate containers
echo   rebuild     - Rebuild Docker images from scratch
echo.
echo 💡 Examples:
echo   manage.bat start
echo   manage.bat logs
echo   manage.bat rcon list
echo   manage.bat rcon save-all
echo   manage.bat backup
echo   manage.bat update
echo   manage.bat help
echo.
echo 📂 Current directory: %CD%
echo 🔗 Web UI: http://localhost:8080
goto :end

:end
REM Only pause if no command was executed (to keep terminal open)
if "%1"=="" pause
