@echo off
echo ========================================
echo Rebuilding Minecraft Web UI
echo ========================================
echo.

echo Step 1: Stopping web UI container...
docker-compose stop minecraft-webui

echo.
echo Step 2: Rebuilding web UI image (this may take a minute)...
docker-compose build --no-cache minecraft-webui

echo.
echo Step 3: Starting all containers...
docker-compose up -d

echo.
echo ========================================
echo Done! Web UI is now running
echo ========================================
echo.
echo Web UI URL: http://localhost:8080
echo.
echo New Features Added:
echo - OP/De-OP players
echo - Ban/Unban players
echo - Ban List menu
echo - Improved player management
echo.
echo Press any key to view logs (Ctrl+C to exit logs)...
pause >nul
docker-compose logs -f minecraft-webui
