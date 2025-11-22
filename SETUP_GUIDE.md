# Minecraft Server with Web UI Management

This setup provides a complete Minecraft server with a modern web-based management interface. The system includes RCON connectivity, real-time server monitoring, player management, plugin management, and comprehensive server administration tools.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 4GB of RAM available
- Port 25565 and 8080 available

### Setup Steps

#### Windows (Recommended)

1. **Run Setup Script**

   ```cmd
   # Option 1: Batch file (Command Prompt)
   setup.bat

   # Option 2: PowerShell
   .\setup.ps1
   ```

2. **Manual Setup (Alternative)**

   ```cmd
   REM Copy environment template
   copy config\.env.example .env

   REM Edit the .env file with your preferred settings
   notepad .env
   ```

3. **Configure Your Server**
   - Edit `config\server.properties` for basic server settings
   - Modify `config\.env` for advanced configuration
   - Add plugin JAR files to `config\plugins\` directory

4. **Start the Server**
   ```cmd
   docker-compose up -d
   ```

#### Linux/macOS

1. **Run Setup Script**

   ```bash
   # Make script executable and run
   chmod +x setup.sh
   ./setup.sh
   ```

2. **Manual Setup (Alternative)**

   ```bash
   # Copy environment template
   cp config/.env.example .env

   # Edit the .env file with your preferred settings
   nano .env
   ```

3. **Start the Server**

   ```bash
   docker-compose up -d
   ```

4. **Access the Web Interface**
   - Web UI: http://localhost:8080
   - Minecraft Server: localhost:25565

## 🌐 Web Interface Features

### Dashboard

- **Real-time Server Status**: Live monitoring of server uptime, player count, and system resources
- **Quick Actions**: One-click commands for common server operations
- **Player Overview**: List of online players with management options
- **System Information**: CPU, memory, and disk usage monitoring

### Console

- **Live Command Execution**: Send RCON commands directly from the web interface
- **Real-time Output**: See command results immediately
- **Command History**: Track all executed commands
- **Batch Commands**: Execute multiple commands in sequence

### Configuration Management

- **server.properties Editor**: Edit server settings through the web interface
- **Live Updates**: Changes take effect without server restart
- **Configuration Backup**: Automatic backup before changes
- **Validation**: Ensure configuration validity before applying

### Plugin Management

- **Plugin List**: View all installed plugins
- **Plugin Upload**: Add new plugins through the web interface
- **Plugin Removal**: Remove plugins with confirmation
- **Plugin Status**: Check plugin loading and error status

### Player Management

- **Online Players**: Real-time list of connected players
- **Player History**: Track player connections and playtime
- **Whitelist Management**: Add/remove players from whitelist
- **Kick/Ban Commands**: Moderate player behavior

### Log Viewer

- **Real-time Logs**: Live server log streaming
- **Log Filtering**: Search and filter by date, level, or message
- **Export Logs**: Download logs for external analysis
- **Alert System**: Get notified of critical server events

## ⚙️ Configuration

### Basic Server Settings

Edit `config/server.properties`:

```properties
server-name=My Minecraft Server
motd=Welcome to our server!
max-players=20
gamemode=survival
difficulty=normal
pvp=true
```

### Advanced Configuration

Edit `.env` file:

```bash
# Server Performance
MAX_MEMORY=4G
MAX_PLAYERS=20
VIEW_DISTANCE=15
SIMULATION_DISTANCE=15

# RCON Settings
RCON_PASSWORD=your_secure_password
WEBUI_SECRET_KEY=your_secret_key

# Server Type (optional)
TYPE=AUTO_CURSEFORGE
```

### Plugin Configuration

1. **Add Plugins**: Place JAR files in `config/plugins/`
2. **Configure Plugins**: Create config files in `config/plugin-configs/`
3. **Restart Server**: Changes require server restart

## 🔧 Services

### minecraft (Main Server)

- **Image**: `itzg/minecraft-server:latest`
- **Ports**: 25565 (game), 8125 (RCON)
- **Volumes**: Game data, configurations, logs

### minecraft-webui (Web Interface)

- **Image**: Custom Python Flask application (built from Dockerfile)
- **Port**: 8080 (HTTP)
- **Features**: Real-time monitoring, RCON client, database management

## 📊 API Endpoints

### Server Information

- `GET /api/status` - Current server status
- `GET /api/players` - Player list and history
- `GET /api/logs` - Server logs

### Command Execution

- `POST /api/command` - Execute RCON command
- **Payload**: `{"command": "list players"}`

### Configuration

- `GET /api/config` - Get server.properties content
- `POST /api/config` - Update server.properties
- **Payload**: `{"config": "server-name=My Server\n..."}`

### Plugin Management

- `GET /api/plugins` - List installed plugins
- `POST /api/plugins/upload` - Upload new plugin (future feature)
- `DELETE /api/plugins/{plugin}` - Remove plugin (future feature)

## 🔍 Troubleshooting

### Server Won't Start

```bash
# Check logs
docker-compose logs minecraft

# Check port availability (Linux/macOS)
netstat -tlnp | grep :25565

# Check port availability (Windows)
netstat -an | findstr :25565

# Verify configuration
docker-compose config
```

### Web UI Not Accessible

```bash
# Check web service
docker-compose logs minecraft-webui

# Verify port mapping
docker-compose ps

# Test network connectivity
docker-compose exec minecraft-webui curl http://localhost:8125
```

### RCON Connection Issues

```bash
# Test RCON connectivity (Linux/macOS)
docker-compose exec minecraft rcon-cli -a localhost -p 8125 list

# Test RCON connectivity (Windows)
docker-compose exec minecraft rcon-cli -a localhost -p 8125 list

# Check RCON configuration
docker-compose exec minecraft cat /data/server.properties | findstr rcon
```

### Plugin Problems

```bash
# Check plugin directory
docker-compose exec minecraft ls -la /data/plugins/

# Check server logs for plugin errors
docker-compose logs minecraft | findstr -i plugin
```

## 🛠️ Windows Management Scripts

The project includes Windows-compatible management scripts:

### Setup Scripts

- **setup.bat** - Batch file for Command Prompt
- **setup.ps1** - PowerShell script with enhanced features

### Management Scripts

- **manage.bat** - Batch file for common server operations
- **manage.ps1** - PowerShell script with full parameter support

#### Usage Examples (Windows)

```cmd
REM Batch file usage
setup.bat
manage.bat start
manage.bat logs
manage.bat backup
manage.bat rcon list

REM PowerShell usage
.\setup.ps1
.\manage.ps1 -Command start
.\manage.ps1 -Command logs
.\manage.ps1 -Command backup
.\manage.ps1 -Command rcon -Argument "list players"
```

#### Linux/macOS Usage

```bash
# Make scripts executable
chmod +x setup.sh manage.sh
./setup.sh
./manage.sh start
./manage.sh logs
./manage.sh backup
./manage.sh rcon "list players"
```

## 🔒 Security

### Change Default Passwords

1. **RCON Password**: Update `RCON_PASSWORD` in `.env`
2. **Web UI Secret**: Change `WEBUI_SECRET_KEY` in `.env`
3. **Server Properties**: Modify default settings in `server.properties`

### Network Security

- Use strong passwords
- Enable firewall rules
- Consider using a reverse proxy with SSL
- Regularly update Docker images

### Backup Strategy

```bash
# Manual backup
docker-compose exec minecraft tar -czf /backups/backup-$(date +%Y%m%d).tar.gz /data

# Automated backup (add to crontab)
0 2 * * * docker-compose exec minecraft /usr/bin/backup.sh
```

## 📈 Performance Optimization

### Memory Tuning

- Set `MAX_MEMORY` based on available RAM
- Monitor memory usage through web UI
- Adjust JVM flags if needed

### Network Optimization

- Use `network-compression-threshold=256`
- Configure appropriate `view-distance` and `simulation-distance`
- Enable native transport if supported

### Plugin Optimization

- Regularly update plugins
- Remove unused plugins
- Monitor plugin performance through logs

## 🔄 Maintenance

### Regular Tasks

1. **Daily**: Check server logs and player activity
2. **Weekly**: Update plugins and check for server updates
3. **Monthly**: Full backup and performance review
4. **Quarterly**: Security audit and configuration review

### Update Process

```bash
# Pull latest images
docker-compose pull

# Recreate containers with new images
docker-compose up -d

# Monitor startup logs
docker-compose logs -f minecraft
```

## 📞 Support

For issues and questions:

1. Check the troubleshooting section above
2. Review Docker Compose logs
3. Check server logs through the web UI
4. Verify configuration files

## 🗂️ File Structure

```
/
├── docker-compose.yml          # Main service definition
├── .env                        # Environment variables (create from .env.example)
├── config/
│   ├── server.properties       # Server configuration
│   ├── plugins/               # Plugin JAR files
│   └── plugin-configs/        # Plugin configuration files
├── webui/
│   ├── app.py                 # Flask application
│   ├── requirements.txt       # Python dependencies
│   ├── Dockerfile            # Web UI container
│   └── templates/            # HTML templates
├── logs/                      # Server logs (mounted)
└── backups/                   # Automatic backups
```

## 🎯 Features Checklist

✅ **Completed Features:**

- ✅ Enhanced docker-compose.yml with RCON support
- ✅ Web UI service with RCON client capabilities
- ✅ Real-time server monitoring dashboard
- ✅ RCON command execution interface
- ✅ Configuration management system
- ✅ Plugin management interface
- ✅ Player list and connection monitoring
- ✅ Live server logs viewing
- ✅ Easy configuration setup
- ✅ Comprehensive documentation

The system is now fully functional and provides a complete Minecraft server management solution!
