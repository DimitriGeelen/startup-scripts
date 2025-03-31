#!/bin/bash

# Set colors for better visibility
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Running LAN Scanner installation script...${NC}"
echo -e "${BLUE}============================================================${NC}"
echo -e "${BLUE}LAN Web Server Scanner - Installation${NC}"
echo -e "${BLUE}============================================================${NC}"

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo -e "${YELLOW}Please run this script as root or with sudo${NC}"
  exit 1
fi

# Function to check and install system dependencies
install_system_dependencies() {
  echo -e "${BLUE}Checking and installing system dependencies...${NC}"
  
  # Update package list
  echo -e "${BLUE}Updating package lists...${NC}"
  apt update
  
  # Check for Chrome/Chromium
  if ! command -v chromium-browser &> /dev/null && ! command -v chromium &> /dev/null && ! command -v google-chrome &> /dev/null; then
    echo -e "${YELLOW}Installing Chromium browser...${NC}"
    apt install -y chromium-browser || apt install -y chromium
    
    # If still not found after installation attempt
    if ! command -v chromium-browser &> /dev/null && ! command -v chromium &> /dev/null && ! command -v google-chrome &> /dev/null; then
      echo -e "${RED}Failed to install Chrome/Chromium. Please install manually.${NC}"
      HAS_ERRORS=true
    fi
  else
    echo -e "${GREEN}Chrome/Chromium is already installed.${NC}"
  fi
  
  # Check for nmap
  if ! command -v nmap &> /dev/null; then
    echo -e "${YELLOW}Installing nmap...${NC}"
    apt install -y nmap
    
    # If still not found after installation attempt
    if ! command -v nmap &> /dev/null; then
      echo -e "${RED}Failed to install nmap. Please install manually.${NC}"
      HAS_ERRORS=true
    fi
  else
    echo -e "${GREEN}nmap is already installed.${NC}"
  fi
  
  # Check for Python venv package
  PYTHON_VERSION=$(python3 --version 2>&1 | cut -d " " -f 2 | cut -d "." -f 1-2)
  PYTHON_VENV_PACKAGE="python3-venv"
  
  if [ -n "$PYTHON_VERSION" ]; then
    PYTHON_VENV_PACKAGE="python${PYTHON_VERSION}-venv"
    echo -e "${BLUE}Detected Python version: ${PYTHON_VERSION}${NC}"
  fi
  
  echo -e "${YELLOW}Installing Python venv package (${PYTHON_VENV_PACKAGE})...${NC}"
  apt install -y $PYTHON_VENV_PACKAGE || apt install -y python3-venv
  
  # Check if we can create a venv after installation
  if ! python3 -m venv --help &> /dev/null; then
    echo -e "${RED}Failed to install Python venv package. Please install manually.${NC}"
    echo -e "${YELLOW}Try: apt install python3-venv${NC}"
    HAS_ERRORS=true
  else
    echo -e "${GREEN}Python venv package is installed.${NC}"
  fi
}

# Check for prerequisites
check_prerequisites() {
  MISSING_PREREQS=()

  echo -e "${BLUE}Checking for Chrome/Chromium browser...${NC}"
  if ! command -v chromium-browser &> /dev/null && ! command -v chromium &> /dev/null && ! command -v google-chrome &> /dev/null; then
    MISSING_PREREQS+=("Chrome or Chromium browser")
  fi

  echo -e "${BLUE}Checking for nmap...${NC}"
  if ! command -v nmap &> /dev/null; then
    MISSING_PREREQS+=("nmap")
  fi

  if [ ${#MISSING_PREREQS[@]} -gt 0 ]; then
    echo -e "${YELLOW}WARNING: The following prerequisites are missing:${NC}"
    for prereq in "${MISSING_PREREQS[@]}"; do
      echo -e "  - $prereq"
    done
    
    echo -e "${BLUE}Would you like to automatically install missing dependencies? (y/n)${NC}"
    read -r install_choice
    
    if [[ "$install_choice" =~ ^[Yy]$ ]]; then
      install_system_dependencies
    else
      echo -e "${YELLOW}You will need to install these manually before running the application.${NC}"
      echo -e "${YELLOW}Installation will continue, but the application may not function correctly.${NC}"
    fi
  fi
}

# Create and activate virtual environment
create_virtual_environment() {
  echo -e "${BLUE}Creating virtual environment at venv...${NC}"
  
  # Try to create virtual environment with error handling
  if ! python3 -m venv venv; then
    echo -e "${RED}Error creating virtual environment.${NC}"
    echo -e "${YELLOW}Checking Python venv capability...${NC}"
    
    # Check if venv module is available
    if ! python3 -m venv --help &> /dev/null; then
      echo -e "${RED}Python venv module is not available.${NC}"
      echo -e "${YELLOW}Would you like to install it now? (y/n)${NC}"
      read -r venv_choice
      
      if [[ "$venv_choice" =~ ^[Yy]$ ]]; then
        install_system_dependencies
        
        # Try creating venv again
        echo -e "${BLUE}Trying to create virtual environment again...${NC}"
        if ! python3 -m venv venv; then
          echo -e "${RED}Installation aborted due to failure creating virtual environment.${NC}"
          exit 1
        fi
      else
        echo -e "${RED}Installation aborted due to missing Python venv module.${NC}"
        exit 1
      fi
    else
      echo -e "${RED}Installation aborted due to failure creating virtual environment.${NC}"
      exit 1
    fi
  fi

  echo -e "${GREEN}Virtual environment created successfully.${NC}"
  
  # Activate virtual environment
  echo -e "${BLUE}Activating virtual environment...${NC}"
  source venv/bin/activate
}

# Install Python dependencies
install_dependencies() {
  echo -e "${BLUE}Installing Python dependencies...${NC}"
  
  # Check if requirements.txt exists
  if [ -f "requirements.txt" ]; then
    pip install --upgrade pip
    pip install -r requirements.txt
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error installing dependencies.${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}Dependencies installed successfully.${NC}"
  else
    echo -e "${YELLOW}requirements.txt not found.${NC}"
    echo -e "${YELLOW}Installing common dependencies...${NC}"
    
    # Install common dependencies
    pip install --upgrade pip
    pip install flask flask-cors requests selenium webdriver-manager python-nmap
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error installing dependencies.${NC}"
      exit 1
    fi
    
    echo -e "${GREEN}Common dependencies installed successfully.${NC}"
  fi
}

# Create executable script
create_executable() {
  echo -e "${BLUE}Creating executable script...${NC}"
  
  cat > run.sh << 'EOF'
#!/bin/bash
# LAN Scanner Executable

# Set colors for better visibility
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}Starting LAN Scanner...${NC}"

# Activate virtual environment
source venv/bin/activate

# Run the application
if [ -f "app.py" ]; then
  python app.py
elif [ -f "main.py" ]; then
  python main.py
else
  echo -e "${RED}Error: Cannot find application entry point (app.py or main.py).${NC}"
  exit 1
fi
EOF

  chmod +x run.sh
  echo -e "${GREEN}Executable script created successfully.${NC}"
}

# Main installation process
main() {
  # Global variable to track if there are any errors
  HAS_ERRORS=false
  
  # Check prerequisites
  check_prerequisites
  
  # Create virtual environment
  create_virtual_environment
  
  # Install dependencies
  install_dependencies
  
  # Create executable
  create_executable
  
  # Installation complete
  if [ "$HAS_ERRORS" = true ]; then
    echo -e "${YELLOW}============================================================${NC}"
    echo -e "${YELLOW}Installation completed with warnings.${NC}"
    echo -e "${YELLOW}Some components may not work correctly.${NC}"
    echo -e "${YELLOW}Run ./run.sh to start the application.${NC}"
    exit 0
  else
    echo -e "${GREEN}============================================================${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${GREEN}Run ./run.sh to start the application.${NC}"
    exit 0
  fi
}

# Run the main installation process
main
