@echo off
setlocal EnableDelayedExpansion

:: Minecraft Server Web UI - Batch Setup Script
:: This script helps you set up the Minecraft server with web management

echo 🎮 Minecraft Server Web UI Setup
echo =================================

:: Check if Docker is installed
docker --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker is not installed. Please install Docker first.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('docker --version') do set DOCKER_VERSION=%%i
echo ✅ Docker is installed: !DOCKER_VERSION!

:: Check if Docker Compose is installed
docker-compose --version >nul 2>&1
if errorlevel 1 (
    echo ❌ Docker Compose is not installed. Please install Docker Compose first.
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('docker-compose --version') do set COMPOSE_VERSION=%%i
echo ✅ Docker Compose is installed: !COMPOSE_VERSION!

echo 📁 Creating directory structure...

if not exist "config\plugins" mkdir "config\plugins"
if not exist "config\plugin-configs" mkdir "config\plugin-configs"
if not exist "logs" mkdir "logs"
if not exist "backups" mkdir "backups"

:: Copy environment file if it doesn't exist
if not exist ".env" (
    echo 🔧 Creating environment configuration...
    if exist "config\.env.example" (
        copy "config\.env.example" ".env" >nul
        echo ✅ Created .env file from template
        echo ⚠️  Please edit .env file with your preferred settings before starting the server
    ) else (
        :: Create a basic .env file
        (
            echo # Minecraft Server Configuration
            echo RCON_PASSWORD=your_secure_rcon_password_here
            echo WEBUI_SECRET_KEY=your_webui_secret_key_change_in_production
            echo SERVER_NAME=Minecraft Server
            echo MAX_MEMORY=4G
            echo MAX_PLAYERS=20
        ) > .env
        echo ✅ Created basic .env file
        echo ⚠️  Please edit .env file with your preferred settings before starting the server
    )
) else (
    echo ✅ .env file already exists
)

:: Generate secure passwords using PowerShell
echo 🔐 Generating secure passwords...

for /f %%i in ('powershell -Command "[System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))"') do set RCON_PASSWORD=%%i
for /f %%i in ('powershell -Command "[System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))"') do set WEBUI_SECRET=%%i

:: Update .env file with secure passwords if placeholder exists
findstr /c:"your_secure_rcon_password_here" .env >nul
if not errorlevel 1 (
    powershell -Command "(Get-Content .env) -replace 'your_secure_rcon_password_here', '%RCON_PASSWORD%' | Set-Content .env"
    echo ✅ Updated RCON password
)

findstr /c:"your_webui_secret_key_change_in_production" .env >nul
if not errorlevel 1 (
    powershell -Command "(Get-Content .env) -replace 'your_webui_secret_key_change_in_production', '%WEBUI_SECRET%' | Set-Content .env"
    echo ✅ Updated Web UI secret key
)

:: Create sample server.properties if it doesn't exist
if not exist "config\server.properties" (
    echo 📝 Creating sample server.properties...
    (
        echo # Minecraft Server Properties
        echo server-name=Minecraft Server
        echo motd=Welcome to our Minecraft server!
        echo max-players=20
        echo gamemode=survival
        echo difficulty=normal
        echo pvp=true
        echo enable-rcon=true
        echo rcon.port=25575
        echo rcon.password=%RCON_PASSWORD%
    ) > config\server.properties
    echo ✅ Created server.properties file
)

echo.
echo 🎉 Setup Complete!
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
echo    docker-compose exec minecraft rcon-cli list  # Test RCON
echo.

:: Offer to start the server
set /p RESPONSE="🚀 Would you like to start the server now? (y/n): "
if /i "!RESPONSE!"=="y" (
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