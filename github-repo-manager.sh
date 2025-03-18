#!/bin/bash

# GitHub Repo Manager
# ==================
# 
# This script manages your GitHub repositories with several functionalities:
# 1. List and clone repos
# 2. Update repos locally
# 3. Replace repos locally
# 4. Push local changes to GitHub
#
# Features:
# - Lists all your GitHub repositories with numbers for easy selection
# - Creates a folder with the same name as the selected repository
# - Clones the repository into the newly created folder
# - Updates local repos with latest changes from GitHub
# - Replaces local repos with fresh clones
# - Pushes local changes to GitHub
# - Detects project type and suggests appropriate startup commands
# - Supports various project types (Node.js, Python, Ruby, PHP, Java, Go, Docker)
#
# Requirements:
# - GitHub CLI (gh) installed and authenticated (https://cli.github.com)
#
# Usage:
# 1. Make this script executable: chmod +x github-repo-manager.sh
# 2. Run the script: ./github-repo-manager.sh
# 3. Select an operation mode
# 4. Follow on-screen instructions

# Set colors for better visibility
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
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

# Function to fetch repositories from GitHub
fetch_repositories() {
    echo -e "${BLUE}Fetching your repositories...${NC}"
    # Get a simple list of repo names
    REPO_NAMES=($(gh repo list --limit 100 --json name --jq '.[].name'))
    REPO_URLS=($(gh repo list --limit 100 --json url --jq '.[].url'))

    # Check if we found any repos
    if [ ${#REPO_NAMES[@]} -eq 0 ]; then
        echo -e "${YELLOW}No repositories found. Make sure you're logged in with the correct account.${NC}"
        exit 1
    fi
}

# Function to display repositories
display_repositories() {
    echo -e "${BLUE}Your GitHub repositories:${NC}"
    for i in "${!REPO_NAMES[@]}"; do
        echo -e "$(($i+1))) ${REPO_NAMES[$i]} - ${REPO_URLS[$i]}"
    done
}

# Function to select a repository
select_repository() {
    echo -e "${BLUE}\nEnter the number of the repository:${NC}"
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
}

# Function to find locally available repositories
find_local_repos() {
    echo -e "${BLUE}Searching for locally available repositories...${NC}"
    
    # List directories in the current folder that are git repositories
    local_repos=()
    for dir in */; do
        if [ -d "${dir}.git" ]; then
            local_repos+=("${dir%/}") # Remove trailing slash
        fi
    done
    
    # Check if we found any local repos
    if [ ${#local_repos[@]} -eq 0 ]; then
        echo -e "${YELLOW}No local repositories found in current directory.${NC}"
        return 1
    fi
    
    echo -e "${BLUE}Your local repositories:${NC}"
    for i in "${!local_repos[@]}"; do
        echo -e "$(($i+1))) ${local_repos[$i]}"
    done
    
    return 0
}

# Function to select a local repository
select_local_repository() {
    echo -e "${BLUE}\nEnter the number of the local repository:${NC}"
    read -r local_selection

    # Validate selection
    if ! [[ "$local_selection" =~ ^[0-9]+$ ]] || [ "$local_selection" -lt 1 ] || [ "$local_selection" -gt ${#local_repos[@]} ]; then
        echo -e "${YELLOW}Invalid selection.${NC}"
        return 1
    fi

    # Get the repository name from the selection
    local_selection=$((local_selection-1))  # Convert to zero-based index
    local_repo_name="${local_repos[$local_selection]}"
    
    return 0
}

# Function to detect project type and suggest startup command
detect_project_type() {
    local repo_dir="$1"
    cd "$repo_dir" || exit
    
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
        start_command="docker build -t $(basename "$repo_dir") . && docker run -p 8080:8080 $(basename "$repo_dir")"
    else
        start_command="# Could not determine how to start this project"
    fi

    # Print the command to start the project
    echo -e "${BLUE}To start the project, you can try:${NC}"
    echo -e "${GREEN}cd $(basename "$repo_dir") && $start_command${NC}"

    echo -e "${YELLOW}Note: The start command is a best guess based on project files.${NC}"
    echo -e "${YELLOW}You may need to adjust it depending on the specific project structure.${NC}"
}

# Clone repository function
clone_repository() {
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
    detect_project_type "$repo_name"
}

# Update local repository function
update_local_repository() {
    echo -e "${BLUE}Updating local repository: ${YELLOW}$local_repo_name${NC}"
    
    # Enter the repository directory
    cd "$local_repo_name" || exit
    
    # Check if there are uncommitted changes
    if ! git diff --quiet || ! git diff --staged --quiet; then
        echo -e "${YELLOW}You have uncommitted changes in this repository.${NC}"
        echo -e "${BLUE}Do you want to stash these changes before updating? (y/n)${NC}"
        read -r stash_choice
        
        if [[ "$stash_choice" =~ ^[Yy]$ ]]; then
            git stash
            echo -e "${GREEN}Changes stashed successfully.${NC}"
        else
            echo -e "${YELLOW}Continuing with uncommitted changes. This may cause conflicts.${NC}"
        fi
    fi
    
    # Fetch and pull updates
    echo -e "${BLUE}Fetching updates from remote...${NC}"
    git fetch origin
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to fetch updates.${NC}"
        cd ..
        return 1
    fi
    
    current_branch=$(git symbolic-ref --short HEAD)
    echo -e "${BLUE}Pulling updates for branch: ${YELLOW}$current_branch${NC}"
    
    git pull origin "$current_branch"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to pull updates. There might be conflicts.${NC}"
        cd ..
        return 1
    fi
    
    echo -e "${GREEN}Repository updated successfully!${NC}"
    
    # Return to the parent directory
    cd ..
    return 0
}

# Replace local repository function
replace_local_repository() {
    echo -e "${BLUE}Replacing local repository: ${YELLOW}$local_repo_name${NC}"
    
    # Confirm the replacement
    echo -e "${RED}WARNING: This will delete the local repository and replace it with a fresh clone.${NC}"
    echo -e "${RED}All local changes will be lost. Continue? (y/n)${NC}"
    read -r replace_confirm
    
    if ! [[ "$replace_confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Operation cancelled.${NC}"
        return 1
    fi
    
    # Get the remote URL of the repository
    remote_url=$(cd "$local_repo_name" && git remote get-url origin)
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to get remote URL.${NC}"
        return 1
    fi
    
    # Delete the local repository
    echo -e "${BLUE}Deleting local repository...${NC}"
    rm -rf "$local_repo_name"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to delete local repository.${NC}"
        return 1
    fi
    
    # Clone the repository again
    echo -e "${BLUE}Cloning repository from: ${YELLOW}$remote_url${NC}"
    git clone "$remote_url" "$local_repo_name"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to clone the repository.${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Repository replaced successfully!${NC}"
    
    # Detect project type and suggest startup command
    detect_project_type "$local_repo_name"
    
    return 0
}

# Push to GitHub function
push_to_github() {
    echo -e "${BLUE}Pushing local repository to GitHub: ${YELLOW}$local_repo_name${NC}"
    
    # Enter the repository directory
    cd "$local_repo_name" || exit
    
    # Check if there are uncommitted changes
    if ! git diff --quiet || ! git diff --staged --quiet; then
        echo -e "${YELLOW}You have uncommitted changes.${NC}"
        echo -e "${BLUE}Do you want to commit these changes? (y/n)${NC}"
        read -r commit_choice
        
        if [[ "$commit_choice" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Enter a commit message:${NC}"
            read -r commit_message
            
            # Stage all changes
            git add -A
            
            # Commit the changes
            git commit -m "$commit_message"
            
            if [ $? -ne 0 ]; then
                echo -e "${RED}Failed to commit changes.${NC}"
                cd ..
                return 1
            fi
            
            echo -e "${GREEN}Changes committed successfully.${NC}"
        else
            echo -e "${YELLOW}Continuing without committing changes.${NC}"
        fi
    fi
    
    # Check the current branch
    current_branch=$(git symbolic-ref --short HEAD)
    echo -e "${BLUE}Current branch: ${YELLOW}$current_branch${NC}"
    
    # Ask if the user wants to push to a different branch
    echo -e "${BLUE}Push to branch $current_branch? (y/n)${NC}"
    read -r branch_choice
    
    push_branch="$current_branch"
    
    if ! [[ "$branch_choice" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Enter the name of the branch to push to:${NC}"
        read -r push_branch
    fi
    
    # Push the changes
    echo -e "${BLUE}Pushing to branch: ${YELLOW}$push_branch${NC}"
    git push origin "$current_branch:$push_branch"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to push changes.${NC}"
        cd ..
        return 1
    fi
    
    echo -e "${GREEN}Changes pushed to GitHub successfully!${NC}"
    
    # Return to the parent directory
    cd ..
    return 0
}

# Main menu function
show_main_menu() {
    echo -e "${BLUE}====================================${NC}"
    echo -e "${BLUE}What would you like to do?${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo -e "1) Clone a GitHub repository"
    echo -e "2) Update a local repository"
    echo -e "3) Replace a local repository"
    echo -e "4) Push changes to GitHub"
    echo -e "0) Exit"
    echo -e "${BLUE}====================================${NC}"
    
    echo -e "${BLUE}Enter your choice:${NC}"
    read -r menu_choice
    
    case $menu_choice in
        1)
            # Clone repository mode
            fetch_repositories
            display_repositories
            select_repository
            clone_repository
            ;;
        2)
            # Update local repository mode
            if find_local_repos && select_local_repository; then
                update_local_repository
            fi
            ;;
        3)
            # Replace local repository mode
            if find_local_repos && select_local_repository; then
                replace_local_repository
            fi
            ;;
        4)
            # Push to GitHub mode
            if find_local_repos && select_local_repository; then
                push_to_github
            fi
            ;;
        0)
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${YELLOW}Invalid choice.${NC}"
            ;;
    esac
}

# Execute the main menu
show_main_menu