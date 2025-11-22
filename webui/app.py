#!/usr/bin/env python3
import os
import json
import sqlite3
import logging
from datetime import datetime
from threading import Thread
import time

from flask import Flask, render_template, request, jsonify, session, redirect, url_for
from flask_socketio import SocketIO, emit
from rcon.source import Client
import requests
import psutil

app = Flask(__name__)
app.config['SECRET_KEY'] = os.environ.get('WEBUI_SECRET_KEY', 'change_this_secret')
socketio = SocketIO(app, cors_allowed_origins="*", async_mode='eventlet', logger=False, engineio_logger=False)

# RCON Configuration
RCON_HOST = os.environ.get('RCON_HOST', 'localhost')
RCON_PORT = int(os.environ.get('RCON_PORT', '8125'))
RCON_PASSWORD = os.environ.get('RCON_PASSWORD', 'minecraft_rcon_password')

# Status cache to reduce RCON connections
status_cache = {
    'data': None,
    'timestamp': None,
    'cache_duration': 10  # Cache for 10 seconds
}

# Database setup
DB_PATH = os.environ.get('DB_PATH', '/app/data/webui.db')
os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

def init_database():
    """Initialize the SQLite database"""
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    
    # Create tables for logs, commands, and player history
    c.execute('''CREATE TABLE IF NOT EXISTS logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        level TEXT,
        message TEXT,
        player TEXT,
        command TEXT
    )''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS commands (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        command TEXT,
        result TEXT,
        user TEXT
    )''')
    
    c.execute('''CREATE TABLE IF NOT EXISTS players (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        first_seen TEXT,
        last_seen TEXT,
        total_playtime INTEGER DEFAULT 0,
        is_online BOOLEAN DEFAULT 0
    )''')
    
    conn.commit()
    conn.close()

def get_rcon_client():
    """Create and return an RCON client with timeout - DEPRECATED, use context manager instead"""
    try:
        return Client(RCON_HOST, RCON_PORT, passwd=RCON_PASSWORD, timeout=5)
    except Exception as e:
        logging.error(f"Failed to connect to RCON: {e}")
        return None

def execute_rcon_command(command):
    """Execute a command via RCON and log it"""
    try:
        with Client(RCON_HOST, RCON_PORT, passwd=RCON_PASSWORD, timeout=5) as client:
            result = client.run(command)
            
            # Log the command
            conn = sqlite3.connect(DB_PATH)
            c = conn.cursor()
            c.execute("INSERT INTO commands (timestamp, command, result, user) VALUES (?, ?, ?, ?)",
                     (datetime.now().isoformat(), command, str(result), "webui"))
            conn.commit()
            conn.close()
            
            return str(result), True
    except Exception as e:
        logging.error(f"RCON command error: {e}")
        return f"Error: {e}", False

def get_simple_server_status():
    """Simple status check - just check if minecraft container is running"""
    try:
        import subprocess
        import json
        
        # Check if minecraft container is running
        result = subprocess.run([
            'docker', 'ps', '--filter', 'name=minecraft-server', '--format', '{{.Status}}'
        ], capture_output=True, text=True, timeout=10)
        
        if result.returncode == 0 and result.stdout.strip():
            status = result.stdout.strip()
            if "Up" in status:
                return {
                    'status': 'online',
                    'player_count': 'Unknown',
                    'online_players': [],
                    'motd': 'Minecraft Server (Container Running)',
                    'version': '1.21.10',
                    'last_updated': datetime.now().isoformat(),
                    'note': 'Container is running, RCON connection may not be ready yet'
                }
        
        return {
            'status': 'offline',
            'player_count': 0,
            'online_players': [],
            'motd': 'Server Container Not Running',
            'version': 'Unknown',
            'last_updated': datetime.now().isoformat()
        }
    except Exception as e:
        logging.error(f"Error checking simple server status: {e}")
        return {
            'status': 'unknown',
            'player_count': 0,
            'online_players': [],
            'motd': 'Status Check Failed',
            'version': 'Unknown',
            'last_updated': datetime.now().isoformat(),
            'error': str(e)
        }

def get_server_status():
    """Get current server status with caching to reduce RCON connections"""
    # Check if we have a recent cached status
    if status_cache['data'] and status_cache['timestamp']:
        age = (datetime.now() - status_cache['timestamp']).total_seconds()
        if age < status_cache['cache_duration']:
            return status_cache['data']
    
    # First try RCON connection
    try:
        # Try to get RCON info with shorter timeout
        with Client(RCON_HOST, RCON_PORT, passwd=RCON_PASSWORD, timeout=5) as client:
            # Test connection first
            result = client.run("list")
            logging.info(f"RCON list result: {result}")  # Debug logging
            
            # Parse player count from "There are X of a max of Y players online:"
            player_count = "0"
            online_players = []
            
            try:
                # Expected format: "There are 0 of a max of 20 players online:" or "There are 1 of a max of 20 players online: PlayerName"
                if "There are" in result and "of a max of" in result:
                    # Extract the number between "There are" and "of a max of"
                    parts = result.split("There are")[1].split("of a max of")
                    player_count = parts[0].strip()
                    
                    # Get player names if any (after the colon)
                    if ": " in result:
                        player_names = result.split(": ")[-1].strip()
                        if player_names and player_names != "":
                            online_players = [p.strip() for p in player_names.split(",") if p.strip()]
                else:
                    # Fallback parsing
                    if ": " in result:
                        player_info = result.split(": ")[-1].strip()
                        if player_info:
                            online_players = [p.strip() for p in player_info.split(",") if p.strip()]
                            player_count = str(len(online_players))
            except Exception as parse_error:
                logging.error(f"Error parsing player list: {parse_error}")
                player_count = "0"
                online_players = []
            
            # Get MOTD from list command or use default
            motd = "Minecraft Server (Online)"
            
            status_data = {
                'status': 'online',
                'player_count': player_count,
                'online_players': online_players,
                'motd': motd,
                'version': '1.21.10',
                'last_updated': datetime.now().isoformat()
            }
            
            # Update cache
            status_cache['data'] = status_data
            status_cache['timestamp'] = datetime.now()
            
            return status_data
                
    except Exception as e:
        logging.warning(f"RCON connection failed: {e}")
    
    # Fallback to simple container status check
    fallback_status = get_simple_server_status()
    
    # Cache the fallback status too
    status_cache['data'] = fallback_status
    status_cache['timestamp'] = datetime.now()
    
    return fallback_status

@app.route('/')
def index():
    """Main dashboard"""
    status = get_server_status()
    
    # Get server configuration from environment and server.properties
    config = {
        'SERVER_NAME': os.environ.get('SERVER_NAME', 'Minecraft Server'),
        'SERVER_VERSION': os.environ.get('SERVER_VERSION', 'latest'),
    }
    
    # Try to read server name from server.properties
    try:
        possible_paths = ['/data/server.properties', '/config/server.properties']
        for path in possible_paths:
            if os.path.exists(path):
                with open(path, 'r') as f:
                    for line in f:
                        if line.startswith('server-name='):
                            config['SERVER_NAME'] = line.split('=', 1)[1].strip()
                            break
                        elif line.startswith('motd='):
                            config['MOTD'] = line.split('=', 1)[1].strip()
                break
    except Exception as e:
        logging.warning(f"Could not read server.properties: {e}")
    
    return render_template('dashboard.html', status=status, config=config)

@app.route('/api/health')
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'timestamp': datetime.now().isoformat(),
        'version': '1.0.0'
    })

@app.route('/api/status')
def api_status():
    """API endpoint for server status"""
    try:
        status = get_server_status()
        return jsonify(status), 200
    except Exception as e:
        logging.error(f"Error in api_status: {e}")
        return jsonify({
            'status': 'error',
            'player_count': 0,
            'online_players': [],
            'motd': 'Error retrieving status',
            'version': 'Unknown',
            'last_updated': datetime.now().isoformat(),
            'error': str(e)
        }), 500

@app.route('/api/players')
def api_players():
    """Get list of players"""
    try:
        with Client(RCON_HOST, RCON_PORT, passwd=RCON_PASSWORD, timeout=5) as client:
            list_result = client.run("list")
            player_list = []
            if ": " in list_result:
                player_count = list_result.split(": ")[-1].split(", ")
                if player_list == [""]:
                    player_list = []
            
            # Get player details from database
            conn = sqlite3.connect(DB_PATH)
            c = conn.cursor()
            c.execute("SELECT username, last_seen, total_playtime FROM players")
            players_db = c.fetchall()
            conn.close()
            
            return jsonify({
                'online': get_server_status()['online_players'],
                'all': [{'username': p[0], 'last_seen': p[1], 'total_playtime': p[2]} for p in players_db]
            })
    except Exception as e:
        logging.error(f"Error getting players: {e}")
    
    return jsonify({'online': [], 'all': []})

@app.route('/api/command', methods=['POST'])
def api_command():
    """Execute a command via RCON"""
    data = request.get_json()
    command = data.get('command', '')
    
    if not command:
        return jsonify({'error': 'No command provided'}), 400
    
    result, success = execute_rcon_command(command)
    
    # Emit to all connected clients
    socketio.emit('command_output', {
        'command': command,
        'result': result,
        'success': success,
        'timestamp': datetime.now().isoformat()
    })
    
    return jsonify({'result': result, 'success': success})

@app.route('/api/logs')
def api_logs():
    """Get server logs"""
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute("SELECT timestamp, level, message, player, command FROM logs ORDER BY timestamp DESC LIMIT 100")
        logs = c.fetchall()
        conn.close()
        
        return jsonify([{
            'timestamp': log[0],
            'level': log[1],
            'message': log[2],
            'player': log[3],
            'command': log[4]
        } for log in logs])
    except Exception as e:
        logging.error(f"Error getting logs: {e}")
        return jsonify([])

@app.route('/api/debug/files')
def debug_files():
    """Debug endpoint to see what files are available"""
    try:
        import os
        debug_info = {
            'cwd': os.getcwd(),
            'data_exists': os.path.exists('/data'),
            'config_exists': os.path.exists('/config'),
            'data_contents': [],
            'config_contents': [],
            'data_root_files': []
        }
        
        if os.path.exists('/data'):
            try:
                debug_info['data_contents'] = os.listdir('/data')
                # Check for server.properties specifically
                sp_path = '/data/server.properties'
                debug_info['server_properties_exists'] = os.path.exists(sp_path)
                if os.path.exists(sp_path):
                    debug_info['server_properties_size'] = os.path.getsize(sp_path)
                    debug_info['server_properties_readable'] = os.access(sp_path, os.R_OK)
            except Exception as e:
                debug_info['data_error'] = str(e)
        
        if os.path.exists('/config'):
            try:
                debug_info['config_contents'] = os.listdir('/config')
            except Exception as e:
                debug_info['config_error'] = str(e)
        
        # Check current directory
        try:
            debug_info['data_root_files'] = os.listdir('.')
        except Exception as e:
            debug_info['root_error'] = str(e)
            
        return jsonify(debug_info)
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/config', methods=['GET', 'POST'])
def api_config():
    """Manage server configuration"""
    # Try multiple possible paths for server.properties
    possible_paths = [
        '/data/server.properties',
        '/config/server.properties',
        './server.properties'
    ]
    
    config_file = None
    for path in possible_paths:
        if os.path.exists(path):
            config_file = path
            break
    
    if request.method == 'GET':
        try:
            if not config_file:
                # List what's in /data to help debug
                data_contents = []
                if os.path.exists('/data'):
                    data_contents = os.listdir('/data')
                
                logging.warning(f"Config file not found. Checked: {possible_paths}")
                logging.warning(f"/data contents: {data_contents}")
                
                return jsonify({
                    'error': 'Configuration file not found',
                    'checked_paths': possible_paths,
                    'data_dir_contents': data_contents
                }), 404
            
            with open(config_file, 'r') as f:
                config = f.read()
            return jsonify({'config': config, 'path': config_file})
        except Exception as e:
            logging.error(f"Error reading config: {e}")
            return jsonify({'error': str(e)}), 500
    
    elif request.method == 'POST':
        try:
            if not config_file:
                return jsonify({'error': 'Configuration file not found'}), 404
                
            data = request.get_json()
            config_content = data.get('config', '')
            
            with open(config_file, 'w') as f:
                f.write(config_content)
            
            return jsonify({'success': True})
        except Exception as e:
            logging.error(f"Error writing config: {e}")
            return jsonify({'error': str(e)}), 500

@app.route('/api/worlds', methods=['GET'])
def api_worlds():
    """List available worlds"""
    try:
        worlds_dir = '/data/worlds'
        worlds = []
        
        # Check if worlds directory exists
        if not os.path.exists(worlds_dir):
            return jsonify({'worlds': [], 'current_world': 'world'})
        
        # List world directories
        for item in os.listdir(worlds_dir):
            world_path = os.path.join(worlds_dir, item)
            if os.path.isdir(world_path):
                # Check if it looks like a world directory (has level.dat or region files)
                has_level_dat = os.path.exists(os.path.join(world_path, 'level.dat'))
                has_region_dir = os.path.exists(os.path.join(world_path, 'region'))
                
                if has_level_dat or has_region_dir:
                    # Calculate world size
                    total_size = 0
                    file_count = 0
                    for root, dirs, files in os.walk(world_path):
                        for file in files:
                            try:
                                file_path = os.path.join(root, file)
                                total_size += os.path.getsize(file_path)
                                file_count += 1
                            except (OSError, IOError):
                                continue
                    
                    worlds.append({
                        'name': item,
                        'size': total_size,
                        'file_count': file_count,
                        'path': world_path
                    })
        
        # Get current world (try multiple methods)
        current_world = 'world'  # default
        try:
            with Client(RCON_HOST, RCON_PORT, passwd=RCON_PASSWORD, timeout=5) as client:
                result = client.run("save query")
                if "world" in result:
                    current_world = "world"
        except:
            pass  # RCON not available
        
        return jsonify({
            'worlds': sorted(worlds, key=lambda x: x['name']),
            'current_world': current_world
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/worlds/<world_name>/backup', methods=['POST'])
def api_backup_world(world_name):
    """Create a backup of a world"""
    try:
        import shutil
        from datetime import datetime
        
        worlds_dir = '/data/worlds'
        backup_dir = '/data/backups'
        
        world_path = os.path.join(worlds_dir, world_name)
        if not os.path.exists(world_path):
            return jsonify({'error': 'World not found'}), 404
        
        os.makedirs(backup_dir, exist_ok=True)
        
        # Create backup with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_name = f"{world_name}_{timestamp}"
        backup_path = os.path.join(backup_dir, backup_name)
        
        # Create compressed backup (zip)
        backup_file = f"{backup_path}.zip"
        shutil.make_archive(backup_path, 'zip', world_path)
        
        return jsonify({
            'success': True,
            'message': f'World {world_name} backed up successfully',
            'backup_file': f"{backup_name}.zip",
            'backup_path': backup_file
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/worlds/backups', methods=['GET'])
def api_list_backups():
    """List available world backups"""
    try:
        backup_dir = '/data/backups'
        backups = []
        
        if os.path.exists(backup_dir):
            for file in os.listdir(backup_dir):
                if file.endswith('.zip'):
                    file_path = os.path.join(backup_dir, file)
                    file_size = os.path.getsize(file_path)
                    modified_time = datetime.fromtimestamp(os.path.getmtime(file_path))
                    
                    # Extract world name and timestamp from filename
                    parts = file.replace('.zip', '').split('_')
                    if len(parts) >= 2:
                        world_name = '_'.join(parts[:-1])
                        timestamp = parts[-1]
                        if len(timestamp) == 14:  # YYYYMMDD_HHMMSS
                            formatted_time = f"{timestamp[:4]}-{timestamp[4:6]}-{timestamp[6:8]} {timestamp[9:11]}:{timestamp[11:13]}:{timestamp[13:15]}"
                        else:
                            formatted_time = modified_time.isoformat()
                    else:
                        world_name = 'unknown'
                        formatted_time = modified_time.isoformat()
                    
                    backups.append({
                        'name': file,
                        'world': world_name,
                        'size': file_size,
                        'created': formatted_time,
                        'path': file_path
                    })
        
        return jsonify({
            'backups': sorted(backups, key=lambda x: x['created'], reverse=True)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/worlds/<world_name>/restore', methods=['POST'])
def api_restore_world(world_name):
    """Restore a world from backup"""
    try:
        import shutil
        import zipfile
        
        data = request.get_json()
        backup_file = data.get('backup_file')
        
        if not backup_file:
            return jsonify({'error': 'Backup file is required'}), 400
        
        worlds_dir = '/data/worlds'
        backup_dir = '/data/backups'
        backup_path = os.path.join(backup_dir, backup_file)
        
        if not os.path.exists(backup_path):
            return jsonify({'error': 'Backup file not found'}), 404
        
        # Remove existing world directory if it exists
        world_path = os.path.join(worlds_dir, world_name)
        if os.path.exists(world_path):
            shutil.rmtree(world_path)
        
        # Extract backup
        with zipfile.ZipFile(backup_path, 'r') as zip_ref:
            zip_ref.extractall(worlds_dir)
        
        return jsonify({
            'success': True,
            'message': f'World {world_name} restored from backup {backup_file}'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/worlds/<world_name>/switch', methods=['POST'])
def api_switch_world(world_name):
    """Switch to a different world"""
    try:
        worlds_dir = '/data/worlds'
        world_path = os.path.join(worlds_dir, world_name)
        
        if not os.path.exists(world_path):
            return jsonify({'error': 'World not found'}), 404
        
        # Update server.properties to point to the new world
        server_props_path = None
        for path in ['/data/server.properties', '/config/server.properties']:
            if os.path.exists(path):
                server_props_path = path
                break
        
        if not server_props_path:
            return jsonify({'error': 'server.properties not found'}), 404
        
        # Read current server.properties
        with open(server_props_path, 'r') as f:
            lines = f.readlines()
        
        # Update or add level-name property
        found_level_name = False
        for i, line in enumerate(lines):
            if line.startswith('level-name='):
                lines[i] = f'level-name={world_name}\n'
                found_level_name = True
                break
        
        # Add level-name property if it doesn't exist
        if not found_level_name:
            lines.append(f'level-name={world_name}\n')
        
        # Write updated server.properties
        with open(server_props_path, 'w') as f:
            f.writelines(lines)
        
        return jsonify({
            'success': True,
            'message': f'Switched to world {world_name}. Server restart may be required.',
            'world': world_name
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/plugins', methods=['GET'])
def api_plugins():
    """List installed plugins"""
    try:
        plugins_dir = '/data/plugins'
        plugins = []
        if os.path.exists(plugins_dir):
            for plugin in os.listdir(plugins_dir):
                if plugin.endswith('.jar'):
                    plugin_path = os.path.join(plugins_dir, plugin)
                    file_size = os.path.getsize(plugin_path)
                    modified_time = datetime.fromtimestamp(os.path.getmtime(plugin_path)).isoformat()
                    plugins.append({
                        'name': plugin,
                        'size': file_size,
                        'modified': modified_time,
                        'enabled': True  # Plugin is considered enabled if file exists
                    })
        return jsonify({'plugins': plugins})
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/plugins/upload', methods=['POST'])
def api_upload_plugin():
    """Upload a new plugin"""
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400
        
        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400
        
        if not file.filename.endswith('.jar'):
            return jsonify({'error': 'Only .jar files are allowed'}), 400
        
        plugins_dir = '/data/plugins'
        os.makedirs(plugins_dir, exist_ok=True)
        
        # Save the plugin
        plugin_path = os.path.join(plugins_dir, file.filename)
        file.save(plugin_path)
        
        return jsonify({
            'success': True,
            'message': f'Plugin {file.filename} uploaded successfully',
            'plugin': file.filename
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/plugins/<plugin_name>', methods=['DELETE'])
def api_remove_plugin(plugin_name):
    """Remove a plugin"""
    try:
        plugins_dir = '/data/plugins'
        plugin_path = os.path.join(plugins_dir, plugin_name)
        
        if not os.path.exists(plugin_path):
            return jsonify({'error': 'Plugin not found'}), 404
        
        # Check if it's actually a .jar file and in the plugins directory
        if not plugin_name.endswith('.jar') or not os.path.abspath(plugin_path).startswith(os.path.abspath(plugins_dir)):
            return jsonify({'error': 'Invalid plugin file'}), 400
        
        os.remove(plugin_path)
        
        return jsonify({
            'success': True,
            'message': f'Plugin {plugin_name} removed successfully'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/plugins/search/bukkit', methods=['GET'])
def api_search_bukkit_plugins():
    """Search for plugins on Spiget (Bukkit/Spigot)"""
    try:
        query = request.args.get('q', '')
        page = request.args.get('page', '1')

        if not query:
            return jsonify({'plugins': []})

        # Search Spiget API
        url = f'https://api.spiget.org/v2/search/resources/{query}'
        params = {
            'size': '20',
            'page': page,
            'fields': 'id,name,description,version,tag,external'
        }

        response = requests.get(url, params=params, timeout=10)

        if response.status_code == 200:
            plugins = response.json()
            # Filter for plugins only (not resources)
            plugin_list = []
            for plugin in plugins:
                if 'external' not in plugin or plugin.get('external', False) == False:
                    plugin_list.append({
                        'id': plugin.get('id'),
                        'name': plugin.get('name'),
                        'description': plugin.get('description', '')[:200] + '...' if len(plugin.get('description', '')) > 200 else plugin.get('description', ''),
                        'version': plugin.get('version', 'Unknown'),
                        'tag': plugin.get('tag', ''),
                        'source': 'spiget'
                    })
            return jsonify({'plugins': plugin_list})
        else:
            return jsonify({'plugins': []})
    except Exception as e:
        return jsonify({'error': str(e), 'plugins': []}), 500

@app.route('/api/plugins/search/bukkitdev', methods=['GET'])
def api_search_bukkitdev_plugins():
    """Search for plugins on dev.bukkit.org"""
    try:
        query = request.args.get('q', '')

        if not query:
            return jsonify({'plugins': []})

        # Search dev.bukkit.org (BukkitDev/Bukkit plugin repository)
        url = 'https://dev.bukkit.org/search'
        params = {
            'search': query,
            'section': 'projects'  # Focus on projects/plugins
        }

        response = requests.get(url, params=params, timeout=15)
        response.raise_for_status()

        # Parse HTML results (simple approach - extract plugin info)
        from bs4 import BeautifulSoup
        soup = BeautifulSoup(response.text, 'html.parser')

        plugins = []
        # Find plugin listings in search results
        project_listings = soup.find_all('div', class_='project-listing-row')

        for listing in project_listings[:20]:  # Limit to 20 results
            try:
                # Extract plugin information
                title_elem = listing.find('h3', class_='project-listing-header')
                if not title_elem:
                    continue

                link_elem = title_elem.find('a')
                if not link_elem:
                    continue

                plugin_name = link_elem.get_text().strip()
                plugin_url = link_elem.get('href')

                if not plugin_url.startswith('https://dev.bukkit.org/bukkit-plugins/'):
                    continue  # Only include bukkit plugins

                # Extract description if available
                desc_elem = listing.find('p', class_='project-listing-summary')
                description = desc_elem.get_text().strip() if desc_elem else 'No description available'

                # Extract version info if available
                version_elem = listing.find('div', class_='project-listing-info')
                version = 'Latest'
                if version_elem:
                    version_info = version_elem.get_text().strip()
                    # Look for version patterns
                    import re
                    version_match = re.search(r'(\d+\.\d+(?:\.\d+)*)', version_info)
                    if version_match:
                        version = version_match.group(1)

                plugin_slug = plugin_url.split('/bukkit-plugins/')[-1].split('/')[0]

                plugin_info = {
                    'name': plugin_name,
                    'description': description[:200] + '...' if len(description) > 200 else description,
                    'version': version,
                    'url': plugin_url,
                    'slug': plugin_slug,
                    'source': 'bukkitdev',
                    'downloads': 0  # Not easily available in search results
                }
                plugins.append(plugin_info)

            except Exception as parse_error:
                # Skip malformed entries
                continue

        return jsonify({'plugins': plugins})

    except requests.exceptions.RequestException as e:
        logging.error(f"Network error accessing dev.bukkit.org: {e}")
        return jsonify({
            'plugins': [],
            'error': f'Network error: {str(e)}',
            'note': 'Check your internet connection.'
        })
    except Exception as e:
        logging.error(f"Error parsing dev.bukkit.org: {e}")
        return jsonify({
            'plugins': [],
            'error': str(e),
            'note': 'Error occurred while searching bukkit.org.'
        })

@app.route('/api/plugins/search/github', methods=['GET'])
def api_search_github_plugins():
    """Search for plugins on GitHub"""
    try:
        query = request.args.get('q', '')

        if not query:
            return jsonify({'plugins': []})

        # Search GitHub for plugin-related repositories
        search_query = f"{query} minecraft plugin"
        url = 'https://api.github.com/search/repositories'
        params = {
            'q': search_query,
            'sort': 'stars',
            'order': 'desc',
            'per_page': '20'
        }

        response = requests.get(url, params=params, timeout=10)

        if response.status_code == 200:
            data = response.json()
            plugin_list = []
            for repo in data.get('items', []):
                plugin_list.append({
                    'name': repo.get('name'),
                    'description': repo.get('description', ''),
                    'version': 'Latest',  # GitHub API doesn't provide version in search
                    'download_url': repo.get('download_url'),
                    'html_url': repo.get('html_url'),
                    'source': 'github',
                    'stars': repo.get('stargazers_count', 0)
                })
            return jsonify({'plugins': plugin_list})
        else:
            return jsonify({'plugins': []})
    except Exception as e:
        return jsonify({'error': str(e), 'plugins': []}), 500

@app.route('/api/plugins/search/curseforge', methods=['GET'])
def api_search_curseforge_plugins():
    """Search for plugins on CurseForge (simplified API - no auth required)"""
    try:
        query = request.args.get('q', '')

        if not query:
            return jsonify({'plugins': []})

        # Use the simplified CurseForge servermods API (no authentication required)
        url = f'https://api.curseforge.com/servermods/projects'
        params = {
            'search': query
        }

        response = requests.get(url, params=params, timeout=10)

        if response.status_code == 200:
            data = response.json()
            plugin_list = []

            for mod in data:
                # The simplified API returns basic project info
                mod_id = mod.get('id')
                mod_slug = mod.get('slug')
                mod_name = mod.get('name')
                mod_stage = mod.get('stage', 'unknown')

                # Only include projects that are in release stage
                if mod_stage.lower() in ['release', 'beta', 'alpha']:
                    plugin_info = {
                        'id': mod_id,
                        'name': mod_name,
                        'description': f'Stage: {mod_stage}',
                        'version': 'Latest Release',
                        'download_url': f'https://www.curseforge.com/api/v1/mods/{mod_id}/files/latest',
                        'source': 'curseforge',
                        'downloads': 0,  # This API doesn't provide download counts
                        'file_id': None,
                        'project_id': mod_id,
                        'slug': mod_slug,
                        'stage': mod_stage,
                        'url': f'https://www.curseforge.com/minecraft/bukkit-plugins/{mod_slug}'
                    }
                    plugin_list.append(plugin_info)

            return jsonify({'plugins': plugin_list})

        else:
            logging.error(f"CurseForge servermods API error: {response.status_code} - {response.text}")
            return jsonify({
                'plugins': [],
                'error': f'CurseForge API returned status {response.status_code}',
                'note': 'The CurseForge servermods API may be temporarily unavailable.'
            })

    except requests.exceptions.RequestException as e:
        logging.error(f"Network error accessing CurseForge servermods API: {e}")
        return jsonify({
            'plugins': [],
            'error': f'Network error: {str(e)}',
            'note': 'Check your internet connection.'
        })
    except Exception as e:
        logging.error(f"Error in CurseForge search: {e}")
        return jsonify({
            'plugins': [],
            'error': str(e),
            'note': 'Internal error occurred while searching CurseForge.'
        })

@app.route('/api/plugins/download', methods=['POST'])
def api_download_plugin():
    """Download a plugin from external source"""
    try:
        data = request.get_json()
        url = data.get('url')
        filename = data.get('filename')
        source = data.get('source')
        
        if not url or not filename:
            return jsonify({'error': 'URL and filename are required'}), 400
        
        plugins_dir = '/data/plugins'
        os.makedirs(plugins_dir, exist_ok=True)
        
        # Download the file
        response = requests.get(url, timeout=30, stream=True)
        response.raise_for_status()
        
        plugin_path = os.path.join(plugins_dir, filename)
        with open(plugin_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        
        return jsonify({
            'success': True,
            'message': f'Plugin {filename} downloaded successfully from {source}',
            'plugin': filename
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@socketio.on('connect')
def handle_connect():
    """Handle WebSocket connection"""
    print('Client connected')
    emit('connected', {'data': 'Connected'})

@socketio.on('disconnect')
def handle_disconnect():
    """Handle WebSocket disconnection"""
    print('Client disconnected')

@socketio.on('request_logs')
def handle_log_request():
    """Handle log request from client"""
    try:
        conn = sqlite3.connect(DB_PATH)
        c = conn.cursor()
        c.execute("SELECT timestamp, level, message, player, command FROM logs ORDER BY timestamp DESC LIMIT 50")
        logs = c.fetchall()
        conn.close()
        
        emit('log_data', [{
            'timestamp': log[0],
            'level': log[1],
            'message': log[2],
            'player': log[3],
            'command': log[4]
        } for log in logs])
    except Exception as e:
        emit('error', {'message': f'Error fetching logs: {e}'})

def background_tasks():
    """Background task to monitor server"""
    while True:
        try:
            # Get server status every 30 seconds
            status = get_server_status()
            
            # Update player database
            for player in status['online_players']:
                if player.strip():
                    conn = sqlite3.connect(DB_PATH)
                    c = conn.cursor()
                    now = datetime.now().isoformat()
                    c.execute("INSERT OR REPLACE INTO players (username, last_seen, is_online) VALUES (?, ?, 1)",
                             (player.strip(), now))
                    conn.commit()
                    conn.close()
                    
                    # Emit player update to connected clients
                    socketio.emit('player_update', {
                        'player': player.strip(),
                        'status': 'online',
                        'timestamp': now
                    })
            
            # Emit status update to connected clients
            socketio.emit('status_update', status)
            
            time.sleep(30)
        except Exception as e:
            logging.error(f"Error in background task: {e}")
            time.sleep(60)

if __name__ == '__main__':
    # Initialize database
    init_database()
    
    # Background monitoring disabled to reduce RCON connections
    # The dashboard polling provides sufficient updates
    # monitor_thread = Thread(target=background_tasks, daemon=True)
    # monitor_thread.start()
    
    # Start Flask-SocketIO app
    socketio.run(app, host='0.0.0.0', port=8080, debug=False, allow_unsafe_werkzeug=True)
