# Minecraft Server Management

This document explains how to manage your Docker Minecraft server using the available management scripts.

## Available Management Scripts

### Windows Users

#### `manage.bat` (Recommended)

Comprehensive batch script with logging and error handling.

**Usage:**

```cmd
manage.bat start        # Start the server
manage.bat stop         # Stop the server
manage.bat restart      # Restart the server
manage.bat status       # Check server status
manage.bat logs         # View logs (press Ctrl+C to exit)
manage.bat backup       # Create backup
manage.bat rcon [cmd]   # Execute RCON command
manage.bat update       # Update Docker images
manage.bat shell        # Open server shell
manage.bat help         # Show all commands
```

**Features:**

- Detailed logging with timestamps
- Input sanitization for security
- Error handling with detailed messages
- Windows Task Scheduler integration for auto-start
- Multi-server support
- Health check functionality

#### `manage.ps1` (Alternative)

Simpler PowerShell script for basic operations.

**Usage:**

```powershell
.\manage.ps1 -Command start
.\manage.ps1 -Command stop
.\manage.ps1 -Command logs
.\manage.ps1 -Command rcon -Argument "list"
```

### Linux Users

#### `setup.sh`

Setup and management script for Linux systems.

**Usage:**

```bash
chmod +x setup.sh
./setup.sh start
./setup.sh stop
./setup.sh status
```

## Quick Start

1. **Initial Setup:**
   - Ensure Docker and Docker Compose are installed
   - Review and edit `.env` file with your settings
   - Run setup: `./setup.sh` (Linux) or use `manage.bat` (Windows)

2. **Start the Server:**

   ```bash
   # Windows
   manage.bat start

   # Linux
   ./setup.sh start
   ```

3. **Access the Server:**
   - Web UI: http://localhost:8080
   - Minecraft: localhost:25565

## Management Features

### Backup

- Automatic and manual backup creation
- Backups stored in `/backups` directory
- Compressed format (tar.gz)

### RCON Commands

- Execute Minecraft commands remotely
- Input sanitization for security
- Command logging and history

### Monitoring

- Real-time server status
- Player list monitoring
- Health checks for containers
- Log aggregation

### Updates

- Docker image updates
- Container recreation
- Zero-downtime deployments

## Configuration

### Environment Variables

Edit `.env` file to configure:

- `RCON_PASSWORD`: Server RCON password
- `WEBUI_SECRET_KEY`: Web UI security key
- `SERVER_NAME`: Server display name
- `SERVER_VERSION`: Minecraft version

### Server Properties

Modify `config/server.properties` for server settings:

- Game mode, difficulty, max players
- World settings, PvP configuration
- Network and security options

## Troubleshooting

### Common Issues

1. **Container Restarting:**
   - Check logs: `manage.bat logs`
   - Verify environment configuration
   - Ensure sufficient system resources

2. **RCON Connection Failed:**
   - Wait for server to fully start
   - Check RCON configuration in `.env`
   - Verify port 25575 is not blocked

3. **Web UI Not Accessible:**
   - Confirm container is running: `manage.bat status`
   - Check if port 8080 is available
   - Review web UI logs for errors

### Health Checks

Both Minecraft server and web UI have health checks:

- Server: RCON connection test (30s interval)
- Web UI: HTTP health endpoint (30s interval)

Containers will restart automatically if health checks fail.

## File Structure

```
docker-minecraft-server/
├── manage.bat              # Windows batch management
├── manage.ps1             # PowerShell management
├── setup.sh               # Linux setup script
├── docker-compose.yml     # Container orchestration
├── .env                   # Environment configuration
├── config/                # Server configuration
│   └── server.properties
├── logs/                  # Server logs
├── backups/              # Backup storage
└── webui/                # Web interface code
```

## Security Notes

- Change default passwords in `.env`
- Use strong passwords for RCON
- Restrict network access as needed
- Regular backup creation recommended
- Monitor logs for suspicious activity

## Support

For issues and support:

1. Check logs: `manage.bat logs`
2. Review configuration files
3. Consult server documentation
4. Check Docker container status
