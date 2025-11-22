# Minecraft Server Web UI - PowerShell Setup Script
# This script helps you set up the Minecraft server with web management

Write-Host "🎮 Minecraft Server Web UI Setup" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Green

# Check if Docker is installed
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker is installed: $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed. Please install Docker first." -ForegroundColor Red
    exit 1
}

# Check if Docker Compose is installed
try {
    $composeVersion = docker-compose --version
    Write-Host "✅ Docker Compose is installed: $composeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker Compose is not installed. Please install Docker Compose first." -ForegroundColor Red
    exit 1
}

Write-Host "📁 Creating directory structure..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path "config\plugins" | Out-Null
New-Item -ItemType Directory -Force -Path "config\plugin-configs" | Out-Null
New-Item -ItemType Directory -Force -Path "logs" | Out-Null
New-Item -ItemType Directory -Force -Path "backups" | Out-Null

# Copy environment file if it doesn't exist
if (-not (Test-Path ".env")) {
    Write-Host "🔧 Creating environment configuration..." -ForegroundColor Yellow
    if (Test-Path "config\.env.example") {
        Copy-Item "config\.env.example" ".env"
        Write-Host "✅ Created .env file from template" -ForegroundColor Green
        Write-Host "⚠️  Please edit .env file with your preferred settings before starting the server" -ForegroundColor Yellow
    } else {
        # Create a basic .env file
        $envContent = @"
# Minecraft Server Configuration
RCON_PASSWORD=your_secure_rcon_password_here
WEBUI_SECRET_KEY=your_webui_secret_key_change_in_production
SERVER_NAME=Minecraft Server
MAX_MEMORY=4G
MAX_PLAYERS=20
"@
        $envContent | Out-File -FilePath ".env" -Encoding UTF8
        Write-Host "✅ Created basic .env file" -ForegroundColor Green
        Write-Host "⚠️  Please edit .env file with your preferred settings before starting the server" -ForegroundColor Yellow
    }
} else {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
}

# Generate secure passwords
Write-Host "🔐 Generating secure passwords..." -ForegroundColor Yellow
$randomBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
$rconPassword = [Convert]::ToBase64String($randomBytes)
$randomBytes = [System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32)
$webuiSecret = [Convert]::ToBase64String($randomBytes)

# Update .env file with secure passwords if placeholder exists
$envContent = Get-Content ".env" -Raw
if ($envContent -match "your_secure_rcon_password_here") {
    $envContent = $envContent -replace "your_secure_rcon_password_here", $rconPassword
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ Updated RCON password" -ForegroundColor Green
}

if ($envContent -match "your_webui_secret_key_change_in_production") {
    $envContent = $envContent -replace "your_webui_secret_key_change_in_production", $webuiSecret
    $envContent | Out-File -FilePath ".env" -Encoding UTF8
    Write-Host "✅ Updated Web UI secret key" -ForegroundColor Green
}

# Create sample server.properties if it doesn't exist
if (-not (Test-Path "config\server.properties")) {
    Write-Host "📝 Creating sample server.properties..." -ForegroundColor Yellow
    $serverProps = @"
# Minecraft Server Properties
server-name=Minecraft Server
motd=Welcome to our Minecraft server!
max-players=20
gamemode=survival
difficulty=normal
pvp=true
enable-rcon=true
rcon.port=25575
rcon.password=$rconPassword
"@
    $serverProps | Out-File -FilePath "config\server.properties" -Encoding UTF8
    Write-Host "✅ Created server.properties file" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review and edit configuration files:" -ForegroundColor White
Write-Host "   - .env (environment variables)" -ForegroundColor Gray
Write-Host "   - config\server.properties (server settings)" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Start the server:" -ForegroundColor White
Write-Host "   docker-compose up -d" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Access the web interface:" -ForegroundColor White
Write-Host "   http://localhost:8080" -ForegroundColor Gray
Write-Host ""
Write-Host "4. Connect to Minecraft:" -ForegroundColor White
Write-Host "   localhost:25565" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 For detailed documentation, see SETUP_GUIDE.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔧 Useful commands:" -ForegroundColor Cyan
Write-Host "   docker-compose logs -f           # View logs" -ForegroundColor White
Write-Host "   docker-compose down              # Stop server" -ForegroundColor White
Write-Host "   docker-compose ps                # Check status" -ForegroundColor White
Write-Host "   docker-compose exec minecraft rcon-cli list  # Test RCON" -ForegroundColor White
Write-Host ""

# Offer to start the server
$response = Read-Host "🚀 Would you like to start the server now? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host "🚀 Starting Minecraft server..." -ForegroundColor Green
    docker-compose up -d
    
    Write-Host ""
    Write-Host "⏳ Waiting for server to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    Write-Host "📊 Server status:" -ForegroundColor Cyan
    docker-compose ps
    
    Write-Host ""
    Write-Host "✅ Server is starting up!" -ForegroundColor Green
    Write-Host "🌐 Web interface: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "🎮 Minecraft server: localhost:25565" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "📋 To view logs: docker-compose logs -f" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Happy mining! ⛏️" -ForegroundColor Green