function __besman_install() {

    __besman_echo_white "Installing environment for ai_recruitment_agent_team POI..."

    # Check if required tools exist
    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1

    # Clone source repository
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        __besman_echo_white "Artifact directory already exists: $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME..."
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "${BESMAN_ARTIFACT_VERSION}_tavoss" "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Clone assessment datastore
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        __besman_echo_white "Assessment datastore already exists at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $BESMAN_USER_NAMESPACE/besecure-assessment-datastore..."
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    fi

    # Prerequisites installation
    __besman_echo_white "Installing system prerequisites..."
    sudo apt-get update
    sudo apt-get install -y docker.io git curl unzip python3 python3-pip

    if ! command -v go &>/dev/null; then
        sudo snap install go --classic
    fi

    if ! command -v node &>/dev/null || [[ "$(node -v | cut -d'.' -f1 | tr -d 'v')" -lt 18 ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt-get install -y nodejs
    fi

    # Python environment setup
    __besman_echo_white "Setting up Python virtual environment for POI..."
    sudo apt-get install -y python3-venv
    python3 -m venv "$BESMAN_ARTIFACT_DIR/venv"
    source "$BESMAN_ARTIFACT_DIR/venv/bin/activate"

    # Install Python requirements if requirements.txt exists in POI subfolder
    POI_PATH="$BESMAN_ARTIFACT_DIR/advanced_ai_agents/multi_agent_apps/agent_teams/ai_recruitment_agent_team"
    if [[ -f "$POI_PATH/requirements.txt" ]]; then
        __besman_echo_white "Installing Python dependencies from requirements.txt..."
        pip install --upgrade pip
        pip install -r "$POI_PATH/requirements.txt"
    else
        __besman_echo_white "No requirements.txt found for Python dependencies."
    fi

    deactivate

    # Install assessment tools
    IFS=',' read -ra tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for tool in "${tools[@]}"; do
        name="${tool%%:*}"

        case "$name" in

        scorecard)
            __besman_echo_white "Downloading scorecard from $BESMAN_SCORECARD_ASSET_URL"
            curl -L -o "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" "$BESMAN_SCORECARD_ASSET_URL"
            tar -xzf "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            chmod +x "$HOME/scorecard"
            sudo mv "$HOME/scorecard" /usr/local/bin/
            [[ -f "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" ]] && rm "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            [[ -z $(which scorecard) ]] && __besman_echo_error "Scorecard installation failed." && return 1
            ;;

        criticality_score)
            __besman_echo_white "Installing Criticality Score..."
            go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            ;;

        sonarqube)
            __besman_echo_white "Setting up SonarQube container..."
            docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name sonarqube-$BESMAN_ARTIFACT_NAME -p $BESMAN_SONARQUBE_PORT:9000 sonarqube
            ;;

        fossology)
            __besman_echo_white "Setting up Fossology container..."
            docker rm -f fossology-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name fossology-$BESMAN_ARTIFACT_NAME -p $BESMAN_FOSSOLOGY_PORT:80 fossology/fossology
            ;;

        spdx-sbom-generator)
            __besman_echo_white "Installing SPDX SBOM Generator..."
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

    __besman_echo_white "Installation complete for ai_recruitment_agent_team POI."
}

function __besman_uninstall() {

    __besman_echo_white "Starting environment cleanup for ai_recruitment_agent_team POI..."

    # Remove Docker containers
    docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME &>/dev/null
    docker rm -f fossology-$BESMAN_ARTIFACT_NAME &>/dev/null

    __besman_echo_white "Stopped and removed SonarQube and Fossology containers (if they existed)."

    # Remove scorecard binary
    if [[ -f /usr/local/bin/scorecard ]]; then
        sudo rm /usr/local/bin/scorecard
        __besman_echo_white "Removed scorecard binary from /usr/local/bin/"
    fi

    # Remove SPDX SBOM Generator binaries
    if [[ -d "$BESMAN_TOOL_PATH/spdx-sbom-generator" ]]; then
        sudo rm -rf "$BESMAN_TOOL_PATH/spdx-sbom-generator"
        __besman_echo_white "Removed SPDX SBOM Generator from $BESMAN_TOOL_PATH"
    fi

    # Remove CycloneDX generator binary copy
    if [[ -f /opt/cyclonedx-sbom-generator ]]; then
        sudo rm /opt/cyclonedx-sbom-generator
        __besman_echo_white "Removed CycloneDX SBOM generator from /opt/"
    fi

    # Remove the virtual environment
    if [[ -d "$BESMAN_ARTIFACT_DIR/venv" ]]; then
        rm -rf "$BESMAN_ARTIFACT_DIR/venv"
        __besman_echo_white "Removed Python virtual environment for POI."
    fi

    # Remove cloned artifact repo
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        rm -rf "$BESMAN_ARTIFACT_DIR"
        __besman_echo_white "Removed artifact directory: $BESMAN_ARTIFACT_DIR"
    fi

    # Remove assessment datastore repo
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"
        __besman_echo_white "Removed assessment datastore directory: $BESMAN_ASSESSMENT_DATASTORE_DIR"
    fi

    __besman_echo_white "Uninstallation complete for ai_recruitment_agent_team POI."
}

function __besman_validate() {

    __besman_echo_white "Validating environment for ai_recruitment_agent_team POI..."

    local missing_deps=()
    local available_deps=()

    # Check prerequisite commands
    for cmd in docker git node npm go python3 pip curl; do
        if command -v "$cmd" &>/dev/null; then
            available_deps+=("$cmd")
        else
            missing_deps+=("$cmd")
        fi
    done

    # Check Docker containers
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

    # Check Scorecard
    if command -v scorecard &>/dev/null; then
        available_deps+=("scorecard")
    else
        missing_deps+=("scorecard")
    fi

    # Check SPDX SBOM Generator
    if [[ -d "$BESMAN_TOOL_PATH/spdx-sbom-generator" ]]; then
        available_deps+=("spdx-sbom-generator")
    else
        missing_deps+=("spdx-sbom-generator")
    fi

    # Check CycloneDX SBOM generator
    if [[ -f /opt/cyclonedx-sbom-generator ]]; then
        available_deps+=("cyclonedx-sbom-generator")
    else
        missing_deps+=("cyclonedx-sbom-generator")
    fi

    # Check Python virtual environment
    if [[ -d "$BESMAN_ARTIFACT_DIR/venv" ]]; then
        available_deps+=("python-venv")
    else
        missing_deps+=("python-venv")
    fi

    __besman_echo_white "Available dependencies: ${available_deps[*]}"
    __besman_echo_white "Missing dependencies: ${missing_deps[*]}"

    if [ ${#missing_deps[@]} -ne 0 ]; then
        __besman_echo_white "Some dependencies are missing. Please install them to ensure proper functioning."
    else
        __besman_echo_white "All dependencies are installed correctly."
    fi
}

function __besman_update() {

    __besman_echo_white "Updating environment for ai_recruitment_agent_team POI..."

    local updated=0

    # Update the POI repository
    if [[ -d "$BESMAN_ARTIFACT_DIR/.git" ]]; then
        __besman_echo_white "Checking for updates in $BESMAN_ARTIFACT_DIR..."
        cd "$BESMAN_ARTIFACT_DIR"
        git fetch origin
        if ! git diff --quiet HEAD origin/"$BESMAN_ARTIFACT_VERSION"; then
            __besman_echo_white "Updates found. Pulling latest changes..."
            git pull origin "$BESMAN_ARTIFACT_VERSION"
            updated=1
        else
            __besman_echo_white "No updates found in POI repository."
        fi
        cd "$HOME"
    else
        __besman_echo_white "POI repository not found at $BESMAN_ARTIFACT_DIR."
    fi

    # Update the assessment datastore repository
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR/.git" ]]; then
        __besman_echo_white "Checking for updates in $BESMAN_ASSESSMENT_DATASTORE_DIR..."
        cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"
        git fetch origin
        if ! git diff --quiet HEAD origin/main; then
            __besman_echo_white "Updates found in assessment datastore. Pulling latest changes..."
            git pull origin main
            updated=1
        else
            __besman_echo_white "No updates found in assessment datastore."
        fi
        cd "$HOME"
    else
        __besman_echo_white "Assessment datastore repo not found at $BESMAN_ASSESSMENT_DATASTORE_DIR."
    fi

    # Reinstall Python dependencies if there were updates
    if [[ $updated -eq 1 ]]; then
        __besman_echo_white "Reinstalling Python dependencies for POI..."
        if [[ -d "$BESMAN_ARTIFACT_DIR/venv" ]]; then
            source "$BESMAN_ARTIFACT_DIR/venv/bin/activate"
            POI_PATH="$BESMAN_ARTIFACT_DIR/advanced_ai_agents/multi_agent_apps/agent_teams/ai_recruitment_agent_team"
            if [[ -f "$POI_PATH/requirements.txt" ]]; then
                pip install --upgrade pip
                pip install -r "$POI_PATH/requirements.txt"
                __besman_echo_white "Python dependencies updated."
            else
                __besman_echo_white "No requirements.txt found. Skipping Python dependency update."
            fi
            deactivate
        else
            __besman_echo_white "Virtual environment not found. Please install environment first."
        fi
    else
        __besman_echo_white "No updates detected, skipping dependency reinstalls."
    fi

    __besman_echo_white "Update process completed for ai_recruitment_agent_team POI."
}

function __besman_reset() {

    __besman_echo_white "Resetting environment for ai_recruitment_agent_team POI..."

    __besman_uninstall
    if [[ $? -ne 0 ]]; then
        __besman_echo_error "Uninstall step failed during reset. Aborting reset process."
        return 1
    fi

    __besman_install
    if [[ $? -ne 0 ]]; then
        __besman_echo_error "Install step failed during reset. Environment may be incomplete."
        return 1
    fi

    __besman_echo_white "Reset process completed for ai_recruitment_agent_team POI."
}
