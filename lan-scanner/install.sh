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
  
  # Make sure pip is installed
  echo -e "${YELLOW}Installing pip3...${NC}"
  apt install -y python3-pip
  
  if ! command -v pip3 &> /dev/null; then
    echo -e "${RED}Failed to install pip3. Please install manually.${NC}"
    echo -e "${YELLOW}Try: apt install python3-pip${NC}"
    HAS_ERRORS=true
  else
    echo -e "${GREEN}pip3 is installed.${NC}"
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
  
  echo -e "${BLUE}Checking for pip3...${NC}"
  if ! command -v pip3 &> /dev/null; then
    MISSING_PREREQS+=("pip3")
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
  # Check if virtual environment already exists
  if [ -d "venv" ]; then
    echo -e "${YELLOW}Virtual environment already exists at venv${NC}"
    echo -e "${BLUE}Would you like to recreate it? (y/n)${NC}"
    read -r recreate_choice
    
    if [[ "$recreate_choice" =~ ^[Yy]$ ]]; then
      echo -e "${BLUE}Removing existing virtual environment...${NC}"
      rm -rf venv
    else
      echo -e "${BLUE}Using existing virtual environment...${NC}"
      
      # Check if pip exists in the virtual environment
      if [ ! -f "venv/bin/pip" ] && [ ! -f "venv/bin/pip3" ]; then
        echo -e "${YELLOW}pip not found in virtual environment.${NC}"
        echo -e "${BLUE}Recreating virtual environment...${NC}"
        rm -rf venv
      else
        return 0
      fi
    fi
  fi
  
  echo -e "${BLUE}Creating virtual environment at venv...${NC}"
  
  # Make sure Python is available
  if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Python 3 is not installed. Please install Python 3.${NC}"
    echo -e "${YELLOW}Try: apt install python3${NC}"
    exit 1
  fi
  
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
}

# Install Python dependencies
install_dependencies() {
  # Activate virtual environment
  echo -e "${BLUE}Activating virtual environment...${NC}"
  source venv/bin/activate || source venv/Scripts/activate
  
  # Check if pip exists in the virtual environment
  if [ ! -f "venv/bin/pip" ] && [ ! -f "venv/bin/pip3" ]; then
    echo -e "${YELLOW}pip not found in virtual environment.${NC}"
    echo -e "${BLUE}Installing pip in virtual environment...${NC}"
    
    # Download get-pip.py
    echo -e "${BLUE}Downloading get-pip.py...${NC}"
    curl -s https://bootstrap.pypa.io/get-pip.py -o get-pip.py
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to download get-pip.py.${NC}"
      echo -e "${YELLOW}Trying with wget...${NC}"
      wget -q https://bootstrap.pypa.io/get-pip.py
      
      if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to download get-pip.py. Please check your internet connection.${NC}"
        exit 1
      fi
    fi
    
    # Install pip in the virtual environment
    python get-pip.py
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}Failed to install pip in virtual environment.${NC}"
      exit 1
    fi
    
    # Clean up
    rm get-pip.py
  fi
  
  echo -e "${BLUE}Installing Python dependencies...${NC}"
  
  # Upgrade pip first
  echo -e "${BLUE}Upgrading pip...${NC}"
  pip install --upgrade pip
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error upgrading pip.${NC}"
    echo -e "${YELLOW}Continuing with installation...${NC}"
  fi
  
  # Check if requirements.txt exists
  if [ -f "requirements.txt" ]; then
    echo -e "${BLUE}Installing dependencies from requirements.txt...${NC}"
    pip install -r requirements.txt
    
    if [ $? -ne 0 ]; then
      echo -e "${RED}Error installing dependencies from requirements.txt.${NC}"
      echo -e "${YELLOW}Would you like to try installing common dependencies? (y/n)${NC}"
      read -r common_deps_choice
      
      if [[ "$common_deps_choice" =~ ^[Yy]$ ]]; then
        install_common_dependencies
      else
        exit 1
      fi
    else
      echo -e "${GREEN}Dependencies installed successfully from requirements.txt.${NC}"
    fi
  else
    echo -e "${YELLOW}requirements.txt not found.${NC}"
    echo -e "${BLUE}Would you like to install common dependencies? (y/n)${NC}"
    read -r common_deps_choice
    
    if [[ "$common_deps_choice" =~ ^[Yy]$ ]]; then
      install_common_dependencies
    else
      echo -e "${YELLOW}No dependencies installed. The application may not function correctly.${NC}"
      HAS_ERRORS=true
    fi
  fi
  
  # Deactivate virtual environment
  deactivate
}

# Install common dependencies
install_common_dependencies() {
  echo -e "${BLUE}Installing common dependencies...${NC}"
  
  # List of common dependencies
  pip install flask flask-cors requests selenium webdriver-manager python-nmap
  
  if [ $? -ne 0 ]; then
    echo -e "${RED}Error installing common dependencies.${NC}"
    exit 1
  fi
  
  echo -e "${GREEN}Common dependencies installed successfully.${NC}"
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

# Check if virtual environment exists
if [ ! -d "venv" ]; then
  echo -e "${RED}Error: Virtual environment not found.${NC}"
  echo -e "${YELLOW}Please run the installation script first.${NC}"
  exit 1
fi

# Activate virtual environment
if [ -f "venv/bin/activate" ]; then
  source venv/bin/activate
elif [ -f "venv/Scripts/activate" ]; then
  source venv/Scripts/activate
else
  echo -e "${RED}Error: Could not find activation script for virtual environment.${NC}"
  exit 1
fi

# Check if the virtual environment was activated successfully
if [ -z "$VIRTUAL_ENV" ]; then
  echo -e "${RED}Error: Failed to activate virtual environment.${NC}"
  exit 1
fi

echo -e "${GREEN}Virtual environment activated.${NC}"

# Run the application
if [ -f "app.py" ]; then
  echo -e "${BLUE}Running app.py...${NC}"
  python app.py
elif [ -f "main.py" ]; then
  echo -e "${BLUE}Running main.py...${NC}"
  python main.py
else
  echo -e "${YELLOW}No app.py or main.py found.${NC}"
  echo -e "${BLUE}Searching for Python files with main function...${NC}"
  
  # Try to find a suitable Python file to run
  MAIN_FILES=$(grep -l "if __name__ == '__main__'" *.py 2>/dev/null)
  
  if [ -n "$MAIN_FILES" ]; then
    # If multiple files found, use the first one
    MAIN_FILE=$(echo "$MAIN_FILES" | head -1)
    echo -e "${BLUE}Running $MAIN_FILE...${NC}"
    python "$MAIN_FILE"
  else
    echo -e "${RED}Error: Cannot find application entry point.${NC}"
    echo -e "${YELLOW}Please specify the Python file to run:${NC}"
    read -r python_file
    
    if [ -f "$python_file" ]; then
      echo -e "${BLUE}Running $python_file...${NC}"
      python "$python_file"
    else
      echo -e "${RED}Error: File $python_file not found.${NC}"
      exit 1
    fi
  fi
fi

# Deactivate virtual environment when done
deactivate
EOF

  chmod +x run.sh
  echo -e "${GREEN}Executable script created successfully.${NC}"
}

# Function to detect and convert Python script if present
check_for_python_installer() {
  if [ -f "install.py" ]; then
    echo -e "${BLUE}Found Python installation script (install.py)${NC}"
    echo -e "${BLUE}Would you like to continue with the bash installation script instead? (y/n)${NC}"
    read -r continue_choice
    
    if ! [[ "$continue_choice" =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Exiting bash installer. Please run the Python installer using:${NC}"
      echo -e "${YELLOW}python3 install.py${NC}"
      exit 0
    fi
  fi
}

# Main installation process
main() {
  # Global variable to track if there are any errors
  HAS_ERRORS=false
  
  # Check for Python installer
  check_for_python_installer
  
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
