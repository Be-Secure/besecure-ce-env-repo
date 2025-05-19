#!/bin/bash
function __besman_install {
    __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1 # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    __besman_echo_white "==> Installing assessment environment..."

    # Ensure Docker
    if ! command -v docker &>/dev/null; then
        __besman_echo_white "Installing Docker..."
        sudo apt update && sudo apt install -y ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER && newgrp docker
    else
        __besman_echo_white "Docker already installed."
    fi

    # Ensure snapd
    if ! command -v snap &>/dev/null; then
        __besman_echo_white "Installing snapd..."
        sudo apt update && sudo apt install -y snapd
    else
        __besman_echo_white "snapd already installed."
    fi

    # Ensure Go
    if ! command -v go &>/dev/null; then
        __besman_echo_white "Installing Go..."
        sudo snap install go --classic
        echo "export PATH=\$PATH:$HOME/go/bin" >> ~/.bashrc
        source ~/.bashrc
    else
        __besman_echo_white "Go already installed."
    fi

    # Install each assessment tool
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        scorecard)
            __besman_echo_white "Pulling Scorecard image..."
            curl -L -o "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" "$BESMAN_SCORECARD_ASSET_URL"
            tar -xzf "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            chmod +x "$HOME/scorecard"
            sudo mv "$HOME/scorecard" /usr/local/bin/
            [[ -f "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" ]] && rm "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            [[ -z $(which scorecard) ]] && __besman_echo_error "Scorecard installation failed." && return 1
            ;;
        criticality_score)
            __besman_echo_white "Installing Criticality Score CLI..."
            go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            [[ -z $(which criticality_score) ]] && __besman_echo_error "criticality_score installation failed." && return 1
            ;;
        sonarqube)
            container="sonarqube-$BESMAN_ARTIFACT_NAME"
            __besman_echo_white "Setting up SonarQube container: $container..."
            sudo docker rm -f $container 2>/dev/null || true
            # docker run -d --name $container -p ${BESMAN_SONARQUBE_PORT}:9000 sonarqube:latest
            sudo docker pull sonarqube:latest
            sudo curl -L "$BESMAN_SONAR_SCANNER_ASSET_URL" -o "$BESMAN_TOOL_PATH/sonar-scanner-cli.zip"
            sudo unzip "$BESMAN_TOOL_PATH/sonar-scanner-cli.zip" -d "$BESMAN_TOOL_PATH"
            sudo mv "$BESMAN_TOOL_PATH/sonar-scanner-$BESMAN_SONAR_SCANNER_VERSION-linux-x64" "$BESMAN_TOOL_PATH/sonar-scanner"
            echo "export PATH='$PATH:$BESMAN_TOOL_PATH/sonar-scanner/bin'" >> ~/.bashrc
            source ~/.bashrc
            [[ -z $(which sonar-scanner) ]] && __besman_echo_error "sonar scanner installation failed." && return 1
            ;;
        fossology)
            container="fossology-$BESMAN_ARTIFACT_NAME"
            __besman_echo_white "Setting up Fossology container: $container..."
            sudo docker rm -f $container 2>/dev/null || true
            sudo docker run -d --name $container -p ${BESMAN_FOSSOLOGY_PORT}:80 fossology/fossology:latest
            ;;
        spdx-sbom-generator)
            __besman_echo_white "Downloading SPDX SBOM Generator..."
            sudo curl -L -o "$BESMAN_TOOL_PATH/spdx-sbom-generator.tar.gz" "$BESMAN_SPDX_SBOM_ASSET_URL"
            sudo tar -xzf "$BESMAN_TOOL_PATH/spdx-sbom-generator.tar.gz" -C "$BESMAN_TOOL_PATH"
            ;;
        *)
            __besman_echo_warn "Unknown tool: $t"
            ;;
        esac
    done

    # Clones the source code repo.
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then

        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi
    __besman_echo_white "Installation complete."
}

function __besman_uninstall {
    __besman_echo_white "==> Uninstalling assessment environment..."

    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        scorecard)
            __besman_echo_white "Removing Scorecard..."
            [[ -f "/usr/local/bin/scorecard" ]] && sudo rm /usr/local/bin/scorecard
            ;;
        criticality_score)
            __besman_echo_white "Uninstalling Criticality Score CLI..."
            [[ -f "$(go env GOPATH)/bin/criticality_score" ]] && rm -f "$(go env GOPATH)/bin/criticality_score"
            ;;
        sonarqube)
            container="sonarqube-$BESMAN_ARTIFACT_NAME"
            __besman_echo_white "Removing SonarQube container: $container..."
            sudo docker rm -f $container || true
            ;;
        fossology)
            container="fossology-$BESMAN_ARTIFACT_NAME"
            __besman_echo_white "Removing Fossology container: $container..."
            sudo docker rm -f $container || true
            ;;
        spdx-sbom-generator)
            __besman_echo_white "Removing SPDX SBOM Generator files..."
            rm -f "$BESMAN_TOOL_PATH/spdx-sbom-generator.tar.gz"
            rm -rf "$BESMAN_TOOL_PATH/spdx-sbom-generator"
            ;;
        *)
            __besman_echo_warn "Unknown tool: $t"
            ;;
        esac
    done

    __besman_echo_white "Uninstallation complete."
}

function __besman_update {
    __besman_echo_white "==> Updating assessment tools to the latest available versions..."
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        scorecard)
            __besman_echo_white "Updating Scorecard image to stable..."
            curl -L -o "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" "$BESMAN_SCORECARD_ASSET_URL"
            tar -xzf "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            chmod +x "$HOME/scorecard"
            sudo mv "$HOME/scorecard" /usr/local/bin/
            [[ -f "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" ]] && rm "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            ;;
        criticality_score)
            __besman_echo_white "Updating Criticality Score CLI to latest..."
            go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            ;;
        sonarqube)
            container="sonarqube-$BESMAN_ARTIFACT_NAME"
            __besman_echo_white "Updating SonarQube container to latest..."
            sudo docker pull sonarqube:latest
            sudo docker rm -f $container 2>/dev/null || true
            sudo docker run -d --name $container -p ${BESMAN_SONARQUBE_PORT}:9000 sonarqube:latest
            ;;
        fossology)
            container="fossology-$BESMAN_ARTIFACT_NAME"
            __besman_echo_white "Updating Fossology container to latest..."
            sudo docker pull fossology/fossology:latest
            sudo docker rm -f $container 2>/dev/null || true
            sudo docker run -d --name $container -p ${BESMAN_FOSSOLOGY_PORT}:80 fossology/fossology:latest
            ;;
        spdx-sbom-generator)
            __besman_echo_white "Updating SPDX SBOM Generator to version from URL..."
            curl -L -o "$BESMAN_TOOL_PATH/spdx-sbom-generator-latest.tar.gz" "$BESMAN_SPDX_SBOM_ASSET_URL"
            rm -rf "$BESMAN_TOOL_PATH/spdx-sbom-generator"
            tar -xzf "$BESMAN_TOOL_PATH/spdx-sbom-generator-latest.tar.gz" -C "$BESMAN_TOOL_PATH"
            ;;
        *)
            __besman_echo_warn "Unknown tool: $t"
            ;;
        esac
    done
    __besman_echo_white "Update complete."
}

function __besman_validate {
    __besman_echo_white "==> Validating environment..."
    local status=0

    # Validate Docker
    if ! command -v docker &>/dev/null; then
        __besman_echo_error "Docker not found."
        status=1
    fi

    # Validate containers
    for svc in sonarqube fossology; do
        name="$svc-$BESMAN_ARTIFACT_NAME"
        if ! docker ps -q -f name=$name | grep -q .; then
            __besman_echo_error "Container $name is not running."
            status=1
        fi
    done
    [[ -z $(which sonar-scanner) ]] && __besman_echo_error "Sonar Scanner CLI not found." && status=1
    [[ -z $(which criticality_score) ]] && __besman_echo_error "Criticality Score CLI not found." && status=1
    # Validate Go CLI
    if ! command -v go &>/dev/null; then
        __besman_echo_error "Go not found."
        status=1
    fi
    [[ -z $(which scorecard) ]] && __besman_echo_error "Scorecard CLI not found." && status=1
 
    # Validate Criticality Score
    if ! command -v criticality_score &>/dev/null; then
        __besman_echo_error "criticality_score CLI not found."
        status=1
    fi

    if [[ $status -eq 0 ]]; then
        __besman_echo_white "Validation succeeded."
    else
        __besman_echo_error "Validation failed."
        exit 1
    fi
}

function __besman_reset {
    __besman_echo_white "==> Resetting environment to default state as defined by configuration..."
    # Remove all installed tools and containers
    __besman_uninstall
    # Re-install tools using current config versions
    __besman_install
    __besman_echo_white "Reset complete."
}
