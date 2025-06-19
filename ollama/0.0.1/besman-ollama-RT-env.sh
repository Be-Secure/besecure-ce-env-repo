#!/usr/bin/env bash

# Lifecycle function: Install environment
__besman_install() {

    __besman_echo_white "Installing environment for ollama POI..."

    # ----------- Clone source and datastore repos -----------
    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1

    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir $BESMAN_ARTIFACT_NAME"
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

    # ----------- Environment Dependencies -----------
    __besman_echo_white "Installing environment dependencies..."

    if ! command -v go &>/dev/null; then
        sudo snap install go --classic
    fi

    if ! command -v cmake &>/dev/null; then
        sudo apt-get update && sudo apt-get install -y cmake
    fi

    if ! command -v docker &>/dev/null; then
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
            sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker "$USER" && sudo systemctl restart docker
    fi

    if ! command -v snap &>/dev/null; then
        sudo apt-get install -y snapd
    fi

    if ! command -v node &>/dev/null || [[ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 18 ]]; then
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    # ----------- Assessment Tool Setup -----------
    IFS=',' read -ra tools <<<"$BESMAN_ASSESSMENT_TOOLS"

    for tool in "${tools[@]}"; do
        name=$(echo "$tool" | cut -d':' -f1)
        version=$(echo "$tool" | cut -d':' -f2)

        case "$name" in

        scorecard)
            __besman_echo_white "Installing scorecard..."
            mkdir -p /tmp/scorecard
            curl -L -o /tmp/scorecard/scorecard.tar.gz https://github.com/ossf/scorecard/releases/latest/download/scorecard-linux-amd64.tar.gz
            tar -xzf /tmp/scorecard/scorecard.tar.gz -C /tmp/scorecard
            chmod +x /tmp/scorecard/scorecard
            sudo mv /tmp/scorecard/scorecard /usr/local/bin/
            ;;

        criticality_score)
            __besman_echo_white "Installing criticality_score..."
            go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            ;;

        sonarqube)
            __besman_echo_white "Setting up SonarQube container..."
            docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name sonarqube-$BESMAN_ARTIFACT_NAME -p 9000:9000 sonarqube
            ;;

        fossology)
            __besman_echo_white "Setting up Fossology container..."
            docker rm -f fossology-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name fossology-$BESMAN_ARTIFACT_NAME -p 9001:80 fossology/fossology
            ;;

        spdx-sbom-generator)
            __besman_echo_white "Installing SPDX SBOM generator..."
            mkdir -p "$BESMAN_TOOL_PATH"
            curl -L "$BESMAN_SPDX_SBOM_ASSET_URL" -o /tmp/spdx.tar.gz
            tar -xzf /tmp/spdx.tar.gz -C "$BESMAN_TOOL_PATH"
            ;;

        cyclonedx-sbom-generator)
            __besman_echo_white "Installing CycloneDX SBOM generator..."
            if ! command -v cdxgen &>/dev/null; then
                npm install -g @cyclonedx/cdxgen
            fi
            sudo cp "$(which cdxgen)" /opt/cyclonedx-sbom-generator
            ;;

        *)
            __besman_echo_white "Unknown tool: $name"
            ;;
        esac
    done

    __besman_echo_white "Environment setup complete."
}

# Lifecycle function: Uninstall environment
__besman_uninstall() {

    __besman_echo_white "Starting uninstallation for POI: $BESMAN_ARTIFACT_NAME"

    # ---------------- Common Cleanup ----------------
    __besman_echo_white "Removing cloned artifact directory..."
    rm -rf "$BESMAN_ARTIFACT_DIR"

    __besman_echo_white "Removing assessment datastore directory..."
    rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    # ---------------- Stop and Remove Containers ----------------
    __besman_echo_white "Removing Docker containers if present..."
    docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME &>/dev/null
    docker rm -f fossology-$BESMAN_ARTIFACT_NAME &>/dev/null

    # ---------------- Remove Tools ----------------
    __besman_echo_white "Removing scorecard..."
    sudo rm -f /usr/local/bin/scorecard

    __besman_echo_white "Cleaning GOPATH-installed binaries..."
    [ -n "$GOPATH" ] && rm -f "$GOPATH/bin/criticality_score"

    __besman_echo_white "Removing SPDX SBOM generator (if path defined)..."
    rm -rf "$BESMAN_TOOL_PATH/spdx-sbom-generator" 2>/dev/null
    rm -rf "$BESMAN_TOOL_PATH" 2>/dev/null

    __besman_echo_white "Removing CycloneDX SBOM generator binary..."
    sudo rm -f /opt/cyclonedx-sbom-generator 2>/dev/null

    __besman_echo_white "Uninstallation completed for POI: $BESMAN_ARTIFACT_NAME"
}

# Lifecycle function: Validate environment
__besman_validate() {
    __besman_echo_white "Validating environment for POI: $BESMAN_ARTIFACT_NAME..."

    local missing_deps=()
    local available_deps=()

    # ---------------- Prerequisite Binaries ----------------
    for cmd in docker git node npm go curl; do
        if command -v "$cmd" &>/dev/null; then
            available_deps+=("$cmd")
        else
            missing_deps+=("$cmd")
        fi
    done

    # ---------------- Assessment Containers ----------------
    if docker ps -a --format '{{.Names}}' | grep -q "^sonarqube-$BESMAN_ARTIFACT_NAME$"; then
        available_deps+=("sonarqube-docker")
    else
        missing_deps+=("sonarqube-docker")
    fi

    if docker ps -a --format '{{.Names}}' | grep -q "^fossology-$BESMAN_ARTIFACT_NAME$"; then
        available_deps+=("fossology-docker")
    else
        missing_deps+=("fossology-docker")
    fi

    # ---------------- SBOM + Scorecard Tools ----------------
    if command -v scorecard &>/dev/null; then
        available_deps+=("scorecard")
    else
        missing_deps+=("scorecard")
    fi

    if command -v criticality_score &>/dev/null; then
        available_deps+=("criticality_score")
    else
        missing_deps+=("criticality_score")
    fi

    if command -v cdxgen &>/dev/null; then
        available_deps+=("cdxgen")
    else
        missing_deps+=("cdxgen")
    fi

    if [[ -f "$BESMAN_TOOL_PATH/spdx-sbom-generator" || -d "$BESMAN_TOOL_PATH" ]]; then
        available_deps+=("spdx-sbom-generator")
    else
        missing_deps+=("spdx-sbom-generator")
    fi

    # ---------------- Report Summary ----------------
    __besman_echo_white "Available dependencies: ${available_deps[*]}"
    __besman_echo_white "Missing dependencies: ${missing_deps[*]}"

    if [ ${#missing_deps[@]} -ne 0 ]; then
        __besman_echo_white "Warning: Some dependencies are missing. Please install them manually or re-run the install function."
    else
        __besman_echo_white "All required dependencies are installed and valid."
    fi
}

# Lifecycle function: Update environment
__besman_update() {
    __besman_echo_white "Update functionality not implemented yet."
}

# Lifecycle function: Reset environment to default state
__besman_reset() {
    __besman_echo_white "Resetting environment..."

    __besman_uninstall
    __besman_install

    __besman_echo_white "Environment reset complete."
}
