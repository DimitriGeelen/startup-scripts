# Startup Scripts

A collection of utility scripts to automate startup tasks and improve workflow.

## Scripts

### add-to-startup.sh

This script helps you easily add commands to your shell's startup file (like `.bashrc`, `.zshrc`, or `.profile`) without having to manually edit these files.

#### Features:

- Automatically detects which startup file to use based on your shell
- Allows you to specify a working directory for your command
- Organizes commands with optional section headers
- Shows a summary and confirms before making any changes
- Provides colored output for better readability

#### Usage:

1. Clone this repository:
   ```bash
   git clone https://github.com/DimitriGeelen/startup-scripts.git
   ```

2. Make the script executable:
   ```bash
   chmod +x startup-scripts/add-to-startup.sh
   ```

3. Run the script:
   ```bash
   ./startup-scripts/add-to-startup.sh
   ```

4. Follow the interactive prompts to:
   - Add an optional section header
   - Enter the command you want to run at startup
   - Choose between using the current directory or specifying a different path
   - Confirm the additions before they're made

#### Example:

```
Add Command to Startup Script
Script location: /home/user/startup-scripts/add-to-startup.sh
This script will add a command to your startup file: /home/user/.bashrc

Enter a section name for this command (optional, press Enter to skip): Development Environment

Enter the command you want to run at startup: nvm use 16

Path Options:
1. Use current directory: /home/user/projects
2. Specify a different path
Enter your choice (1/2): 1

Summary:
Section name: Development Environment
Command: nvm use 16
Path: /home/user/projects
Full command to add: cd "/home/user/projects" && nvm use 16
Startup file: /home/user/.bashrc
Add this command to your startup file? (y/n): y

Success! Command added to /home/user/.bashrc
Changes will take effect on next login or when you run: source /home/user/.bashrc
```

## Contributing

Feel free to submit pull requests with improvements or additional scripts.

## License

MIT
