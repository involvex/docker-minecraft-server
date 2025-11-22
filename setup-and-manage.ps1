# Minecraft Server Web UI - Setup and Management Script
# PowerShell Version

function Show-Menu {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Minecraft Server Web UI Manager" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Initial Setup"
    Write-Host "2. Start Services"
    Write-Host "3. Stop Services"
    Write-Host "4. Restart Services"
    Write-Host "5. View Logs"
    Write-Host "6. Rebuild Web UI"
    Write-Host "7. Update Configuration"
    Write-Host "8. Check Status"
    Write-Host "9. Exit"
    Write-Host ""
}

function Initialize-Setup {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Initial Setup" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Check if .env exists
    if (Test-Path ".env") {
        Write-Host ".env file already exists." -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to reconfigure? (y/n)"
        if ($overwrite -ne "y") {
            Initialize-Docker
            return
        }
    }
    
    # Create .env file
    Write-Host "Creating .env file..." -ForegroundColor Green
    @"
# Environment Configuration for Minecraft Server Web UI

# RCON Configuration
RCON_PASSWORD=admin

# Web UI Security
WEBUI_SECRET_KEY=admin

# Server Configuration
SERVER_NAME=Involvex Minecraft Server
SERVER_VERSION=latest
"@ | Out-File -FilePath ".env" -Encoding UTF8
    
    Write-Host ".env file created successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "IMPORTANT: Please edit .env and change the default passwords!" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to continue"
    
    Initialize-Docker
}

function Initialize-Docker {
    Write-Host ""
    Write-Host "Checking Docker..." -ForegroundColor Green
    
    try {
        docker --version | Out-Null
        Write-Host "Docker is installed." -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Docker is not installed or not in PATH" -ForegroundColor Red
        Write-Host "Please install Docker Desktop from https://www.docker.com/products/docker-desktop" -ForegroundColor Yellow
        Read-Host "Press Enter to continue"
        return
    }
    
    Write-Host ""
    Write-Host "Pulling Docker images..." -ForegroundColor Green
    docker-compose pull
    
    Write-Host ""
    Write-Host "Setup complete!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Cyan
    Write-Host "1. Edit .env file to set your passwords"
    Write-Host "2. Select option 2 to start services"
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Start-Services {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Starting Services" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    docker-compose up -d
    
    Write-Host ""
    Write-Host "Services started!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Web UI: http://localhost:8080" -ForegroundColor Cyan
    Write-Host "Minecraft Server: localhost:25565" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Stop-Services {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Stopping Services" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    docker-compose stop
    
    Write-Host ""
    Write-Host "Services stopped." -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Restart-Services {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Restarting Services" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    docker-compose restart
    
    Write-Host ""
    Write-Host "Services restarted." -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Show-Logs {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " View Logs" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Web UI Logs"
    Write-Host "2. Minecraft Server Logs"
    Write-Host "3. All Logs"
    Write-Host "4. Back to Menu"
    Write-Host ""
    
    $logChoice = Read-Host "Select log to view (1-4)"
    
    switch ($logChoice) {
        "1" {
            Write-Host ""
            Write-Host "Showing Web UI logs (Ctrl+C to exit)..." -ForegroundColor Green
            Write-Host ""
            docker-compose logs -f minecraft-webui
        }
        "2" {
            Write-Host ""
            Write-Host "Showing Minecraft Server logs (Ctrl+C to exit)..." -ForegroundColor Green
            Write-Host ""
            docker-compose logs -f minecraft
        }
        "3" {
            Write-Host ""
            Write-Host "Showing all logs (Ctrl+C to exit)..." -ForegroundColor Green
            Write-Host ""
            docker-compose logs -f
        }
    }
}

function Rebuild-WebUI {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Rebuild Web UI" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This will rebuild the Web UI container with latest changes." -ForegroundColor Yellow
    Write-Host ""
    
    $confirm = Read-Host "Continue? (y/n)"
    if ($confirm -ne "y") { return }
    
    Write-Host ""
    Write-Host "Stopping Web UI..." -ForegroundColor Green
    docker-compose stop minecraft-webui
    
    Write-Host ""
    Write-Host "Rebuilding Web UI (this may take a minute)..." -ForegroundColor Green
    docker-compose build --no-cache minecraft-webui
    
    Write-Host ""
    Write-Host "Starting services..." -ForegroundColor Green
    docker-compose up -d
    
    Write-Host ""
    Write-Host "Rebuild complete!" -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to continue"
}

function Update-Configuration {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Update Configuration" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1. Edit .env file"
    Write-Host "2. Edit server.properties"
    Write-Host "3. Back to Menu"
    Write-Host ""
    
    $configChoice = Read-Host "Select configuration to edit (1-3)"
    
    switch ($configChoice) {
        "1" {
            if (Test-Path ".env") {
                notepad .env
                Write-Host ""
                Write-Host "Configuration updated. Restart services to apply changes." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            else {
                Write-Host ".env file not found. Run Initial Setup first." -ForegroundColor Red
                Read-Host "Press Enter to continue"
            }
        }
        "2" {
            if (Test-Path "config\server.properties") {
                notepad config\server.properties
                Write-Host ""
                Write-Host "Configuration updated. Restart Minecraft server to apply changes." -ForegroundColor Yellow
                Read-Host "Press Enter to continue"
            }
            else {
                Write-Host "server.properties not found. Start the server first to generate it." -ForegroundColor Red
                Read-Host "Press Enter to continue"
            }
        }
    }
}

function Show-Status {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Service Status" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    docker-compose ps
    
    Write-Host ""
    Write-Host ""
    Write-Host "Container Details:" -ForegroundColor Cyan
    Write-Host ""
    docker ps --filter "name=minecraft" --format "table {{.Names}}`t{{.Status}}`t{{.Ports}}"
    
    Write-Host ""
    Read-Host "Press Enter to continue"
}

# Main loop
do {
    Show-Menu
    $choice = Read-Host "Select an option (1-9)"
    
    switch ($choice) {
        "1" { Initialize-Setup }
        "2" { Start-Services }
        "3" { Stop-Services }
        "4" { Restart-Services }
        "5" { Show-Logs }
        "6" { Rebuild-WebUI }
        "7" { Update-Configuration }
        "8" { Show-Status }
        "9" {
            Write-Host ""
            Write-Host "Goodbye!" -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            exit
        }
    }
} while ($true)
