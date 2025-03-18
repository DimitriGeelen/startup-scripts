#!/bin/bash

# GitHub Repo Manager
# ==================
# 
# This script lists your GitHub repos, lets you select one, 
# creates a folder with the same name, and clones the repo into it.
#
# Features:
# - Lists all your GitHub repositories with numbers for easy selection
# - Creates a folder with the same name as the selected repository
# - Clones the repository into the newly created folder
# - Detects project type and suggests appropriate startup commands
# - Supports various project types (Node.js, Python, Ruby, PHP, Java, Go, Docker)
#
# Requirements:
# - GitHub CLI (gh) installed and authenticated (https://cli.github.com)
#
# Usage:
# 1. Make this script executable: chmod +x github-repo-manager.sh
# 2. Run the script: ./github-repo-manager.sh
# 3. Select a repository from the list
# 4. The script will create a folder, clone the repo, and suggest a startup command

# Set colors for better visibility
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== GitHub Repo Manager ===${NC}"

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI (gh) is not installed. Please install it first:${NC}"
    echo "  https://cli.github.com/manual/installation"
    exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}You need to authenticate with GitHub CLI first. Run:${NC}"
    echo "  gh auth login"
    exit 1
fi

# Fetch repositories from GitHub (without using jq)
echo -e "${BLUE}Fetching your repositories...${NC}"
# Get a simple list of repo names
REPO_NAMES=($(gh repo list --limit 100 --json name --jq '.[].name'))
REPO_URLS=($(gh repo list --limit 100 --json url --jq '.[].url'))

# Check if we found any repos
if [ ${#REPO_NAMES[@]} -eq 0 ]; then
    echo -e "${YELLOW}No repositories found. Make sure you're logged in with the correct account.${NC}"
    exit 1
fi

# Display repositories as a numbered list
echo -e "${BLUE}Your GitHub repositories:${NC}"
for i in "${!REPO_NAMES[@]}"; do
    echo -e "$(($i+1))) ${REPO_NAMES[$i]} - ${REPO_URLS[$i]}"
done

# Ask user to select a repository
echo -e "${BLUE}\nEnter the number of the repository you want to clone:${NC}"
read -r selection

# Validate selection
if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#REPO_NAMES[@]} ]; then
    echo -e "${YELLOW}Invalid selection.${NC}"
    exit 1
fi

# Get the repository info from the selection
selection=$((selection-1))  # Convert to zero-based index
repo_name="${REPO_NAMES[$selection]}"
repo_url="${REPO_URLS[$selection]}"

# Create directory with the same name as the repo
echo -e "${BLUE}Creating directory: ${YELLOW}$repo_name${NC}"
mkdir -p "$repo_name"

# Clone the repository into the directory
echo -e "${BLUE}Cloning repository: ${YELLOW}$repo_url${NC}"
git clone "$repo_url" "$repo_name"

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Failed to clone the repository.${NC}"
    exit 1
fi

echo -e "${GREEN}Repository cloned successfully!${NC}"

# Detect project type and suggest startup command
cd "$repo_name" || exit

# Initialize command variable
start_command=""

# Check for package.json (Node.js)
if [ -f "package.json" ]; then
    if grep -q "\"start\":" package.json; then
        start_command="npm start"
    elif grep -q "\"dev\":" package.json; then
        start_command="npm run dev"
    else
        start_command="npm install && npm start"
    fi
# Check for requirements.txt (Python)
elif [ -f "requirements.txt" ]; then
    start_command="pip install -r requirements.txt && python app.py"
    # Try to find the main Python file if app.py doesn't exist
    if [ ! -f "app.py" ]; then
        main_py=$(find . -maxdepth 1 -name "*.py" | head -1)
        if [ -n "$main_py" ]; then
            start_command="pip install -r requirements.txt && python $(basename "$main_py")"
        fi
    fi
# Check for Gemfile (Ruby)
elif [ -f "Gemfile" ]; then
    start_command="bundle install && rails server"
# Check for composer.json (PHP)
elif [ -f "composer.json" ]; then
    start_command="composer install && php -S localhost:8000"
# Check for pom.xml (Java Maven)
elif [ -f "pom.xml" ]; then
    start_command="mvn install && mvn exec:java"
# Check for build.gradle (Java Gradle)
elif [ -f "build.gradle" ]; then
    start_command="gradle build && gradle run"
# Check for go.mod (Go)
elif [ -f "go.mod" ]; then
    start_command="go run ."
# Check for Dockerfile
elif [ -f "Dockerfile" ]; then
    start_command="docker build -t $repo_name . && docker run -p 8080:8080 $repo_name"
else
    start_command="# Could not determine how to start this project"
fi

# Print the command to start the project
echo -e "${BLUE}To start the project, you can try:${NC}"
echo -e "${GREEN}cd $repo_name && $start_command${NC}"

echo -e "${YELLOW}Note: The start command is a best guess based on project files.${NC}"
echo -e "${YELLOW}You may need to adjust it depending on the specific project structure.${NC}"