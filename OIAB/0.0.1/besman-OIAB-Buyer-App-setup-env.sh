#!/bin/bash

function __besman_install_docker() {

    __besman_echo_no_colour "Checking if Docker is installed..."
    
    if command -v docker >/dev/null 2>&1; then
        __besman_echo_yellow "Docker is already installed"
        docker --version
    else
        __besman_echo_white "Docker not found. Installing Docker..."
        
        # Update package index
        sudo apt-get update
        
        # Install required packages
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release
            
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Set up stable repository
        echo \
          "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          
        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        
        # Start Docker service
        sudo systemctl start docker
        sudo systemctl enable docker
        
        # Add current user to docker group
        sudo usermod -aG docker $USER
        
        __besman_echo_yellow "Docker installed successfully!"
        docker --version
    fi
}

function __besman_install_buyer_ui()
{
    if [[ -d $BESMAN_OIAB_BUYER_UI_DIR ]]; then
        __besman_echo_white "Buyer ui code found"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_ORG/$BESMAN_OIAB_BUYER_UI"
        __besman_repo_clone "$BESMAN_ORG" "$BESMAN_OIAB_BUYER_UI" "$BESMAN_OIAB_BUYER_UI_DIR" || return 1
    fi
    cd "$BESMAN_OIAB_BUYER_UI_DIR" || return 1
    __besman_echo_white "Installing $BESMAN_OIAB_BUYER_UI"
    __besman_echo_yellow "Building OIAB buyer ui"
    sed -i "s/EXPOSE 80/EXPOSE 8001/g" Dockerfile
    sed -i "s/listen 80;/listen 8001;/g" nginx.conf
    docker build -t oiab-buyer-ui .
    docker run -d --name oiab-buyer-ui -p 8001:8001 oiab-buyer-ui
}

function __besman_install_buyer_app()
{
    if [[ -d $BESMAN_OIAB_BUYER_APP_DIR ]]; then
        __besman_echo_white "Buyer ui code found"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_ORG/$BESMAN_OIAB_BUYER_APP"
        __besman_repo_clone "$BESMAN_ORG" "$BESMAN_OIAB_BUYER_APP" "$BESMAN_OIAB_BUYER_APP_DIR" || return 1
    fi
    cd "$BESMAN_OIAB_BUYER_APP_DIR" || return 1
    __besman_echo_white "Installing $BESMAN_OIAB_BUYER_APP"
    __besman_echo_yellow "Building buyer app"
    docker-compose up --build -d
}

function __besman_install_docker_compose() {
    __besman_echo_no_colour "Checking if Docker Compose is installed..."
    
    if command -v docker-compose >/dev/null 2>&1; then
        __besman_echo_yellow "Docker Compose is already installed"
        docker-compose --version
    else
        __besman_echo_white "Docker Compose not found. Installing latest version..."
        
        # Download the latest version of Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/$BESMAN_DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        
        # Apply executable permissions
        sudo chmod +x /usr/local/bin/docker-compose
        
        __besman_echo_yellow "Docker Compose installed successfully!"
        docker-compose --version
    fi
}

function __besman_install
{
    # Checks if git/GitHub CLI is present or not.
    __besman_check_vcs_exist || return 1
    # # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE 
    # __besman_check_github_id || return 1 
    __besman_install_docker
    __besman_install_docker_compose
    __besman_install_buyer_ui || return 1
    __besman_install_buyer_app || return 1
}

function __besman_uninstall
{
    __besman_echo_white "Stopping and removing Docker containers..."

    docker stop "$(docker ps -a -q)"
    docker container rm "$(docker ps -a -q)"

    __besman_echo_white "Removing Docker images and volumes..."
    docker image rm "$(docker image ls -q)"
    docker volume rmm "$(docker volume ls -q)"

    __besman_echo_white "Cleaning up directories..."
    if [[ -d $BESMAN_OIAB_BUYER_UI_DIR ]]; then
        rm -rf "$BESMAN_OIAB_BUYER_UI_DIR"
        __besman_echo_yellow "Removed buyer UI directory"
    fi
    
    if [[ -d $BESMAN_OIAB_BUYER_APP_DIR ]]; then
        rm -rf "$BESMAN_OIAB_BUYER_APP_DIR"
        __besman_echo_yellow "Removed buyer app directory"
    fi
}

# function __besman_update
# {
#     # TODO: Implement update logic
# }

# function __besman_validate
# {
#     # TODO: Implement validate logic
# }

# function __besman_reset
# {
#     # TODO: Implement reset logic
# }


