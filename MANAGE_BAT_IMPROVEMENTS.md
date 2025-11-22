# Minecraft Server Management Script Improvements

This document details the improvements made to the `manage.bat` script to address various requirements and enhance its functionality.

## Implemented Improvements

### 1. Logging & Error Handling

All commands now include:

- Comprehensive logging to `logs\server.log` with timestamps
- Error handling using `errorlevel` checks after each operation
- Error logging to a dedicated log file
- Clear error messages with both visual indicators (❌) and detailed information

### 2. Command Validation & Parameter Handling

The script now includes:

- Validation for all commands that require parameters
- Enhanced validation for the `rcon` command with required argument check
- Input sanitization function to prevent potential security issues
- Better handling of special characters in user input

### 3. Environment Protection & Security

- Added input sanitization to remove potentially dangerous characters
- Docker-compose availability check before executing commands
- Safe handling of user-provided parameters

### 4. Auto-Start/Stop with Scheduled Tasks

New functionality includes:

- `auto-start` command that creates a Windows Task Scheduler task
- Automatic server startup on user login
- Proper task creation with appropriate permissions

### 5. UI Improvements

Enhanced the user interface with:

- More detailed help section with examples
- Visual status indicators for all commands
- Version information displayed in help output
- Better organization of commands by category

### 6. Support for Multiple Server Types

Added support for:

- `multi-server` command to create and manage multiple Minecraft server instances
- Automatic generation of separate docker-compose files for each server
- Proper isolation of multiple server instances

### 7. Advanced Features

New commands and functionality:

- `health` command to check server health via RCON
- Improved restart functionality that properly handles stop/start
- Better error recovery in all commands

### 8. Better Exit Code Handling

- All commands now return appropriate exit codes (0 for success, 1 for errors)
- Enables proper error handling in calling scripts or processes
- Better integration with other automation tools

## Key Changes Summary

| Feature             | Implementation                                         |
| ------------------- | ------------------------------------------------------ |
| **Logging**         | Log files created in `logs\server.log` with timestamps |
| **Security**        | Input sanitization for all user inputs                 |
| **User Experience** | Enhanced help output with examples and version info    |
| **Automation**      | Auto-start functionality with Task Scheduler           |
| **Multi-Instance**  | Support for multiple Minecraft servers                 |
| **Error Handling**  | Proper error detection and reporting                   |

## Example Usage

```batch
# Start the server with full logging
manage.bat start

# Check server health
manage.bat health

# Create an automated start task
manage.bat auto-start minecraft-server

# Create multiple server instances
manage.bat multi-server survival
manage.bat multi-server creative

# Execute RCON commands with sanitized input
manage.bat rcon list
manage.bat rcon save-all
```

## Conclusion

The enhanced script maintains full compatibility with the original functionality while adding robust logging, error handling, and security features. These improvements make it more suitable for production environments and automated deployments while remaining user-friendly for manual operation.
