@echo off
REM Minecraft Server Web UI - Quick Setup Script for Windows
REM This script helps you set up the Minecraft server with web management

setlocal enabledelayedexpansion

echo 🎮 Minecraft Server Web UI Setup
echo ================================

REM Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker first.
    echo Download from: https://docs.docker.com/desktop/windows/install/
    pause
    exit /b 1
)

REM Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not installed. Please install Docker Compose first.
    echo Docker Desktop usually includes it. If not, install separately.
    pause
    exit /b 1
)

echo ✅ Docker and Docker Compose are installed

REM Create directories if they don't exist
echo 📁 Creating directory structure...
if not exist "config\plugins" mkdir config\plugins
if not exist "config\plugin-configs" mkdir config\plugin-configs
if not exist "logs" mkdir logs
if not exist "backups" mkdir backups

REM Copy environment file if it doesn't exist
if not exist ".env" (
    echo 🔧 Creating environment configuration...
    copy config\.env.example .env
    echo ✅ Created .env file from template
    echo ⚠️  Please edit .env file with your preferred settings before starting the server
) else (
    echo ✅ .env file already exists
)

echo.
echo 🔐 Setup completed successfully!
echo.
echo Next steps:
echo 1. Review and edit configuration files:
echo    - .env (environment variables)
echo    - config\server.properties (server settings)
echo.
echo 2. Start the server:
echo    docker-compose up -d
echo.
echo 3. Access the web interface:
echo    http://localhost:8080
echo.
echo 4. Connect to Minecraft:
echo    localhost:25565
echo.
echo 📖 For detailed documentation, see SETUP_GUIDE.md
echo.
echo 🔧 Useful commands:
echo    docker-compose logs -f           # View logs
echo    docker-compose down              # Stop server
echo    docker-compose ps                # Check status

REM Ask if user wants to start the server
set /p start_now="🚀 Would you like to start the server now? (y/n): "
if /i "%start_now%"=="y" (
    echo 🚀 Starting Minecraft server...
    docker-compose up -d
    
    echo.
    echo ⏳ Waiting for server to start...
    timeout /t 10 /nobreak >nul
    
    echo 📊 Server status:
    docker-compose ps
    
    echo.
    echo ✅ Server is starting up!
    echo 🌐 Web interface: http://localhost:8080
    echo 🎮 Minecraft server: localhost:25565
    echo.
    echo 📋 To view logs: docker-compose logs -f
)

echo.
echo Happy mining! ⛏️
pause