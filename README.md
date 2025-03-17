# Startup Scripts

A collection of utility scripts to automate startup tasks and improve workflow.

## Scripts

### 1. add-to-system-startup.sh

This script adds commands to run at system boot time BEFORE any user login. It supports multiple system initialization methods:

- systemd services (most modern Linux distributions)
- crontab @reboot entries (works on most Unix-like systems)
- rc.local additions (legacy systems)

#### Features:

- Automatically detects your system's initialization method
- Creates proper systemd service files with dependencies and auto-restart
- Allows running commands as specific users
- Supports setting working directories
- Provides descriptive task names and descriptions

#### Usage:

1. Clone this repository:
   ```bash
   git clone https://github.com/DimitriGeelen/startup-scripts.git
   ```

2. Make the script executable:
   ```bash
   chmod +x startup-scripts/add-to-system-startup.sh
   ```

3. Run the script with sudo:
   ```bash
   sudo ./startup-scripts/add-to-system-startup.sh
   ```

4. Follow the interactive prompts to:
   - Name your startup task
   - Add an optional description
   - Enter the command to run at boot
   - Specify a working directory (optional)
   - Choose which user to run the command as

#### Example:

```
System Startup Command Manager
Script location: /root/startup-scripts/add-to-system-startup.sh
Detected system type: systemd

Enter a name for this startup task (no spaces, e.g. 'mysql_server'): web_server

Enter a description for this task (optional): Start development web server

Enter the command to run at system startup: /usr/local/bin/serve -p 8080

Enter the working directory for the command (or press Enter for default): /var/www

Run command as:
1. root (system user)
2. Specify a different user
Enter your choice (1/2): 2
Enter username: www-data

Summary:
Task name: web_server
Description: Start development web server
Command: /usr/local/bin/serve -p 8080
Working directory: /var/www
Run as user: www-data
System type: systemd

Add this command to system startup? (y/n): y

Systemd service created and enabled: web_server.service
View service status with: systemctl status web_server.service

Success! Command will run at next system boot.
```

### 2. add-to-startup.sh

This script helps you easily add commands to your shell's startup file (like `.bashrc`, `.zshrc`, or `.profile`) for execution when a user logs in.

#### Features:

- Automatically detects which startup file to use based on your shell
- Allows you to specify a working directory for your command
- Organizes commands with optional section headers
- Shows a summary and confirms before making any changes
- Provides colored output for better readability

#### Usage:

1. Make the script executable:
   ```bash
   chmod +x startup-scripts/add-to-startup.sh
   ```

2. Run the script:
   ```bash
   ./startup-scripts/add-to-startup.sh
   ```

3. Follow the interactive prompts

## Contributing

Feel free to submit pull requests with improvements or additional scripts.

## License

MIT
