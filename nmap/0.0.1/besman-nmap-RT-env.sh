__besman_install() {

    # Function to extract values from YAML
    extract_yaml_value() {
        local key=$1
        local value
        value=$(grep "^$key:" "$CONFIG_FILE" | awk -F": " '{print $2}' | tr -d '"')
        echo "$value"
    }

    # Load artifact variables
    BESMAN_ARTIFACT_NAME=$(extract_yaml_value "BESMAN_ARTIFACT_NAME")
    BESMAN_ARTIFACT_VERSION=$(extract_yaml_value "BESMAN_ARTIFACT_VERSION")
    BESMAN_ARTIFACT_URL=$(extract_yaml_value "BESMAN_ARTIFACT_URL")
    BESMAN_ARTIFACT_DIR=$(eval echo "$(extract_yaml_value "BESMAN_ARTIFACT_DIR")")
    BESMAN_ASSESSMENT_DATASTORE_DIR=$(eval echo "$(extract_yaml_value "BESMAN_ASSESSMENT_DATASTORE_DIR")")
    BESMAN_ASSESSMENT_DATASTORE_URL=$(extract_yaml_value "BESMAN_ASSESSMENT_DATASTORE_URL")

    # Check if Git is installed
    if ! command -v git &>/dev/null; then
        echo "Error: Git is not installed. Please install Git to proceed."
        return 1
    fi

    # Clone the main artifact repository (Nmap)
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "✅ The artifact '$BESMAN_ARTIFACT_NAME' already exists at $BESMAN_ARTIFACT_DIR"
    else
        echo "🔄 Cloning '$BESMAN_ARTIFACT_NAME' from $BESMAN_ARTIFACT_URL..."
        git clone "$BESMAN_ARTIFACT_URL" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Install Docker if not installed
    if ! command -v docker &>/dev/null; then
        echo "🔄 Installing Docker..."
        sudo apt update
        sudo apt install -y ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        sudo systemctl restart docker
        echo "✅ Docker installed successfully!"
    else
        echo "✅ Docker is already installed."
    fi

    # Clone assessment datastore
    if [[ ! -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo "🔄 Cloning assessment datastore from $BESMAN_ASSESSMENT_DATASTORE_URL..."
        git clone "$BESMAN_ASSESSMENT_DATASTORE_URL" "$BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        echo "✅ Assessment datastore already exists at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    fi

    # Install assessment tools dynamically from YAML
    echo "🔍 Fetching assessment tools from YAML..."
    grep -A 10 "BESMAN_ASSESSMENT_TOOLS:" "$CONFIG_FILE" | tail -n +2 | while read -r line; do
        tool_name=$(echo "$line" | awk -F": " '{print $1}' | tr -d '"')
        repo_url=$(echo "$line" | awk -F": " '{print $2}' | tr -d '"')

        if [[ -z "$tool_name" || -z "$repo_url" ]]; then
            continue
        fi

        tool_install_dir="$HOME/tools/$tool_name"

        if [[ -d "$tool_install_dir" ]]; then
            echo "✅ $tool_name is already installed at $tool_install_dir"
        else
            echo "🔄 Installing $tool_name from $repo_url..."
            git clone "$repo_url" "$tool_install_dir"
            cd "$tool_install_dir"

            if [[ -f "Makefile" ]]; then
                make && sudo make install
            elif [[ -f "install.sh" ]]; then
                chmod +x install.sh && ./install.sh
            else
                echo "⚠️ No standard installation method found for $tool_name. Please install manually if needed."
            fi

            cd "$HOME"
        fi
    done

    echo "✅ All tools installed successfully!"
}
__besman_uninstall() {
    # Uninstall the artifact and remove its directory
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "🗑️ Removing artifact directory: $BESMAN_ARTIFACT_DIR"
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        echo "⚠️ Artifact directory not found. Skipping removal."
    fi

    # Remove assessment datastore if it exists
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo "🗑️ Removing assessment datastore: $BESMAN_ASSESSMENT_DATASTORE_DIR"
        rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        echo "⚠️ Assessment datastore not found. Skipping removal."
    fi

    # Remove installed assessment tools
    echo "🗑️ Removing installed assessment tools..."
    grep -A 10 "BESMAN_ASSESSMENT_TOOLS:" "$CONFIG_FILE" | tail -n +2 | while read -r line; do
        tool_name=$(echo "$line" | awk -F": " '{print $1}' | tr -d '"')
        tool_install_dir="$HOME/tools/$tool_name"

        if [[ -d "$tool_install_dir" ]]; then
            echo "🗑️ Removing $tool_name from $tool_install_dir"
            rm -rf "$tool_install_dir"
        else
            echo "⚠️ $tool_name not found. Skipping."
        fi
    done

    echo "✅ Uninstallation completed!"
}

__besman_update() {
    # Pull the latest changes for the artifact repository
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "🔄 Updating artifact: $BESMAN_ARTIFACT_NAME"
        cd "$BESMAN_ARTIFACT_DIR"
        git pull origin "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    else
        echo "⚠️ Artifact directory not found. Cannot update."
    fi

    # Update assessment datastore
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo "🔄 Updating assessment datastore..."
        cd "$BESMAN_ASSESSMENT_DATASTORE_DIR"
        git pull origin main
        cd "$HOME"
    else
        echo "⚠️ Assessment datastore not found. Skipping update."
    fi

    echo "🔄 Updating installed assessment tools..."
    grep -A 10 "BESMAN_ASSESSMENT_TOOLS:" "$CONFIG_FILE" | tail -n +2 | while read -r line; do
        tool_name=$(echo "$line" | awk -F": " '{print $1}' | tr -d '"')
        tool_install_dir="$HOME/tools/$tool_name"

        if [[ -d "$tool_install_dir" ]]; then
            echo "🔄 Updating $tool_name..."
            cd "$tool_install_dir"
            git pull origin main
            cd "$HOME"
        else
            echo "⚠️ $tool_name not found. Skipping update."
        fi
    done

    echo "✅ Update completed!"
}

__besman_validate() {
    # Validate if the artifact exists
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "✅ Artifact exists at $BESMAN_ARTIFACT_DIR"
    else
        echo "❌ Artifact is missing. Please install it."
    fi

    # Validate assessment datastore
    if [[ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]]; then
        echo "✅ Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        echo "❌ Assessment datastore is missing. Please reinstall it."
    fi

    # Validate assessment tools
    echo "🔍 Validating installed assessment tools..."
    grep -A 10 "BESMAN_ASSESSMENT_TOOLS:" "$CONFIG_FILE" | tail -n +2 | while read -r line; do
        tool_name=$(echo "$line" | awk -F": " '{print $1}' | tr -d '"')
        tool_install_dir="$HOME/tools/$tool_name"

        if [[ -d "$tool_install_dir" ]]; then
            echo "✅ $tool_name is installed."
        else
            echo "❌ $tool_name is missing. Please install it."
        fi
    done

    echo "✅ Validation completed!"
}

__besman_reset() {
    # Reset the artifact by re-cloning it
    echo "🔄 Resetting artifact: $BESMAN_ARTIFACT_NAME"
    rm -rf "$BESMAN_ARTIFACT_DIR"
    git clone "$BESMAN_ARTIFACT_URL" "$BESMAN_ARTIFACT_DIR"
    cd "$BESMAN_ARTIFACT_DIR" && git checkout "$BESMAN_ARTIFACT_VERSION"
    cd "$HOME"

    # Reset assessment datastore
    echo "🔄 Resetting assessment datastore..."
    rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"
    git clone "$BESMAN_ASSESSMENT_DATASTORE_URL" "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    # Reset assessment tools
    echo "🔄 Resetting assessment tools..."
    grep -A 10 "BESMAN_ASSESSMENT_TOOLS:" "$CONFIG_FILE" | tail -n +2 | while read -r line; do
        tool_name=$(echo "$line" | awk -F": " '{print $1}' | tr -d '"')
        repo_url=$(echo "$line" | awk -F": " '{print $2}' | tr -d '"')
        tool_install_dir="$HOME/tools/$tool_name"

        echo "🔄 Resetting $tool_name..."
        rm -rf "$tool_install_dir"
        git clone "$repo_url" "$tool_install_dir"
    done

    echo "✅ Reset completed!"
}

