@echo off
REM Minecraft Server Management Batch File for Windows
REM Common server management commands

echo 🎮 Minecraft Server Management
echo ==============================

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

if "%1"=="shell" (
    echo 🐚 Opening server shell...
    docker-compose exec minecraft bash
    goto :end
)

echo.
echo Available commands:
echo   start    - Start the server
echo   stop     - Stop the server
echo   restart  - Restart the server
echo   status   - Show server status
echo   logs     - View server logs
echo   backup   - Create a backup
echo   rcon     - Execute RCON command
echo   update   - Update server images
echo   shell    - Open server shell
echo.
echo Examples:
echo   manage.bat start
echo   manage.bat logs
echo   manage.bat rcon list
echo   manage.bat backup

:end
pause