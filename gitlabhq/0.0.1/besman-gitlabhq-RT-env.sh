#!/usr/bin/env bash

# Environment script for POI: gitlabhq (https://github.com/Be-Secure/gitlabhq)

# Lifecycle function: Install environment and dependencies
__besman_install() {
    __besman_echo_white "Starting environment installation..."

    # Check if GitHub CLI exists
    __besman_check_vcs_exist || {
        __besman_echo_white "GitHub CLI not found. Please install it."
        return 1
    }

    # Check if GitHub user ID is set
    __besman_check_github_id || {
        __besman_echo_white "BESMAN_USER_NAMESPACE is not set. Please set it."
        return 1
    }

    # Clone source repo if not present
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains directory $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "${BESMAN_ARTIFACT_VERSION}_tavoss" "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Clone assessment datastore if not present
    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    fi

    # ************************* env dependency *********************************
    __besman_echo_white "Installing prerequisites..."

    # -------------------- Ruby 3.2.x --------------------
    if ! ruby -v | grep -q "3.2."; then
        __besman_echo_white "Installing Ruby 3.2.x..."
        sudo apt-get update
        sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev
        curl -fsSL https://rvm.io/mpapis.asc | gpg --dearmor -o /usr/share/keyrings/rvm.gpg
        curl -sSL https://get.rvm.io | bash -s stable
        source /etc/profile.d/rvm.sh
        rvm install 3.2
        rvm use 3.2 --default
    else
        __besman_echo_white "Ruby 3.2.x is already installed."
    fi

    # -------------------- RubyGems 3.5+ --------------------
    if ! gem -v | grep -q "^3\.[5-9]"; then
        __besman_echo_white "Upgrading RubyGems to >=3.5..."
        gem update --system
    else
        __besman_echo_white "RubyGems is already >=3.5."
    fi

    # -------------------- Git 2.47+ --------------------
    GIT_VERSION_REQUIRED="2.47"
    GIT_VERSION_INSTALLED=$(git --version | awk '{print $3}')
    if dpkg --compare-versions "$GIT_VERSION_INSTALLED" lt "$GIT_VERSION_REQUIRED"; then
        __besman_echo_white "Upgrading Git to >= 2.47..."
        sudo add-apt-repository ppa:git-core/ppa -y
        sudo apt-get update
        sudo apt-get install -y git
    else
        __besman_echo_white "Git version $GIT_VERSION_INSTALLED is sufficient."
    fi

    # -------------------- PostgreSQL 16.x --------------------
    if ! psql --version | grep -q "16."; then
        __besman_echo_white "Installing PostgreSQL 16..."
        sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
        wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
        sudo apt-get update
        sudo apt-get install -y postgresql-16
    else
        __besman_echo_white "PostgreSQL 16 is already installed."
    fi

    # Docker installation
    if ! command -v docker &>/dev/null; then
        __besman_echo_white "Docker not found. Installing Docker..."
        sudo apt-get update
        sudo apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo \
            "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker "$USER"
        sudo systemctl restart docker
    else
        __besman_echo_white "Docker already installed."
    fi

    # Snapd installation
    if ! command -v snap &>/dev/null; then
        __besman_echo_white "snapd not found. Installing snapd..."
        sudo apt-get update
        sudo apt-get install -y snapd
    else
        __besman_echo_white "snapd already installed."
    fi

    # Go installation using snap
    if ! command -v go &>/dev/null; then
        __besman_echo_white "Go not found. Installing Go via snap..."
        sudo snap install go --classic
    else
        __besman_echo_white "Go already installed."
    fi

    # Node.js 18.x and npm installation
    NODE_MAJOR_REQUIRED=18
    if ! command -v node &>/dev/null || [ "$(node -v | grep -oP '(?<=v)[0-9]+')" != "$NODE_MAJOR_REQUIRED" ]; then
        __besman_echo_white "Installing Node.js 18.x and npm..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt-get install -y nodejs
    else
        __besman_echo_white "Node.js 18.x already installed."
    fi

    __besman_echo_white "Prerequisiscorecardtes installation completed."

    # =========================
    # Install assessment tools listed in $BESMAN_ASSESSMENT_TOOLS
    # =========================
    if [ -z "$BESMAN_ASSESSMENT_TOOLS" ]; then
        __besman_echo_white "No assessment tools specified in BESMAN_ASSESSMENT_TOOLS."
    else
        IFS=',' read -ra tools <<<"$BESMAN_ASSESSMENT_TOOLS"
        for tool in "${tools[@]}"; do
            tool_name=$(echo "$tool" | cut -d':' -f1)
            tool_version=$(echo "$tool" | grep ':' | cut -d':' -f2)

            case "$tool_name" in
            scorecard)
                __besman_echo_white "Installing scorecard tool..."
                tmpdir=$(mktemp -d)
                curl -sSL "https://github.com/ossf/scorecard/releases/latest/download/scorecard-linux-amd64.tar.gz" -o "$tmpdir/scorecard.tar.gz" || {
                    __besman_echo_white "Failed to download scorecard"
                    continue
                }
                tar -xzf "$tmpdir/scorecard.tar.gz" -C "$tmpdir"
                chmod +x "$tmpdir/scorecard-linux-amd64"
                sudo mv "$tmpdir/scorecard-linux-amd64" /usr/local/bin/scorecard
                rm -rf "$tmpdir"
                ;;

            criticality_score)
                __besman_echo_white "Installing criticality_score tool..."
                if command -v go &>/dev/null; then
                    go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest || __besman_echo_white "Failed to install criticality_score"
                else
                    __besman_echo_white "Go not found; cannot install criticality_score"
                fi
                ;;

            sonarqube)
                __besman_echo_white "Setting up SonarQube docker container..."
                if docker ps -a --format '{{.Names}}' | grep -q "^sonarqube-$BESMAN_ARTIFACT_NAME$"; then
                    __besman_echo_white "Removing existing SonarQube container..."
                    docker rm -f "sonarqube-$BESMAN_ARTIFACT_NAME" || __besman_echo_white "Failed to remove existing SonarQube container"
                fi
                docker run -d --name "sonarqube-$BESMAN_ARTIFACT_NAME" -p $BESMAN_SONARQUBE_PORT:$BESMAN_SONARQUBE_PORT sonarqube || __besman_echo_white "Failed to start SonarQube container"
                ;;

            fossology)
                __besman_echo_white "Setting up Fossology docker container..."
                if docker ps -a --format '{{.Names}}' | grep -q "^fossology-$BESMAN_ARTIFACT_NAME$"; then
                    __besman_echo_white "Removing existing Fossology container..."
                    docker rm -f "fossology-$BESMAN_ARTIFACT_NAME" || __besman_echo_white "Failed to remove existing Fossology container"
                fi
                docker run -d --name "fossology-$BESMAN_ARTIFACT_NAME" -p $BESMAN_FOSSOLOGY_PORT:$BESMAN_FOSSOLOGY_PORT fossology/fossology || __besman_echo_white "Failed to start Fossology container"
                ;;

            spdx-sbom-generator)
                __besman_echo_white "Installing SPDX SBOM Generator..."

                curl -L -o $BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"
                tar -xzf $BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz -C $BESMAN_ARTIFACT_DIR
                ;;

            cyclonedx-sbom-generator)
                __besman_echo_white "Installing CycloneDX SBOM Generator..."
                if ! command -v cdxgen &>/dev/null; then
                    npm install -g @cyclonedx/cdxgen || __besman_echo_white "Failed to install cdxgen"
                fi
                sudo cp "$(which cdxgen)" /opt/cyclonedx-sbom-generator || __besman_echo_white "Failed to copy cdxgen binary"
                ;;

            *)
                __besman_echo_white "Unknown tool $tool_name. Skipping."
                ;;
            esac
        done
    fi

    __besman_echo_white "Installation finished."
}

# Lifecycle function: Uninstall environment and clean up
__besman_uninstall() {
    __besman_echo_white "Starting environment uninstallation..."

    # Remove source code directory
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        rm -rf "$BESMAN_ARTIFACT_DIR"
        __besman_echo_white "Removed source code directory: $BESMAN_ARTIFACT_DIR"
    fi

    # Remove assessment datastore directory
    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then
        rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"
        __besman_echo_white "Removed assessment datastore directory: $BESMAN_ASSESSMENT_DATASTORE_DIR"
    fi

    # Stop and remove SonarQube container if running
    if docker ps -a --format '{{.Names}}' | grep -q "^sonarqube-$BESMAN_ARTIFACT_NAME$"; then
        docker rm -f "sonarqube-$BESMAN_ARTIFACT_NAME"
        __besman_echo_white "Removed SonarQube container."
    fi

    # Stop and remove Fossology container if running
    if docker ps -a --format '{{.Names}}' | grep -q "^fossology-$BESMAN_ARTIFACT_NAME$"; then
        docker rm -f "fossology-$BESMAN_ARTIFACT_NAME"
        __besman_echo_white "Removed Fossology container."
    fi

    # Remove cdxgen if installed globally via npm
    if command -v cdxgen &>/dev/null; then
        npm uninstall -g @cyclonedx/cdxgen
        __besman_echo_white "Uninstalled CycloneDX SBOM Generator (cdxgen)."
    fi

    # Remove SPDX SBOM Generator folder if exists
    if [[ -d "$BESMAN_TOOL_PATH/spdx-sbom-generator" ]]; then
        rm -rf "$BESMAN_TOOL_PATH/spdx-sbom-generator"
        __besman_echo_white "Removed SPDX SBOM Generator."
    fi

    __besman_echo_white "Uninstallation complete."
}

# Lifecycle function: Validate environment and dependencies
__besman_validate() {
    __besman_echo_white "Validating environment..."

    local missing_deps=()
    local available_deps=()

    # Check prerequisite commands
    for cmd in docker git node npm go curl; do
        if command -v "$cmd" &>/dev/null; then
            available_deps+=("$cmd")
        else
            missing_deps+=("$cmd")
        fi
    done

    # Check Docker containers for SonarQube and Fossology
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

    # Check cdxgen presence
    if command -v cdxgen &>/dev/null; then
        available_deps+=("cdxgen")
    else
        missing_deps+=("cdxgen")
    fi

    # Report available and missing deps
    __besman_echo_white "Available dependencies: ${available_deps[*]}"
    __besman_echo_white "Missing dependencies: ${missing_deps[*]}"

    if [ ${#missing_deps[@]} -ne 0 ]; then
        __besman_echo_white "Warning: Some dependencies are missing. Please install them."
    else
        __besman_echo_white "All dependencies are installed."
    fi
}

# Lifecycle function: Update environment (placeholder)
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
