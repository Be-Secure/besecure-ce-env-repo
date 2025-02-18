#!/bin/bash
# Set up color variables for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
# Environment variables
export BESMAN_USER_NAMESPACE="scikit-learn"
export BESMAN_ARTIFACT_NAME="scikit-learn"
export BESMAN_ARTIFACT_VERSION="main" # or specific version
export BESMAN_ARTIFACT_DIR="$HOME/scikit-learn"
export BESMAN_ASSESSMENT_DATASTORE_DIR="$HOME/assessment-datastore-scikit-learn"
export BESMAN_ASSESSMENT_TOOLS="criticality_score,sonarqube,fossology,spdx-sbom-generator"
export BESMAN_SPDX_SBOM_ASSET_URL="https://github.com/ossf/spdx-sbom-generator/releases/download/v0.0.15/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz"
function __besman_check_vcsExist() {
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed.${NC}"
        return 1
    fi
    return 0
}

function __besman_check_github_id {
    # Check if BESMAN_USER_NAMESPACE is set correctly
    if [ -z "$BESMAN_USER_NAMESPACE" ]; then
        echo -e "${RED}Error: BESMAN_USER_NAMESPACE is not set.${NC}"
        return 1
    fi
    return 0
}

function __besman_check_for_ansible {
    # For this script, we'll skip Ansible checks as we're using Docker
    return 0
}

function __besman_install {
    # Check if required hyperparameters are passed or set correctly
    __besman_check_vcsExist || return 1
    __besman_check_github_id || return 1

    echo -e "${BLUE}Installing Scikit-Learn security assessment environment...${NC}"

    # Clone the source code repo
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo -e "${BLUE}The clone path already contains dir name: $BESMAN_ARTIFACT_NAME${NC}"
    else
        echo -e "${BLUE}Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME${NC}"
        git clone https://github.com/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME.git "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "besecure_$BESMAN_ARTIFACT_VERSION" "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Clone the assessment datastore repo
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo -e "${BLUE}Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR${NC}"
    else
        echo -e "${BLUE}Cloning assessment datastore from $BESMAN_USER_NAMESPACE/besecure-assessment-datastore${NC}"
        git clone https://github.com/$BESMAN_USER_NAMESPACE/besecure-assessment-datastore "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    fi

    # Install system dependencies
    echo -e "${BLUE}Installing system dependencies...${NC}"
    {
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose python3 python3-pip
    } && echo -e "${GREEN}System dependencies installed successfully${NC}" || {
        echo -e "${RED}Failed to install system dependencies${NC}"
        return 1
    }

    # Install Python dependencies
    echo -e "${BLUE}Installing Python dependencies...${NC}"
    {
        pip3 install -U scikit-learn criticality_score sonarqube python-fossology spdx-sbom-generator
    } && echo -e "${GREEN}Python dependencies installed successfully${NC}" || {
        echo -e "${RED}Failed to install Python dependencies${NC}"
        return 1
    }

    # Install Docker if not installed
    if ! command -v docker &> /dev/null; then
        echo -e "${BLUE}Installing Docker...${NC}"
        {
            sudo apt-get install -y docker.io docker-compose
            sudo usermod -aG docker "$USER"
            newgrp docker
        } && echo -e "${GREEN}Docker installed successfully${NC}" || {
            echo -e "${RED}Failed to install Docker${NC}"
            return 1
        }
    fi

    # Start Docker
    sudo systemctl start docker

    # Install Go (required for criticality_score)
    if ! command -v go &> /dev/null; then
        echo -e "${BLUE}Installing Go...${NC}"
        {
            curl -fsSL https://golang.org/install | sh
            export GOPATH="$HOME/go"
            export PATH="$PATH:$GOPATH/bin"
        } && echo -e "${GREEN}Go installed successfully${NC}" || {
            echo -e "${RED}Failed to install Go${NC}"
            return 1
        }
    fi

    # Install assessment tools
    echo -e "${BLUE}Installing assessment tools...${NC}"
    if [ ! -z "$BESMAN_ASSESSMENT_TOOLS" ]; then
        IFS=',' read -r -a TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"
        for tool in "${TOOLS[@]}"; do
            case "$tool" in
            "criticality_score")
                if ! command -v criticality_score &> /dev/null; then
                    echo -e "${BLUE}Installing criticality_score...${NC}"
                    {
                        go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
                    } && echo -e "${GREEN}criticality_score installed successfully${NC}" || {
                        echo -e "${RED}Failed to install criticality_score${NC}"
                        return 1
                    }
                fi
                ;;
            "sonarqube")
                echo -e "${BLUE}Starting SonarQube container...${NC}"
                {
                    docker run -d --name sonarqube_scikit-learn sonarqube
                } && echo -e "${GREEN}SonarQube container started successfully${NC}" || {
                    echo -e "${RED}Failed to start SonarQube container${NC}"
                    return 1
                }
                ;;
            "fossology")
                echo -e "${BLUE}Starting Fossology container...${NC}"
                {
                    docker run -d --name fossology_scikit-learn fossology/fossology
                } && echo -e "${GREEN}Fossology container started successfully${NC}" || {
                    echo -e "${RED}Failed to start Fossology container${NC}"
                    return 1
                }
                ;;
            "spdx-sbom-generator")
                echo -e "${BLUE}Installing spdx-sbom-generator...${NC}"
                {
                    curl -L -o "$BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz" "$BESMAN_SPDX_SBOM_ASSET_URL"
                    tar -xzf "$BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz" -C "$BESMAN_ARTIFACT_DIR"
                } && echo -e "${GREEN}spdx-sbom-generator installed successfully${NC}" || {
                    echo -e "${RED}Failed to install spdx-sbom-generator${NC}"
                    return 1
                }
                ;;
            *)
                echo -e "${YELLOW}No installation steps found for $tool${NC}"
                ;;
            esac
        done
    fi

    echo -e "${GREEN}Scikit-Learn security assessment environment installed successfully${NC}"
}

function __besman_uninstall {
    # Stop and remove containers
    echo -e "${BLUE}Stopping and removing containers...${NC}"
    for container in sonarqube_scikit-learn fossology_scikit-learn; do
        if [ -n "$(docker ps -q -f name="$container")" ]; then
            echo -e "${BLUE}Stopping container: $container${NC}"
            docker stop "$container" || true
            echo -e "${BLUE}Removing container: $container${NC}"
            docker rm --force "$container" || true
        fi
    done

    # Remove cloned directories
    echo -e "${BLUE}Removing cloned directories...${NC}"
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo -e "${BLUE}Removing $BESMAN_ARTIFACT_DIR...${NC}"
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        echo -e "${YELLOW}Could not find dir: $BESMAN_ARTIFACT_DIR${NC}"
    fi

    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo -e "${BLUE}Removing $BESMAN_ASSESSMENT_DATASTORE_DIR...${NC}"
        rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        echo -e "${YELLOW}Could not find dir: $BESMAN_ASSESSMENT_DATASTORE_DIR${NC}"
    fi

    # Uninstall Go
    echo -e "${BLUE}Uninstalling Go...${NC}"
    {
        sudo apt-get remove -y golang
        unset GOPATH
        unset PATH
    } && echo -e "${GREEN}Go uninstalled successfully${NC}" || {
        echo -e "${RED}Failed to uninstall Go${NC}"
        return 1
    }

    # Uninstall Docker
    echo -e "${BLUE}Uninstalling Docker...${NC}"
    {
        sudo apt-get remove -y docker.io docker-compose
        sudo apt-get autoremove -y
        sudo rm -rf /var/lib/docker /var/lib/containerd
        sudo deluser "$USER" docker
        sudo groupdel docker
    } && echo -e "${GREEN}Docker uninstalled successfully${NC}" || {
        echo -e "${RED}Failed to uninstall Docker${NC}"
        return 1
    }

    # Uninstall Python packages
    echo -e "${BLUE}Uninstalling Python packages...${NC}"
    {
        pip3 uninstall -y scikit-learn criticality_score sonarqube python-fossology spdx-sbom-generator
    } && echo -e "${GREEN}Python packages uninstalled successfully${NC}" || {
        echo -e "${RED}Failed to uninstall Python packages${NC}"
        return 1
    }

    echo -e "${GREEN}Scikit-Learn security assessment environment uninstalled successfully${NC}"
}

function __besman_update {
    echo -e "${BLUE}Updating Scikit-Learn security assessment environment...${NC}"

    # Update system packages
    echo -e "${BLUE}Updating system packages...${NC}"
    {
        sudo apt-get update
        sudo apt-get upgrade -y
    } && echo -e "${GREEN}System packages updated successfully${NC}" || {
        echo -e "${RED}Failed to update system packages${NC}"
        return 1
    }

    # Update Python packages
    echo -e "${BLUE}Updating Python packages...${NC}"
    {
        pip3 install --upgrade scikit-learn criticality_score sonarqube python-fossology spdx-sbom-generator
    } && echo -e "${GREEN}Python packages updated successfully${NC}" || {
        echo -e "${RED}Failed to update Python packages${NC}"
        return 1
    }

    # Pull latest changes from repositories
    echo -e "${BLUE}Pulling latest changes from repositories...${NC}"
    {
        cd "$BESMAN_ARTIFACT_DIR" && git pull
        cd "$BESMAN_ASSESSMENT_DATASTORE_DIR" && git pull
    } && echo -e "${GREEN}Repositories updated successfully${NC}" || {
        echo -e "${RED}Failed to update repositories${NC}"
        return 1
    }

    # Restart containers
    echo -e "${BLUE}Restarting containers...${NC}"
    for container in sonarqube_scikit-learn fossology_scikit-learn; do
        echo -e "${BLUE}Restarting container: $container${NC}"
        {
            docker stop "$container" && docker start "$container"
        } || {
            echo -e "${RED}Failed to restart container: $container${NC}"
            return 1
        }
    done

    echo -e "${GREEN}Scikit-Learn security assessment environment updated successfully${NC}"
}

function __besman_validate {
    echo -e "${BLUE}Validating Scikit-Learn security assessment environment...${NC}"

    # Check Docker containers
    echo -e "${BLUE}Checking Docker containers...${NC}"
    for container in sonarqube_scikit-learn fossology_scikit-learn; do
        if ! docker ps -q -f name="$container" > /dev/null; then
            echo -e "${RED}Container $container is not running${NC}"
            return 1
        fi
    done

    # Check Python packages
    echo -e "${BLUE}Checking Python packages...${NC}"
    if ! pip3 list | grep -E 'scikit-learn|criticality_score|sonarqube|python-fossology|spdx-sbom-generator' > /dev/null; then
        echo -e "${RED}Missing required Python packages${NC}"
        return 1
    fi

    # Check Go
    if ! command -v go &> /dev/null; then
        echo -e "${RED}Go is not installed${NC}"
        return 1
    fi

    # Check criticality_score
    if ! command -v criticality_score &> /dev/null; then
        echo -e "${RED}criticality_score is not installed${NC}"
        return 1
    fi

    # Check repository directories
    echo -e "${BLUE}Checking repository directories...${NC}"
    if [[ ! -d "$BESMAN_ARTIFACT_DIR" ]] || [[ ! -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo -e "${RED}Missing repository directories${NC}"
        return 1
    fi

    echo -e "${GREEN}Scikit-Learn security assessment environment validation passed successfully${NC}"
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

    echo -e "${GREEN}Scikit-Learn security assessment environment reset successfully${NC}"
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