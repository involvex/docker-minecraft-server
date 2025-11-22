# Minecraft Server Management PowerShell Script
# Common server management commands

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "logs", "backup", "rcon", "update", "shell")]
    [string]$Command = "help"
)

function Show-Help {
    Write-Host "🎮 Minecraft Server Management" -ForegroundColor Green
    Write-Host "==============================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Available commands:" -ForegroundColor Yellow
    Write-Host "  start    - Start the server"
    Write-Host "  stop     - Stop the server"
    Write-Host "  restart  - Restart the server"
    Write-Host "  status   - Show server status"
    Write-Host "  logs     - View server logs (press Ctrl+C to exit)"
    Write-Host "  backup   - Create a backup"
    Write-Host "  rcon     - Execute RCON command"
    Write-Host "  update   - Update server images"
    Write-Host "  shell    - Open server shell"
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Cyan
    Write-Host "  .\manage.ps1 -Command start"
    Write-Host "  .\manage.ps1 -Command logs"
    Write-Host "  .\manage.ps1 -Command rcon -Argument 'list'"
}

switch ($Command) {
    "start" {
        Write-Host "🚀 Starting Minecraft server..." -ForegroundColor Blue
        docker-compose up -d
        Write-Host "✅ Server started!" -ForegroundColor Green
    }
    
    "stop" {
        Write-Host "⏹️  Stopping Minecraft server..." -ForegroundColor Blue
        docker-compose down
        Write-Host "✅ Server stopped!" -ForegroundColor Green
    }
    
    "restart" {
        Write-Host "🔄 Restarting Minecraft server..." -ForegroundColor Blue
        docker-compose restart
        Write-Host "✅ Server restarted!" -ForegroundColor Green
    }
    
    "status" {
        Write-Host "📊 Server status:" -ForegroundColor Blue
        docker-compose ps
    }
    
    "logs" {
        Write-Host "📋 Server logs (press Ctrl+C to exit):" -ForegroundColor Blue
        docker-compose logs -f
    }
    
    "backup" {
        Write-Host "💾 Creating backup..." -ForegroundColor Blue
        
        if (-not (Test-Path "backups")) {
            New-Item -ItemType Directory -Path "backups" -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $backupName = "backup-$timestamp.tar.gz"
        
        docker-compose exec minecraft tar -czf "/backups/$backupName" /data
        Write-Host "✅ Backup created: backups\$backupName" -ForegroundColor Green
    }
    
    "update" {
        Write-Host "🔄 Updating server images..." -ForegroundColor Blue
        docker-compose pull
        Write-Host "🚀 Recreating containers with new images..." -ForegroundColor Blue
        docker-compose up -d
        Write-Host "✅ Update complete!" -ForegroundColor Green
    }
    
    "shell" {
        Write-Host "🐚 Opening server shell..." -ForegroundColor Blue
        docker-compose exec minecraft bash
    }
    
    "rcon" {
        param([string]$Argument)
        
        if (-not $Argument) {
            Write-Host "Usage: .\manage.ps1 -Command rcon -Argument 'command'" -ForegroundColor Yellow
            Write-Host "Example: .\manage.ps1 -Command rcon -Argument 'list'" -ForegroundColor Cyan
        } else {
            Write-Host "🔧 Executing RCON command: $Argument" -ForegroundColor Blue
            docker-compose exec minecraft rcon-cli $Argument
        }
    }
    
    default {
        Show-Help
    }
}