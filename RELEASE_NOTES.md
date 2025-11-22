# Release 2.1.0 - Critical Bug Fixes & Stability Improvements

## 🎯 Release Summary

This release addresses critical stability issues and improves the overall user experience. The WebUI no longer restarts constantly, management scripts work reliably across all Windows environments, and documentation is now consistent with the actual file structure.

## 🔧 Major Fixes

### 🐛 WebUI Constant Restarting Issue - RESOLVED
- **Root Cause**: Missing `CMD ["python3", "app.py"]` instruction in webui Dockerfile
- **Solution**: Added proper CMD instruction and improved service dependencies
- **Impact**: WebUI now runs stably without restart loops

### 🖥️ PowerShell Compatibility Issues - RESOLVED  
- **Root Cause**: Unicode emoji characters causing display corruption
- **Solution**: Replaced all Unicode with ASCII-compatible symbols
- **Impact**: Clean output in both PowerShell and Command Prompt

### 📜 Management Script Output Issues - RESOLVED
- **Root Cause**: Complex batch logic suppressing docker-compose output
- **Solution**: Simplified to direct commands with proper output display
- **Impact**: Status commands now show actual container information

### 🧹 File Structure Cleanup - COMPLETED
- **Action**: Removed 5 duplicate management scripts
- **Removed**: `setup.bat`, `setup.ps1`, `setup-and-manage.bat`, `setup-and-manage.ps1`, `rebuild-webui.bat`
- **Impact**: Cleaner project structure, less confusion

### 📚 Documentation Consistency - UPDATED
- **Updated**: README.md, README-WEBUI.md, docs/index.html
- **Fixed**: All references to removed scripts
- **Impact**: Setup instructions now point to existing files

## 🆕 New Features

- **Enhanced MANAGEMENT.md**: Comprehensive management commands documentation
- **Simplified Commands**: Streamlined batch scripts with better error handling
- **Cross-Platform Support**: Consistent behavior across all Windows environments

## 🧪 Testing

✅ **Container Status**: Both minecraft-server and minecraft-webui run stably  
✅ **Management Commands**: All commands (start, stop, status, logs) work correctly  
✅ **PowerShell Compatibility**: No encoding issues in any environment  
✅ **Documentation**: All setup guides tested and verified  

## 🔄 Breaking Changes

⚠️ **Management Script Changes**: Some batch script commands have been simplified
- `manage.bat rebuild` → Use `docker-compose build --no-cache` instead
- References to removed scripts in documentation updated

## 📦 Installation

### Windows PowerShell
```powershell
git clone https://github.com/involvex/docker-minecraft-server.git
cd docker-minecraft-server
.\setup.ps1
```

### Windows Command Prompt
```cmd
git clone https://github.com/involvex/docker-minecraft-server.git
cd docker-minecraft-server
setup.bat
manage.bat start
```

### Linux/macOS
```bash
git clone https://github.com/involvex/docker-minecraft-server.git
cd docker-minecraft-server
./setup.sh
```

## 🎮 Quick Start

1. **Setup**: Run the appropriate setup script for your platform
2. **Start**: `manage.bat start` (Windows) or `./setup.sh start` (Linux)
3. **Access**: Web UI at http://localhost:8080, Minecraft at localhost:25565

## 🙏 Acknowledgments

Thanks to the community for reporting these issues and helping improve the project stability.

## 📋 Full Changelog

### Fixed
- WebUI constant restarting due to missing Dockerfile CMD instruction
- PowerShell display issues with Unicode characters in batch scripts
- manage.bat status command not showing container output
- Documentation references to non-existent setup scripts
- Duplicate management scripts causing user confusion

### Improved
- Simplified and optimized management scripts
- Enhanced documentation with consistent file references
- Better error handling and user feedback
- Cross-platform compatibility for Windows environments

### Removed
- Duplicate management scripts (setup.bat, setup.ps1, setup-and-manage.bat, etc.)
- References to non-existent files in documentation

---

**Release Date**: November 22, 2025  
**Download**: https://github.com/involvex/docker-minecraft-server/releases/tag/v2.1.0  
**Documentation**: https://github.com/involvex/docker-minecraft-server/blob/master/README.md
