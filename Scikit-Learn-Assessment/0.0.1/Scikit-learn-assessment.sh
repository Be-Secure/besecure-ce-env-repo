#!/bin/bash

# Set up color variables for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Define functions

function __besman_install {
    echo -e "${BLUE}Installing Scikit-Learn security assessment environment...${NC}"
    
    # Install system dependencies
    echo -e "${BLUE}Installing system dependencies...${NC}"
    {
        sudo apt-get update
        sudo apt-get install -y python3-dev python3-pip git
    } && echo -e "${GREEN}System dependencies installed successfully${NC}" || {
        echo -e "${RED}Failed to install system dependencies${NC}" 
        return 1
    }
    
    # Install Python dependencies
    echo -e "${BLUE}Installing Python packages...${NC}"
    {
        pip3 install -U scikit-learn criticality_score sonarqube fossology spdx-sbom-generator
    } && echo -e "${GREEN}Python packages installed successfully${NC}" || {
        echo -e "${RED}Failed to install Python packages${NC}" 
        return 1
    }

    # Clone repositories
    echo -e "${BLUE}Cloning source code and assessment datastore repositories...${NC}"
    {
        git clone https://github.com/scikit-learn/scikit-learn.git
        git clone https://github.com/besecure/assessment-datastore.git
    } && echo -e "${GREEN}Repositories cloned successfully${NC}" || {
        echo -e "${RED}Failed to clone repositories${NC}" 
        return 1
    }

    echo -e "${GREEN}Installation completed successfully${NC}"
}

function __besman_uninstall {
    echo -e "${BLUE}Uninstalling Scikit-Learn security assessment environment...${NC}"
    
    # Uninstall Python packages
    echo -e "${BLUE}Uninstalling Python packages...${NC}"
    {
        pip3 uninstall -y criticality_score sonarqube fossology spdx-sbom-generator
    } && echo -e "${GREEN}Python packages uninstalled successfully${NC}" || {
        echo -e "${RED}Failed to uninstall Python packages${NC}" 
        return 1
    }

    # Remove repositories
    echo -e "${BLUE}Removing cloned repositories...${NC}"
    {
        rm -rf scikit-learn assessment-datastore
    } && echo -e "${GREEN}Repositories removed successfully${NC}" || {
        echo -e "${RED}Failed to remove repositories${NC}" 
        return 1
    }

    echo -e "${GREEN}Uninstallation completed successfully${NC}"
}

function __besman_update {
    echo -e "${BLUE}Updating Scikit-Learn security assessment environment...${NC}"
    
    # Update Python packages
    echo -e "${BLUE}Updating Python packages...${NC}"
    {
        pip3 install --upgrade scikit-learn criticality_score sonarqube fossology spdx-sbom-generator
    } && echo -e "${GREEN}Python packages updated successfully${NC}" || {
        echo -e "${RED}Failed to update Python packages${NC}" 
        return 1
    }

    # Pull latest changes from repositories
    echo -e "${BLUE}Pulling latest changes from repositories...${NC}"
    {
        cd scikit-learn && git pull && cd ..
        cd assessment-datastore && git pull && cd ..
    } && echo -e "${GREEN}Repositories updated successfully${NC}" || {
        echo -e "${RED}Failed to update repositories${NC}" 
        return 1
    }

    echo -e "${GREEN}Update completed successfully${NC}"
}

function __besman_validate {
    echo -e "${BLUE}Validating Scikit-Learn security assessment environment...${NC}"
    
    # Check Python packages installation
    echo -e "${BLUE}Checking Python package installations...${NC}"
    pip3 list | grep -E 'criticality_score|sonarqube|fossology|spdx-sbom-generator' > /dev/null
    if [ $? -ne 0 ]; then
        echo -e "${RED}Missing Python packages${NC}"
        return 1
    fi

    # Check repository structure
    echo -e "${BLUE}Checking repository structure...${NC}"
    if [ ! -d "scikit-learn" ] || [ ! -d "assessment-datastore" ]; then
        echo -e "${RED}Missing repository directories${NC}"
        return 1
    fi

    echo -e "${GREEN}Environment validation passed successfully${NC}"
}

function __besman_reset {
    echo -e "${BLUE}Resetting Scikit-Learn security assessment environment...${NC}"
    
    # Uninstall existing environment
    __besman_uninstall || {
        echo -e "${RED}Failed to uninstall existing environment${NC}"
        return 1
    }

    # Reinstall environment
    __besman_install || {
        echo -e "${RED}Failed to reinstall environment${NC}"
        return 1
    }

    echo -e "${GREEN}Environment reset completed successfully${NC}"
}

# Main script execution
case "$1" in
    "install")
        __besman_install
        ;;
    "uninstall")
        __besman_uninstall
        ;;
    "update")
        __besman_update
        ;;
    "validate")
        __besman_validate
        ;;
    "reset")
        __besman_reset
        ;;
    *)
        echo "Usage: $0 {install|uninstall|update|validate|reset}"
        exit 1
        ;;
esac