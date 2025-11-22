# Minecraft Server with Web Management UI

🎮 **Complete Minecraft server setup with modern web-based administration interface**

## 📦 Version 2.1.0 - Major Bug Fixes & Improvements

**Latest Release:** November 22, 2025

### 🐛 **Critical Fixes in v2.1.0**

- ✅ **FIXED**: WebUI constant restarting issue (containers now run stably)
- ✅ **FIXED**: PowerShell encoding problems with Unicode characters  
- ✅ **FIXED**: manage.bat script output suppression
- ✅ **CLEANED**: Removed 5 duplicate management scripts
- ✅ **UPDATED**: All documentation to reflect current file structure

### 🚀 **What's New**

- **Simplified Management**: Streamlined batch scripts with clean ASCII output
- **Better Documentation**: Updated all setup guides with correct file references  
- **Enhanced Stability**: Improved health checks and service dependencies
- **Cross-Platform**: Works reliably in both PowerShell and Command Prompt

This project provides a production-ready Minecraft server with a comprehensive web management system, built using Docker and modern web technologies.

## ✨ Features

### 🔧 **Server Management**

- **Easy Configuration**: Edit server settings through web interface or config files
- **Plugin Management**: Upload, install, and manage plugins seamlessly
- **Real-time Monitoring**: Live server status, player count, and system resources
- **Backup System**: Automated and manual backup capabilities

### 🌐 **Web Interface**

- **Modern Dashboard**: Real-time server overview with system metrics
- **Console Access**: Execute RCON commands directly from the browser
- **Live Logs**: Stream server logs in real-time with filtering
- **Player Management**: OP, De-OP, Ban, Unban, and Kick players
- **Ban List**: View and manage banned players
- **Configuration Editor**: Edit server.properties through the web UI
- **Dark Mode**: Toggle between light and dark themes (preference saved)

### 🔒 **Security & Reliability**

- **RCON Integration**: Secure remote command execution
- **Environment-based Configuration**: Easy environment variable management
- **Network Isolation**: Docker network for secure container communication
- **Health Monitoring**: Automatic service health checks and restart policies

## ⚙️ Management Commands

Once your server is set up, use these commands to manage it:

### Available Commands

- `manage.bat help` - Show all available commands
- `manage.bat start` - Start the Minecraft server
- `manage.bat stop` - Stop the Minecraft server
- `manage.bat restart` - Restart the Minecraft server
- `manage.bat status` - Show server status
- `manage.bat logs` - View live server logs
- `manage.bat backup` - Create server data backup
- `manage.bat rcon [command]` - Execute RCON command
- `manage.bat update` - Update Docker images
- `manage.bat rebuild` - Rebuild Docker images from scratch
- `manage.bat shell` - Open server container shell

### Examples

```cmd
# Get help (also shown if no command provided)
manage.bat help

# Start the server
manage.bat start

# View live logs
manage.bat logs

# Execute commands
manage.bat rcon list
manage.bat rcon save-all
manage.bat rcon op playername

# Create backup
manage.bat backup

# Update server
manage.bat update
```

## 🚀 Quick Start

### One-Command Setup (Windows)

**PowerShell:**

```powershell
# Clone and setup the repository
git clone https://github.com/involvex/docker-minecraft-server.git
cd docker-minecraft-server
.\setup.ps1
```

**Command Prompt:**

```cmd
REM Clone the repository
git clone https://github.com/involvex/docker-minecraft-server.git
cd docker-minecraft-server

REM Run setup
setup.bat

REM Start the server
manage.bat start
```

### Manual Setup

**Windows:**

```cmd
# Clone the repository
git clone https://github.com/involvex/docker-minecraft-server.git
cd docker-minecraft-server

# Run the setup script
setup.bat
# or
.\setup.ps1

# Manage the server (see all commands)
manage.bat help
manage.bat start
manage.bat logs
manage.bat rcon list
# or
.\manage.ps1 -Command help
.\manage.ps1 -Command start
.\manage.ps1 -Command logs
```

**Linux/macOS:**

```bash
# Clone the repository
git clone https://github.com/involvex/docker-minecraft-server.git
cd docker-minecraft-server

# Run the setup script
./setup.sh

# Manage the server
./manage.sh start
```

## 📊 Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Browser   │◄──►│  Web UI Flask   │◄──►│   RCON Client   │
│   (Port 8080)   │    │  (Port 8080)    │    │  (Port 25575)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                                ▼
                       ┌─────────────────┐
                       │ Minecraft Server│
                       │  (Port 25565)   │
                       └─────────────────┘
```

## 📁 Project Structure

```
/
├── docker-compose.yml          # Main service orchestration
├── setup.bat                   # Windows batch setup script
├── setup.ps1                   # Windows PowerShell setup script
├── setup.sh                    # Linux/macOS bash setup script
├── manage.bat                  # Windows batch management script
├── manage.ps1                  # Windows PowerShell management script
├── SETUP_GUIDE.md             # Comprehensive documentation
├── README.md                  # This file
├── MANAGEMENT.md              # Management commands documentation
├── .env                       # Environment configuration (auto-generated)
├── config/
│   ├── server.properties      # Server configuration template
│   ├── plugins/              # Plugin JAR files directory
│   └── plugin-configs/       # Plugin configurations
├── webui/
│   ├── app.py               # Flask web application
│   ├── requirements.txt     # Python dependencies
│   ├── Dockerfile          # Web UI container definition
│   └── templates/          # HTML templates
└── logs/                   # Server logs mount point
```

## 🔧 Configuration

### Environment Variables (.env)

```bash
RCON_PASSWORD=your_secure_password    # Change this!
WEBUI_SECRET_KEY=your_secret_key      # Change this!
SERVER_NAME=My Minecraft Server
MAX_MEMORY=4G
MAX_PLAYERS=20
```

### Server Properties

```properties
server-name=My Minecraft Server
motd=Welcome to our server!
max-players=20
gamemode=survival
difficulty=normal
pvp=true
enable-rcon=true
rcon.port=25575
rcon.password=your_secure_password
```

## 🌟 Web Interface Highlights

### Dashboard

- **Real-time Server Status**: Live monitoring with status indicators
- **System Metrics**: CPU, memory, and disk usage visualization
- **Quick Actions**: One-click common commands (save, weather, time)
- **Player Overview**: Current online players with management options

### Console

- **Live Command Execution**: Send RCON commands with instant results
- **Command History**: Track all executed commands with timestamps
- **Real-time Output**: WebSocket-powered live log streaming
- **Error Handling**: Clear error messages and troubleshooting

### Configuration Management

- **server.properties Editor**: Full syntax highlighting and validation
- **Live Updates**: Changes apply immediately without restart
- **Backup Protection**: Automatic backup before modifications
- **Environment Integration**: Edit environment variables through UI

### Plugin Management

- **Plugin Repository**: List all installed plugins
- **Upload Interface**: Add new plugins via web upload
- **Status Monitoring**: Check plugin loading and error states
- **Configuration**: Direct access to plugin configuration files

## 🔍 Monitoring & Logs

### Real-time Monitoring

- **Server Status**: Online/offline with uptime tracking
- **Player Activity**: Connection/disconnection notifications
- **Resource Usage**: System resource monitoring
- **Performance Metrics**: Tick rate and performance tracking

### Log Management

- **Live Streaming**: Real-time log feed through WebSocket
- **Log Search**: Filter by date, level, player, or content
- **Export Functionality**: Download logs for external analysis
- **Alert System**: Notifications for critical events

## 🛠️ Troubleshooting

### Common Issues

**Server won't start:**

```bash
docker-compose logs minecraft
# Check port availability and configuration
```

**Web UI not accessible:**

```bash
docker-compose logs minecraft-webui
# Verify port mapping and network connectivity
```

**RCON connection failed:**

```bash
docker-compose exec minecraft rcon-cli -a localhost -p 25575 list
# Check RCON configuration and password
```

### Debug Commands

```bash
# View all logs
docker-compose logs -f

# Check service status
docker-compose ps

# Execute commands in containers
docker-compose exec minecraft bash
docker-compose exec minecraft-webui bash

# Test RCON connectivity
docker-compose exec minecraft rcon-cli list
```

## 📈 Performance Optimization

### Recommended Settings

- **Memory**: 4GB minimum, 8GB recommended
- **CPU**: 2+ cores for smooth operation
- **Storage**: SSD recommended for world data
- **Network**: Stable internet connection for players

### Tuning Options

```bash
# Performance environment variables
VIEW_DISTANCE=15
SIMULATION_DISTANCE=15
MAX_BUILD_HEIGHT=256
MAX_TICK_TIME=60000
```

## 🔄 Maintenance

### Regular Tasks

1. **Daily**: Check server logs and player activity
2. **Weekly**: Update plugins and monitor performance
3. **Monthly**: Full backup and security review
4. **Quarterly**: System updates and optimization

### Backup Strategy

```bash
# Manual backup
docker-compose exec minecraft tar -czf /backups/backup-$(date +%Y%m%d).tar.gz /data

# Automated backup (add to crontab)
0 2 * * * docker-compose exec minecraft /usr/bin/backup.sh
```

## 🎯 API Reference

### Endpoints

- `GET /api/status` - Server status and player count
- `GET /api/players` - Online and historical player data
- `GET /api/logs` - Server logs with filtering
- `POST /api/command` - Execute RCON commands
- `GET /api/config` - Get server configuration
- `POST /api/config` - Update server configuration
- `GET /api/plugins` - List installed plugins

### WebSocket Events

- `status_update` - Real-time server status changes
- `player_update` - Player connection/disconnection
- `command_output` - Command execution results
- `log_data` - Live log streaming

## 🤝 Supporting the Project

### 💖 Support Our Work

This project is maintained by the community, for the community. Your support helps us continue development, maintain infrastructure, and add new features to make Minecraft server management even better.

### ☕ Funding Options

**Buy Me a Coffee:**  
Fuel our development with a coffee! Every cup helps us code longer and build better features.

[![Buy Me a Coffee](https://www.buymeacoffee.com/assets/img/button-80x15.png)](https://www.buymeacoffee.com/involvex)

**GitHub Sponsors:**  
Sponsor our work on GitHub and get recognized as a supporter of open source Minecraft tools.

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-4285F4?style=for-the-badge&logo=github&logoColor=white)](https://github.com/sponsors/involvex)

### 🌟 Other Ways to Help

- **🐛 Report Bugs**: Help us identify and fix issues
- **💻 Contribute Code**: Submit pull requests for new features or improvements
- **📖 Improve Documentation**: Help make our guides clearer and more comprehensive
- **🆘 Help Others**: Support fellow users in issues and discussions
- **⭐ Star the Project**: Show your appreciation by starring our repository

## 🤝 Contributing

This project provides a complete foundation for Minecraft server management. The web UI is built with modern technologies and can be extended with additional features:

- **Authentication System**: Add user accounts and permissions
- **Advanced Monitoring**: Charts and analytics dashboard
- **Plugin Store**: Integrated plugin marketplace
- **Multi-server Support**: Manage multiple Minecraft servers
- **Mobile App**: React Native or Flutter mobile interface

## 📄 License

This project is open source and available under the MIT License.

## 🎮 Happy Mining!

Your Minecraft server is now equipped with a professional-grade web management interface. Enjoy the convenience of managing your server from anywhere with a web browser!

**Quick Links:**

- 🌐 **Web Interface**: http://localhost:8080
- 🎮 **Minecraft Server**: localhost:25565
- 📖 **Full Documentation**: SETUP_GUIDE.md
