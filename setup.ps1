# Minecraft Server Web UI - Quick Setup Script for Windows PowerShell
# This script helps you set up the Minecraft server with web management

# Set error action preference
$ErrorActionPreference = "Stop"

Write-Host "🎮 Minecraft Server Web UI Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green
Write-Host ""

# Check if Docker is installed
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker is installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed. Please install Docker first." -ForegroundColor Red
    Write-Host "Download from: https://docs.docker.com/desktop/windows/install/" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Check if Docker Compose is installed
try {
    $composeVersion = docker-compose --version
    Write-Host "✅ Docker Compose is installed: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose is not installed. Please install Docker Compose first." -ForegroundColor Red
    Write-Host "Docker Desktop usually includes it. If not, install separately." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

# Create directories if they don't exist
Write-Host "📁 Creating directory structure..." -ForegroundColor Blue
$directories = @("config\plugins", "config\plugin-configs", "logs", "backups")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        Write-Host "  Created directory: $dir" -ForegroundColor Gray
    }
}

# Copy environment file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "🔧 Creating environment configuration..." -ForegroundColor Blue
    Copy-Item "config\.env.example" ".env"
    Write-Host "✅ Created .env file from template" -ForegroundColor Green
    Write-Host "⚠️  Please edit .env file with your preferred settings before starting the server" -ForegroundColor Yellow
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

# Function to generate a random password
function Generate-RandomPassword {
    param([int]$Length = 32)
    $chars = "ABCDEFGHJKMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789"
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

# Generate secure passwords
Write-Host "🔐 Generating secure passwords..." -ForegroundColor Blue
$rconPassword = Generate-RandomPassword
$webuiSecret = Generate-RandomPassword

# Update .env file with secure passwords if not already set
if (Select-String -Path ".env" -Pattern "your_secure_rcon_password_here" -Quiet) {
    (Get-Content ".env") -replace "your_secure_rcon_password_here", $rconPassword | Set-Content ".env"
    Write-Host "✅ Updated RCON password" -ForegroundColor Green
}

if (Select-String -Path ".env" -Pattern "your_webui_secret_key_change_in_production" -Quiet) {
    (Get-Content ".env") -replace "your_webui_secret_key_change_in_production", $webuiSecret | Set-Content ".env"
    Write-Host "✅ Updated Web UI secret key" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review and edit configuration files:"
Write-Host "   - .env (environment variables)"
Write-Host "   - config\server.properties (server settings)"
Write-Host ""
Write-Host "2. Start the server:"
Write-Host "   docker-compose up -d"
Write-Host ""
Write-Host "3. Access the web interface:"
Write-Host "   http://localhost:8080"
Write-Host ""
Write-Host "4. Connect to Minecraft:"
Write-Host "   localhost:25565"
Write-Host ""
Write-Host "📖 For detailed documentation, see SETUP_GUIDE.md"
Write-Host ""
Write-Host "🔧 Useful commands:" -ForegroundColor Cyan
Write-Host "   docker-compose logs -f           # View logs"
Write-Host "   docker-compose down              # Stop server"
Write-Host "   docker-compose ps                # Check status"
Write-Host "   docker-compose exec minecraft rcon-cli list  # Test RCON"
Write-Host ""

# Offer to start the server
$startNow = Read-Host "🚀 Would you like to start the server now? (y/n)"
if ($startNow -match "^[Yy]$") {
    Write-Host "🚀 Starting Minecraft server..." -ForegroundColor Blue
    docker-compose up -d
    
    Write-Host ""
    Write-Host "⏳ Waiting for server to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host "📊 Server status:" -ForegroundColor Blue
    docker-compose ps
    
    Write-Host ""
    Write-Host "✅ Server is starting up!" -ForegroundColor Green
    Write-Host "🌐 Web interface: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "🎮 Minecraft server: localhost:25565" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 To view logs: docker-compose logs -f" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Happy mining! ⛏️" -ForegroundColor Green
Read-Host "Press Enter to exit"