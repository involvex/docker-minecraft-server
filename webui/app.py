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

@app.route('/api/plugins', methods=['GET'])
def api_plugins():
    """List installed plugins"""
    try:
        plugins_dir = '/data/plugins'
        if os.path.exists(plugins_dir):
            plugins = [f for f in os.listdir(plugins_dir) if f.endswith('.jar')]
            return jsonify({'plugins': plugins})
        return jsonify({'plugins': []})
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