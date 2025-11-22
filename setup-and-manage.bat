@echo off
setlocal enabledelayedexpansion

:MENU
cls
echo ========================================
echo  Minecraft Server Web UI Manager
echo ========================================
echo.
echo 1. Initial Setup
echo 2. Start Services
echo 3. Stop Services
echo 4. Restart Services
echo 5. View Logs
echo 6. Rebuild Web UI
echo 7. Update Configuration
echo 8. Check Status
echo 9. Exit
echo.
set /p choice="Select an option (1-9): "

if "%choice%"=="1" goto SETUP
if "%choice%"=="2" goto START
if "%choice%"=="3" goto STOP
if "%choice%"=="4" goto RESTART
if "%choice%"=="5" goto LOGS
if "%choice%"=="6" goto REBUILD
if "%choice%"=="7" goto CONFIG
if "%choice%"=="8" goto STATUS
if "%choice%"=="9" goto EXIT
goto MENU

:SETUP
cls
echo ========================================
echo  Initial Setup
echo ========================================
echo.

REM Check if .env exists
if exist ".env" (
    echo .env file already exists.
    set /p overwrite="Do you want to reconfigure? (y/n): "
    if /i not "!overwrite!"=="y" goto SETUP_DOCKER
)

REM Create .env file
echo Creating .env file...
(
echo # Environment Configuration for Minecraft Server Web UI
echo.
echo # RCON Configuration
echo RCON_PASSWORD=admin
echo.
echo # Web UI Security
echo WEBUI_SECRET_KEY=admin
echo.
echo # Server Configuration
echo SERVER_NAME=Involvex Minecraft Server
echo SERVER_VERSION=latest
) > .env

echo .env file created successfully!
echo.
echo IMPORTANT: Please edit .env and change the default passwords!
echo.
pause

:SETUP_DOCKER
echo.
echo Checking Docker...
docker --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Docker is not installed or not in PATH
    echo Please install Docker Desktop from https://www.docker.com/products/docker-desktop
    pause
    goto MENU
)

echo Docker is installed.
echo.
echo Pulling Docker images...
docker-compose pull

echo.
echo Setup complete!
echo.
echo Next steps:
echo 1. Edit .env file to set your passwords
echo 2. Select option 2 to start services
echo.
pause
goto MENU

:START
cls
echo ========================================
echo  Starting Services
echo ========================================
echo.
docker-compose up -d
echo.
echo Services started!
echo.
echo Web UI: http://localhost:8080
echo Minecraft Server: localhost:25565
echo.
pause
goto MENU

:STOP
cls
echo ========================================
echo  Stopping Services
echo ========================================
echo.
docker-compose stop
echo.
echo Services stopped.
echo.
pause
goto MENU

:RESTART
cls
echo ========================================
echo  Restarting Services
echo ========================================
echo.
docker-compose restart
echo.
echo Services restarted.
echo.
pause
goto MENU

:LOGS
cls
echo ========================================
echo  View Logs
echo ========================================
echo.
echo 1. Web UI Logs
echo 2. Minecraft Server Logs
echo 3. All Logs
echo 4. Back to Menu
echo.
set /p logchoice="Select log to view (1-4): "

if "%logchoice%"=="1" (
    echo.
    echo Showing Web UI logs (Ctrl+C to exit)...
    echo.
    docker-compose logs -f minecraft-webui
)
if "%logchoice%"=="2" (
    echo.
    echo Showing Minecraft Server logs (Ctrl+C to exit)...
    echo.
    docker-compose logs -f minecraft
)
if "%logchoice%"=="3" (
    echo.
    echo Showing all logs (Ctrl+C to exit)...
    echo.
    docker-compose logs -f
)
if "%logchoice%"=="4" goto MENU

goto MENU

:REBUILD
cls
echo ========================================
echo  Rebuild Web UI
echo ========================================
echo.
echo This will rebuild the Web UI container with latest changes.
echo.
set /p confirm="Continue? (y/n): "
if /i not "%confirm%"=="y" goto MENU

echo.
echo Stopping Web UI...
docker-compose stop minecraft-webui

echo.
echo Rebuilding Web UI (this may take a minute)...
docker-compose build --no-cache minecraft-webui

echo.
echo Starting services...
docker-compose up -d

echo.
echo Rebuild complete!
echo.
pause
goto MENU

:CONFIG
cls
echo ========================================
echo  Update Configuration
echo ========================================
echo.
echo 1. Edit .env file
echo 2. Edit server.properties
echo 3. Back to Menu
echo.
set /p configchoice="Select configuration to edit (1-3): "

if "%configchoice%"=="1" (
    if exist ".env" (
        notepad .env
        echo.
        echo Configuration updated. Restart services to apply changes.
        pause
    ) else (
        echo .env file not found. Run Initial Setup first.
        pause
    )
)
if "%configchoice%"=="2" (
    if exist "config\server.properties" (
        notepad config\server.properties
        echo.
        echo Configuration updated. Restart Minecraft server to apply changes.
        pause
    ) else (
        echo server.properties not found. Start the server first to generate it.
        pause
    )
)
if "%configchoice%"=="3" goto MENU

goto MENU

:STATUS
cls
echo ========================================
echo  Service Status
echo ========================================
echo.
docker-compose ps
echo.
echo.
echo Container Details:
echo.
docker ps --filter "name=minecraft" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo.
pause
goto MENU

:EXIT
echo.
echo Goodbye!
timeout /t 2 >nul
exit /b 0
