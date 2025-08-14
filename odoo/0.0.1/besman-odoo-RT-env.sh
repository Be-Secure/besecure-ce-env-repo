#!/bin/bash

__besman_install() {
    # Check if the required directories exist
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "The clone path already contains dir named $BESMAN_ARTIFACT_NAME"
    else
        echo "Cloning source code repo from $BESMAN_ARTIFACT_URL"
        git clone "$BESMAN_ARTIFACT_URL" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Check and install Docker
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed. Installing Docker..."
        sudo apt update
        sudo apt install -y ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        sudo systemctl restart docker
    else
        echo "Docker is already installed."
    fi

    # Check and install Go for criticality_score
    if ! command -v go &>/dev/null; then
        echo "Installing Go..."
        sudo snap install go --classic
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    else
        echo "Go is already available."
    fi

    # Install assessment tools
    IFS=',' read -r -a ASSESSMENT_TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"
    for tool in "${ASSESSMENT_TOOLS[@]}"; do
        case $tool in
        criticality_score)
            if ! command -v criticality_score &>/dev/null; then
                echo "Installing criticality_score..."
                go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            else
                echo "criticality_score is already available."
            fi
            ;;
        sonarqube)
            if [ "$(docker ps -aq -f name=sonarqube-$BESMAN_ARTIFACT_NAME)" ]; then
                docker stop sonarqube-$BESMAN_ARTIFACT_NAME
                docker container rm --force sonarqube-$BESMAN_ARTIFACT_NAME
            fi
            docker create --name sonarqube-$BESMAN_ARTIFACT_NAME -p 9000:9000 sonarqube
            docker start sonarqube-$BESMAN_ARTIFACT_NAME
            ;;
        fossology)
            if [ "$(docker ps -aq -f name=fossology-$BESMAN_ARTIFACT_NAME)" ]; then
                docker stop fossology-$BESMAN_ARTIFACT_NAME
                docker container rm --force fossology-$BESMAN_ARTIFACT_NAME
            fi
            docker create --name fossology-$BESMAN_ARTIFACT_NAME -p 8081:80 fossology/fossology
            docker start fossology-$BESMAN_ARTIFACT_NAME
            ;;
        spdx-sbom-generator)
            echo "Installing spdx-sbom-generator..."
            curl -L -o $BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"
            tar -xzf $BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz -C $BESMAN_ARTIFACT_DIR
            ;;
        snyk)
            if ! command -v snyk &>/dev/null; then
                echo "Installing Snyk..."
                npm install -g snyk
            else
                echo "Snyk is already available."
            fi
            ;;
        *)
            echo "No installation steps found for $tool."
            ;;
        esac
    done
}

__besman_uninstall() {
    # Remove the cloned source code
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        echo "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi

    # Uninstall assessment tools
    for tool in "${ASSESSMENT_TOOLS[@]}"; do
        case $tool in
        criticality_score)
            if command -v criticality_score &>/dev/null; then
                go install github.com/ossf/criticality_score/v2/cmd/criticality_score@none
                rm -rf $GOPATH/bin/criticality_score
            fi
            ;;
        sonarqube)
            if [ "$(docker ps -aq -f name=sonarqube-$BESMAN_ARTIFACT_NAME)" ]; then
                docker stop sonarqube-$BESMAN_ARTIFACT_NAME
                docker container rm --force sonarqube-$BESMAN_ARTIFACT_NAME
            fi
            ;;
        fossology)
            if [ "$(docker ps -aq -f name=fossology-$BESMAN_ARTIFACT_NAME)" ]; then
                docker stop fossology-$BESMAN_ARTIFACT_NAME
                docker container rm --force fossology-$BESMAN_ARTIFACT_NAME
            fi
            ;;
        spdx-sbom-generator)
            rm -f $BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz
            rm -rf $BESMAN_ARTIFACT_DIR/spdx-sbom-generator*
            ;;
        snyk)
            npm uninstall -g snyk
            ;;
        *)
            echo "No uninstallation steps found for $tool."
            ;;
        esac
    done

    # Remove Docker if installed
    if command -v docker &>/dev/null; then
        sudo apt purge -y docker-ce docker-ce-cli containerd.io
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo deluser $USER docker
        sudo groupdel docker
        sudo apt update
    fi

    # Remove Go if installed
    if command -v go &>/dev/null; then
        sudo snap remove go -y
    fi

    # Clean up unused packages
    sudo apt autoremove -y
}

__besman_update() {
    echo "Updating environment..."
    # Add update logic here
}

__besman_reset() {
    echo "Resetting environment to default state..."
    # Add reset logic here
}

__besman_validate() {
    echo "Validating environment setup..."

    local validationStatus=1
    declare -a errors

    # Validate Docker installation
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed."
        validationStatus=0
        errors+=("Docker")
    fi

    # Validate Docker containers
    if [ ! "$(docker ps -q -f name=sonarqube-$BESMAN_ARTIFACT_NAME)" ]; then
        echo "The sonarqube-$BESMAN_ARTIFACT_NAME container is not running."
        validationStatus=0
        errors+=("Docker container - sonarqube-$BESMAN_ARTIFACT_NAME is not running")
    fi

    if [ ! "$(docker ps -q -f name=fossology-$BESMAN_ARTIFACT_NAME)" ]; then
        echo "The fossology-$BESMAN_ARTIFACT_NAME container is not running."
        validationStatus=0
        errors+=("Docker container - fossology-$BESMAN_ARTIFACT_NAME is not running")
    fi

    # Validate Go installation
    if ! command -v go &>/dev/null; then
        echo "Go is not installed."
        validationStatus=0
        errors+=("Go")
    fi

    # Validate criticality_score installation
    if ! command -v criticality_score &>/dev/null; then
        echo "criticality_score is not installed."
        validationStatus=0
        errors+=("criticality_score")
    fi

    echo "Validation errors: ${errors[@]}"
}