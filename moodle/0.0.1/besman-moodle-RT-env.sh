#!/bin/bash

__besman_install() {
    # Prompt for project name
    read -p "Enter the project name (e.g., moodle): " BESMAN_ARTIFACT_NAME

    # Clone the source code repo
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "The clone path already contains dir named $BESMAN_ARTIFACT_NAME"
    else
        echo "Cloning source code repo from $BESMAN_ARTIFACT_URL"
        git clone "$BESMAN_ARTIFACT_URL" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Install Docker if not present
    if ! command -v docker &>/dev/null; then
        echo "Installing Docker..."
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        sudo systemctl restart docker
    fi

    # Install Go if not present
    if ! command -v go &>/dev/null; then
        echo "Installing Go..."
        sudo snap install go --classic
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    fi

    # Install assessment tools
    for tool in spdx-sbom-generator sonarqube criticality_score snyk fossology; do
        case $tool in
        criticality_score)
            if ! command -v criticality_score &>/dev/null; then
                echo "Installing criticality_score..."
                go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
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
            fi
            ;;
        esac
    done
}

__besman_uninstall() {
    # Remove cloned source code
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    fi

    # Uninstall assessment tools
    for tool in spdx-sbom-generator sonarqube criticality_score snyk fossology; do
        case $tool in
        criticality_score)
            if command -v criticality_score &>/dev/null; then
                echo "Uninstalling criticality_score..."
                go install github.com/ossf/criticality_score/v2/cmd/criticality_score@none
                rm -f $GOPATH/bin/criticality_score
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
            if command -v snyk &>/dev/null; then
                echo "Uninstalling Snyk..."
                npm uninstall -g snyk
            fi
            ;;
        esac
    done

    # Remove Docker if installed
    if command -v docker &>/dev/null; then
        echo "Removing Docker..."
        sudo apt purge -y docker-ce docker-ce-cli containerd.io
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo deluser $USER docker
        sudo groupdel docker
        sudo apt update
    fi

    # Remove Go if installed
    if command -v go &>/dev/null; then
        echo "Removing Go..."
        sudo snap remove go
    fi

    # Clean up unused packages
    sudo apt autoremove -y
}

__besman_update() {
    echo "Updating environment for $BESMAN_ARTIFACT_NAME..."

    # Update the source code repository
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "Updating the source code repository..."
        cd "$BESMAN_ARTIFACT_DIR" || return 1
        git fetch --all
        git checkout "$BESMAN_ARTIFACT_VERSION"
        git pull origin "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME" || return 1
    else
        echo "Source code directory does not exist. Please install the environment first."
        return 1
    fi

    # Update installed tools
    for tool in spdx-sbom-generator sonarqube criticality_score snyk fossology; do
        case $tool in
        criticality_score)
            echo "Updating criticality_score..."
            go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            ;;
        snyk)
            echo "Updating Snyk..."
            npm update -g snyk
            ;;
        # Add additional tool update commands here as needed
        esac
    done

    echo "Environment update completed."
}

__besman_reset() {
    echo "Resetting environment for $BESMAN_ARTIFACT_NAME..."

    __besman_uninstall
    __besman_install
}

__besman_validate() {
    echo "Validating environment..."
    # Validate Docker installation
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed."
    fi

    # Validate Go installation
    if ! command -v go &>/dev/null; then
        echo "Go is not installed."
    fi

    # Validate criticality_score installation
    if ! command -v criticality_score &>/dev/null; then
        echo "criticality_score is not installed."
    fi

    # Validate other tools
    # Code to validate other tools
}