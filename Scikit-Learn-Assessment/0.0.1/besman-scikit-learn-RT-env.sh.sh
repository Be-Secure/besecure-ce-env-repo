#!/bin/bash

# Environment variables
export BESMAN_USER_NAMESPACE="Be-Secure"
export BESMAN_ARTIFACT_NAME="scikit-learn"
export BESMAN_ARTIFACT_VERSION="main" # or specific version
export BESMAN_ARTIFACT_DIR="$HOME/scikit-learn"
export BESMAN_ASSESSMENT_DATASTORE_DIR="$HOME/assessment-datastore-scikit-learn"
export BESMAN_ASSESSMENT_TOOLS="criticality_score,sonarqube,fossology,spdx-sbom-generator"
export BESMAN_SPDX_SBOM_ASSET_URL="https://github.com/ossf/spdx-sbom-generator/releases/download/v0.0.15/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz"

function __besman_check_vcsExist() {
    # Check if git is installed
    if ! command -v git &> /dev/null; then
        echo "Error: git is not installed."
        return 1
    fi
    return 0
}

function __besman_check_github_id {
    # Check if BESMAN_USER_NAMESPACE is set correctly
    if [ -z "$BESMAN_USER_NAMESPACE" ]; then
        echo "Error: BESMAN_USER_NAMESPACE is not set."
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

    echo "Installing Scikit-Learn security assessment environment..."

    # Clone the source code repo
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "The clone path already contains dir name: $BESMAN_ARTIFACT_NAME"
    else
        echo "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        git clone https://github.com/$BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME.git "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "besecure_$BESMAN_ARTIFACT_VERSION" "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Clone the assessment datastore repo
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        echo "Cloning assessment datastore from $BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        git clone https://github.com/$BESMAN_USER_NAMESPACE/besecure-assessment-datastore "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    fi

    # Install system dependencies
    echo "Installing system dependencies..."
    {
        sudo apt-get update
        sudo apt-get install -y docker.io docker-compose python3 python3-pip
    } && echo "System dependencies installed successfully" || {
        echo "Failed to install system dependencies"
        return 1
    }

    # Install Python dependencies
    echo "Installing Python dependencies..."
    {
        pip3 install -U scikit-learn criticality_score
    } && echo "Python dependencies installed successfully" || {
        echo "Failed to install Python dependencies"
        return 1
    }

    # Install Docker if not installed
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        {
            sudo apt-get install -y docker.io docker-compose
            sudo usermod -aG docker "$USER"
            newgrp docker
        } && echo "Docker installed successfully" || {
            echo "Failed to install Docker"
            return 1
        }
    fi

    # Start Docker
    sudo systemctl start docker

    # Install Go (required for criticality_score)
    if ! command -v go &> /dev/null; then
        echo "Installing Go..."
        {
            curl -fsSL https://golang.org/install | sh
            export GOPATH="$HOME/go"
            export PATH="$PATH:$GOPATH/bin"
        } && echo "Go installed successfully" || {
            echo "Failed to install Go"
            return 1
        }
    fi

    # Install assessment tools
    echo "Installing assessment tools..."
    if [ ! -z "$BESMAN_ASSESSMENT_TOOLS" ]; then
        IFS=',' read -r -a TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"
        for tool in "${TOOLS[@]}"; do
            case "$tool" in
            "criticality_score")
                if ! command -v criticality_score &> /dev/null; then
                    echo "Installing criticality_score..."
                    {
                        go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
                    } && echo "criticality_score installed successfully" || {
                        echo "Failed to install criticality_score"
                        return 1
                    }
                fi
                ;;
            "sonarqube")
                echo "Starting SonarQube container..."
                {
                    docker run -d --name sonarqube_scikit-learn sonarqube
                } && echo "SonarQube container started successfully" || {
                    echo "Failed to start SonarQube container"
                    return 1
                }
                ;;
            "fossology")
                echo "Starting Fossology container..."
                {
                    docker run -d --name fossology_scikit-learn fossology/fossology
                } && echo "Fossology container started successfully" || {
                    echo "Failed to start Fossology container"
                    return 1
                }
                ;;
            "spdx-sbom-generator")
                echo "Installing sbom-tool..."
                {
                    curl -Lo sbom-tool https://github.com/microsoft/sbom-tool/releases/latest/download/sbom-tool-linux-x64
                } && echo "spdx-sbom-generator installed successfully" || {
                    echo "Failed to install spdx-sbom-generator"
                    return 1
                }
                ;;
            *)
                echo "No installation steps found for $tool"
                ;;
            esac
        done
    fi

    echo "Scikit-Learn security assessment environment installed successfully"
}

function __besman_uninstall {
    # Stop and remove containers
    echo "Stopping and removing containers..."
    for container in sonarqube_scikit-learn fossology_scikit-learn; do
        if [ -n "$(docker ps -q -f name="$container")" ]; then
            echo "Stopping container: $container"
            docker stop "$container" || true
            echo "Removing container: $container"
            docker rm --force "$container" || true
        fi
    done

    # Remove cloned directories
    echo "Removing cloned directories..."
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        echo "Could not find dir: $BESMAN_ARTIFACT_DIR"
    fi

    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo "Removing $BESMAN_ASSESSMENT_DATASTORE_DIR..."
        rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        echo "Could not find dir: $BESMAN_ASSESSMENT_DATASTORE_DIR"
    fi

    # Uninstall Go
    echo "Uninstalling Go..."
    {
        sudo apt-get remove -y golang
        unset GOPATH
        unset PATH
    } && echo "Go uninstalled successfully" || {
        echo "Failed to uninstall Go"
        return 1
    }

    # Uninstall Docker
    {
        /usr/bin/sudo apt-get remove -y docker.io docker-compose
        /usr/bin/sudo apt-get autoremove -y
        /usr/bin/sudo rm -rf /var/lib/docker /var/lib/containerd
        /usr/bin/sudo deluser "$USER" docker
        /usr/bin/sudo groupdel docker
    } && echo "Docker uninstalled successfully" || {
        echo "Failed to uninstall Docker"
        return 1
    }

    # Uninstall Python packages
    echo "Uninstalling Python packages..."
    {
        pip3 uninstall -y scikit-learn criticality_score
    } && echo "Python packages uninstalled successfully" || {
        echo "Failed to uninstall Python packages"
        return 1
    }

    echo "Scikit-Learn security assessment environment uninstalled successfully"
}

function __besman_update {
    echo "Updating Scikit-Learn security assessment environment..."

    # Update system packages
    echo "Updating system packages..."
    {
        sudo apt-get update
        sudo apt-get upgrade -y
    } && echo "System packages updated successfully" || {
        echo "Failed to update system packages"
        return 1
    }

    # Update Python packages
    echo "Updating Python packages..."
    {
        pip3 install --upgrade scikit-learn criticality_score sonarqube python-fossology spdx-sbom-generator
    } && echo "Python packages updated successfully" || {
        echo "Failed to update Python packages"
        return 1
    }

    # Pull latest changes from repositories
    echo "Pulling latest changes from repositories..."
    {
        cd "$BESMAN_ARTIFACT_DIR" && git pull
        cd "$BESMAN_ASSESSMENT_DATASTORE_DIR" && git pull
    } && echo "Repositories updated successfully" || {
        echo "Failed to update repositories"
        return 1
    }

    # Restart containers
    echo "Restarting containers..."
    for container in sonarqube_scikit-learn fossology_scikit-learn; do
        echo "Restarting container: $container"
        {
            docker stop "$container" && docker start "$container"
        } || {
            echo "Failed to restart container: $container"
            return 1
        }
    done

    echo "Scikit-Learn security assessment environment updated successfully"
}

function __besman_validate {
    echo "Validating Scikit-Learn security assessment environment..."

    # Check Docker containers
    echo "Checking Docker containers..."
    for container in sonarqube_scikit-learn fossology_scikit-learn; do
        if ! docker ps -q -f name="$container" > /dev/null; then
            echo "Container $container is not running"
            return 1
        fi
    done

    # Check Python packages
    echo "Checking Python packages..."
    if ! pip3 list | grep -E 'scikit-learn|criticality_score|sonarqube|python-fossology|spdx-sbom-generator' > /dev/null; then
        echo "Missing required Python packages"
        return 1
    fi

    # Check Go
    if ! command -v go &> /dev/null; then
        echo "Go is not installed"
        return 1
    fi

    # Check criticality_score
    if ! command -v criticality_score &> /dev/null; then
        echo "criticality_score is not installed"
        return 1
    fi

    # Check repository directories
    echo "Checking repository directories..."
    if [[ ! -d "$BESMAN_ARTIFACT_DIR" ]] || [[ ! -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo "Missing repository directories"
        return 1
    fi

    echo "Scikit-Learn security assessment environment validation passed successfully"
}

function __besman_reset {
    echo "Resetting Scikit-Learn security assessment environment..."

    # Uninstall existing environment
    __besman_uninstall || {
        echo "Failed to uninstall existing environment"
        return 1
    }

    # Reinstall environment
    __besman_install || {
        echo "Failed to reinstall environment"
        return 1
    }

    echo "Scikit-Learn security assessment environment reset successfully"
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
