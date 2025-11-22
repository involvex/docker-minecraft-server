#!/bin/bash

# Minecraft Server Web UI - Quick Setup Script
# This script helps you set up the Minecraft server with web management

set -e

echo "🎮 Minecraft Server Web UI Setup"
echo "================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

echo "✅ Docker and Docker Compose are installed"

# Create directories if they don't exist
echo "📁 Creating directory structure..."
mkdir -p config/plugins
mkdir -p config/plugin-configs
mkdir -p logs
mkdir -p backups

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "🔧 Creating environment configuration..."
    cp config/.env.example .env
    echo "✅ Created .env file from template"
    echo "⚠️  Please edit .env file with your preferred settings before starting the server"
else
    echo "✅ .env file already exists"
fi

# Generate secure passwords
echo "🔐 Generating secure passwords..."
NEW_RCON_PASSWORD=$(openssl rand -base64 32)
NEW_WEBUI_SECRET=$(openssl rand -base64 32)

# Update .env file with secure passwords if not already set
if grep -q "your_secure_rcon_password_here" .env; then
    sed -i "s/your_secure_rcon_password_here/${NEW_RCON_PASSWORD}/g" .env
    echo "✅ Updated RCON password"
fi

if grep -q "your_webui_secret_key_change_in_production" .env; then
    sed -i "s/your_webui_secret_key_change_in_production/${NEW_WEBUI_SECRET}/g" .env
    echo "✅ Updated Web UI secret key"
fi

# Set proper permissions
chmod 600 .env
echo "🔒 Set secure permissions on .env file"

# Create sample server.properties if it doesn't exist
if [ ! -f config/server.properties ]; then
    echo "📝 Creating sample server.properties..."
    # The server.properties file should already exist from earlier creation
fi

echo ""
echo "🎉 Setup Complete!"
echo ""
echo "Next steps:"
echo "1. Review and edit configuration files:"
echo "   - .env (environment variables)"
echo "   - config/server.properties (server settings)"
echo ""
echo "2. Start the server:"
echo "   docker-compose up -d"
echo ""
echo "3. Access the web interface:"
echo "   http://localhost:8080"
echo ""
echo "4. Connect to Minecraft:"
echo "   localhost:25565"
echo ""
echo "📖 For detailed documentation, see SETUP_GUIDE.md"
echo ""
echo "🔧 Useful commands:"
echo "   docker-compose logs -f           # View logs"
echo "   docker-compose down              # Stop server"
echo "   docker-compose ps                # Check status"
echo "   docker-compose exec minecraft rcon-cli list  # Test RCON"
echo ""

# Offer to start the server
read -p "🚀 Would you like to start the server now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Starting Minecraft server..."
    docker-compose up -d
    
    echo ""
    echo "⏳ Waiting for server to start..."
    sleep 10
    
    echo "📊 Server status:"
    docker-compose ps
    
    echo ""
    echo "✅ Server is starting up!"
    echo "🌐 Web interface: http://localhost:8080"
    echo "🎮 Minecraft server: localhost:25565"
    echo ""
    echo "📋 To view logs: docker-compose logs -f"
fi

echo ""
echo "Happy mining! ⛏️"