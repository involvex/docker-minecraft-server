# Minecraft Server Web UI

A modern, feature-rich web interface for managing your Minecraft server with RCON support.

## Features

### 🎮 Server Management

- **Real-time Status Monitoring** - View server status, player count, and uptime
- **RCON Console** - Execute commands directly from the web interface
- **Player Management** - OP, De-OP, Ban, Unban, and Kick players
- **Ban List** - View and manage banned players
- **Configuration Editor** - Edit server.properties directly from the web UI

### 🎨 User Interface

- **Dark Mode** - Toggle between light and dark themes (preference saved)
- **Responsive Design** - Works on desktop, tablet, and mobile
- **Real-time Updates** - WebSocket-based live updates
- **Quick Actions** - One-click commands for common tasks

### 🔧 Technical Features

- **RCON Integration** - Secure remote console access
- **Status Caching** - Reduced server load with intelligent caching
- **Error Handling** - Comprehensive error messages and logging
- **Docker-based** - Easy deployment with Docker Compose

## Quick Start

### One-Command Setup (Windows)

**PowerShell:**

```powershell
iwr -useb https://raw.githubusercontent.com/involvex/docker-minecraft-server/master/setup-and-manage.ps1 | iex
```

**Command Prompt:**

```cmd
curl -o setup-and-manage.bat https://raw.githubusercontent.com/involvex/docker-minecraft-server/master/setup-and-manage.bat && setup-and-manage.bat
```

### Manual Setup

1. **Clone or download this repository**

   ```bash
   git clone https://github.com/involvex/docker-minecraft-server.git
   cd docker-minecraft-server
   ```

2. **Configure environment variables**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and set:
   - `RCON_PASSWORD` - Your RCON password (default: admin)
   - `WEBUI_SECRET_KEY` - Secret key for web UI sessions

3. **Start the services**

   ```bash
   docker-compose up -d
   ```

4. **Access the Web UI**
   - Open http://localhost:8080 in your browser
   - The Minecraft server will be available on port 25565

## Configuration

### Environment Variables

#### Required Variables

| Variable           | Description                     | Default |
| ------------------ | ------------------------------- | ------- |
| `RCON_PASSWORD`    | RCON password for server access | `admin` |
| `WEBUI_SECRET_KEY` | Secret key for web UI           | `admin` |

**Note:** CurseForge plugin search now uses the public servermods API and does not require authentication. Spiget and GitHub searches also work without API keys.

#### Server Configuration Variables

| Variable      | Description                  | Default                     |
| ------------- | ---------------------------- | --------------------------- |
| `RCON_PORT`   | RCON port                    | `25575`                     |
| `SERVER_NAME` | Display name for your server | `Involvex Minecraft Server` |
| `MAX_MEMORY`  | Maximum memory allocation    | `4G`                        |
| `MAX_PLAYERS` | Maximum player count         | `20`                        |

### RCON Setup

The web UI communicates with the Minecraft server via RCON. Ensure these settings match:

**In `.env`:**

```env
RCON_PASSWORD=your_secure_password
```

**In `config/server.properties`:**

```properties
enable-rcon=true
rcon.port=25575
rcon.password=your_secure_password
```

## Usage

### Dashboard

- View real-time server status
- See online players
- Monitor system resources
- Quick action buttons for common commands

### Console

- Execute any Minecraft command
- View command history
- Real-time command output

### Player Management

- **OP** - Grant operator permissions
- **De-OP** - Remove operator permissions
- **Ban** - Ban player with optional reason
- **Kick** - Kick player from server
- **Unban** - Remove player from ban list

### Configuration

- Edit server.properties directly
- Changes are saved immediately
- Restart server to apply changes

### Ban List

- View all banned players
- Unban players with one click
- See ban reasons (if provided)

## Troubleshooting

### Web UI shows "Checking..." status

- Ensure RCON is enabled in server.properties
- Verify RCON password matches in both .env and server.properties
- Check that RCON port (25575) is not blocked
- Rebuild the web UI container: `docker-compose build --no-cache minecraft-webui`

### Configuration shows blank

- The server.properties file may not exist yet
- Wait for the Minecraft server to fully start
- Check `/api/debug/files` endpoint for file location details
- Verify volume mounts in docker-compose.yml

### RCON connection spam in logs

- This has been fixed with status caching
- Ensure you're running the latest version
- Rebuild containers if needed

### Players not showing

- This is normal if no players are online
- Player list updates every 30 seconds
- Check RCON connection is working

### Plugin search not working

- Check your internet connection
- Try a different search query
- The API may be temporarily unavailable
- All plugin search providers (Spiget, CurseForge, GitHub) work without requiring API keys

## Management Scripts

### rebuild-webui.bat

Rebuilds and restarts the web UI container:

```bash
rebuild-webui.bat
```

### setup-and-manage.bat

Combined setup and management script:

```bash
setup-and-manage.bat
```

Options:

1. Initial Setup
2. Start Services
3. Stop Services
4. Restart Services
5. View Logs
6. Rebuild Web UI
7. Update Configuration

## Architecture

```
┌─────────────────┐         ┌──────────────────┐
│   Web Browser   │◄───────►│  Web UI (Flask)  │
└─────────────────┘         └──────────────────┘
                                     │
                                     │ RCON
                                     ▼
                            ┌──────────────────┐
                            │ Minecraft Server │
                            └──────────────────┘
```

### Components

- **Web UI** - Flask application with Socket.IO for real-time updates
- **RCON Client** - Python rcon library for server communication
- **Database** - SQLite for storing logs and player data
- **Docker** - Containerized deployment

### Ports

- **8080** - Web UI HTTP
- **25565** - Minecraft server
- **25575** - RCON (internal only)

## Development

### Project Structure

```
.
├── webui/
│   ├── app.py              # Main Flask application
│   ├── Dockerfile          # Web UI container
│   ├── requirements.txt    # Python dependencies
│   └── templates/
│       ├── base.html       # Base template with dark mode
│       └── dashboard.html  # Dashboard page
├── config/
│   └── server.properties   # Minecraft server config
├── docker-compose.yml      # Service definitions
├── .env                    # Environment variables
└── README-WEBUI.md        # This file
```

### Building from Source

1. Make changes to webui/app.py or templates
2. Rebuild the container:
   ```bash
   docker-compose build --no-cache minecraft-webui
   ```
3. Restart services:
   ```bash
   docker-compose up -d
   ```

## Security

### Best Practices

1. **Change default passwords** - Update RCON_PASSWORD and WEBUI_SECRET_KEY
2. **Use strong passwords** - At least 16 characters, mixed case, numbers, symbols
3. **Restrict access** - Use firewall rules to limit web UI access
4. **HTTPS** - Use a reverse proxy (nginx, Caddy) for HTTPS
5. **Regular updates** - Keep Docker images updated

### Recommended nginx Configuration

```nginx
server {
    listen 443 ssl;
    server_name minecraft.yourdomain.com;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see LICENSE file for details.

## Support

- **Issues**: https://github.com/involvex/docker-minecraft-server/issues
- **Discussions**: https://github.com/involvex/docker-minecraft-server/discussions
- **Wiki**: https://github.com/involvex/docker-minecraft-server/wiki

## Changelog

### Version 1.0.0 (2025-11-22)

- Initial release
- RCON integration
- Player management (OP, Ban, Kick)
- Dark mode support
- Real-time status updates
- Configuration editor
- Ban list management

## Credits

- Built with [Flask](https://flask.palletsprojects.com/)
- Uses [itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server) Docker image
- RCON library: [rcon](https://pypi.org/project/rcon/)
- UI Framework: [Bootstrap 5](https://getbootstrap.com/)
- Icons: [Font Awesome](https://fontawesome.com/)
