#!/bin/bash

## Lifecycle Functions

__besman_install() {
    __besman_echo_white "Installing environment for $BESMAN_ENV_NAME..."

    # Default Besman installation steps
    __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present.
    __besman_check_github_id || return 1 # Checks if BESMAN_USER_NAMESPACE is populated.

    # Clone source code repo
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir named $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Clone assessment datastore
    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    fi

    # Step 1: Check for and install missing dependencies
    __besman_echo_white "Checking system dependencies..."

    declare -A dependencies=(
        ["curl"]="curl --version"
        ["git"]="git --version"
        ["Python 3.10.9"]="python3.10 --version"
        ["pip"]="pip --version"
    )

    for dep in "${!dependencies[@]}"; do
        if ! ${dependencies[$dep]} &>/dev/null; then
            __besman_echo_white "Installing missing dependency: $dep..."
            case $dep in
            "curl") sudo apt update && sudo apt install -y curl ;;
            "git") sudo apt update && sudo apt install -y git ;;
            "Python 3.10.9") sudo apt update && sudo apt install -y python3.10 python3.10-venv python3.10-dev ;;
            "pip") python3.10 -m ensurepip --default-pip && python3.10 -m pip install --upgrade pip ;;
            esac
        else
            __besman_echo_white "$dep is already installed."
        fi
    done

    # Step 2: Install Ollama (Local LLM)
    __besman_echo_white "Checking for Ollama..."
    if ! command -v ollama &>/dev/null; then
        __besman_echo_white "Installing Ollama..."
        curl -fsSL https://ollama.ai/install.sh | sh
    else
        __besman_echo_white "Ollama is already installed."
    fi
    # Ensure Ollama service is running
    __besman_echo_white "Checking if Ollama service is active..."
    if systemctl is-active --quiet ollama; then
        __besman_echo_white "Ollama service is already running."
    else
        __besman_echo_yellow "Ollama service is inactive. Starting it now..."
        sudo systemctl start ollama
        __besman_echo_white "Ollama service started."
    fi

    # Step 3: Pull Required Model in Ollama
    __besman_echo_white "Checking for Ollama model: mistral:7b-instruct..."
    if ollama list | grep -q "mistral:7b-instruct"; then
        __besman_echo_white "Model mistral:7b-instruct is already available."
    else
        __besman_echo_white "Pulling Ollama model mistral:7b-instruct..."
        ollama pull mistral:7b-instruct
    fi

    # Step 4: Set up Python Virtual Environment
    __besman_echo_white "Setting up virtual environment for ShellGPT..."
    if [[ ! -d "$HOME/sgpt_env" ]]; then
        python3 -m venv "$HOME/sgpt_env"
    fi
    source "$HOME/sgpt_env/bin/activate"

    # Step 5: Install ShellGPT with LiteLLM inside Virtual Env
    __besman_echo_white "Checking for ShellGPT..."
    if ! command -v sgpt &>/dev/null; then
        __besman_echo_white "Installing ShellGPT with LiteLLM..."

        pip install --upgrade pip
        pip install pluggy "shell-gpt[litellm]"
        # pip install --upgrade pip # Ensure pip is updated
        # pip install pluggy        # Fix missing dependency issuex
        # pip install "shell-gpt[litellm]"
    else
        __besman_echo_white "ShellGPT is already installed."
    fi

    # Step 6: Configure ShellGPT
    __besman_echo_white "Configuring ShellGPT..."
    CONFIG_DIR="$HOME/.config/shell_gpt"
    CONFIG_FILE="$CONFIG_DIR/.sgptrc"

    # Ensure the directory exists
    mkdir -p "$CONFIG_DIR"

    # If the config file does NOT exist, run sgpt once to generate it
    if [[ ! -f "$CONFIG_FILE" ]]; then
        __besman_echo_white "Generating default ShellGPT config..."
        __besman_echo_white "**********************************************************"
        __besman_echo_white "If you are running ShellGPT for the first time, you will be prompted for OpenAI API key. 
                             Provide any random string to skip this step (do not just press enter with empty input)."
        __besman_echo_white "***********************************************************"
        sgpt -h >/dev/null 2>&1 # This triggers sgpt to create the config file
    fi

    # Update the required keys while preserving other settings
    if [[ -f "$CONFIG_FILE" ]]; then
        sed -i "s|^DEFAULT_MODEL=.*|DEFAULT_MODEL=ollama/mistral:7b-instruct|" "$CONFIG_FILE" || echo "DEFAULT_MODEL=ollama/mistral:7b-instruct" >>"$CONFIG_FILE"
        sed -i "s|^OPENAI_USE_FUNCTIONS=.*|OPENAI_USE_FUNCTIONS=false|" "$CONFIG_FILE" || echo "OPENAI_USE_FUNCTIONS=false" >>"$CONFIG_FILE"
        sed -i "s|^USE_LITELLM=.*|USE_LITELLM=true|" "$CONFIG_FILE" || echo "USE_LITELLM=true" >>"$CONFIG_FILE"
    else
        cat >"$CONFIG_FILE" <<EOL
DEFAULT_MODEL=ollama/mistral:7b-instruct
OPENAI_USE_FUNCTIONS=false
USE_LITELLM=true
EOL
    fi

    __besman_echo_white "ShellGPT configuration updated successfully."

    # Install Assessment Tools
    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] && readarray -d ',' -t ASSESSMENT_TOOLS <<<"$BESMAN_ASSESSMENT_TOOLS"

    if [ ! -z $ASSESSMENT_TOOLS ]; then
        for tool in ${ASSESSMENT_TOOLS[*]}; do
            if [[ $tool == *:* ]]; then
                tool_name=${tool%%:*}
                tool_version=${tool##*:}
            else
                tool_name=$tool
                tool_version=""
            fi

            __besman_echo_white "Installing tool - $tool_name : version - $tool_version"

            case $tool_name in
            criticality_score)
                if ! [ -x "$(command -v criticality_score)" ]; then
                    go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
                fi
                ;;
            sonarqube)
                docker ps -aq -f name=sonarqube-$BESMAN_ARTIFACT_NAME && docker stop sonarqube-$BESMAN_ARTIFACT_NAME && docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME
                docker create --name sonarqube-$BESMAN_ARTIFACT_NAME -p 9000:9000 sonarqube && docker start sonarqube-$BESMAN_ARTIFACT_NAME
                ;;
            fossology)
                docker ps -aq -f name=fossology-$BESMAN_ARTIFACT_NAME && docker stop fossology-$BESMAN_ARTIFACT_NAME && docker rm -f fossology-$BESMAN_ARTIFACT_NAME
                docker create --name fossology-$BESMAN_ARTIFACT_NAME -p 9001:80 fossology/fossology && docker start fossology-$BESMAN_ARTIFACT_NAME
                ;;
            spdx-sbom-generator)
                curl -L -o $BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"
                tar -xzf $BESMAN_ARTIFACT_DIR/spdx-sbom-generator.tar.gz -C $BESMAN_ARTIFACT_DIR
                ;;
            cyclonedx-sbom-generator)
                if ! which cdxgen >/dev/null; then
                    sudo npm install -g @cyclonedx/cdxgen && sudo cp /usr/bin/cdxgen /opt/cyclonedx-sbom-generator
                fi
                ;;
            *)
                __besman_echo_white "No installation steps found for $tool_name."
                ;;
            esac
        done
        __besman_echo_white "Bes-Assessment tools installation completed."
    fi

    __besman_echo_white "Installation complete."
}

__besman_uninstall() {
    __besman_echo_white "Uninstalling environment for $BESMAN_ENV_NAME..."

    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi

    # Remove ShellGPT
    if command -v sgpt &>/dev/null; then
        __besman_echo_white "Uninstalling ShellGPT with LiteLLM..."
        pip uninstall -y "shell-gpt[litellm]"
    else
        __besman_echo_white "ShellGPT is not installed. Skipping..."
    fi

    # Remove ShellGPT configuration
    CONFIG_DIR="$HOME/.config/shell_gpt"
    if [[ -d "$CONFIG_DIR" ]]; then
        __besman_echo_white "Removing ShellGPT configuration files..."
        rm -rf "$CONFIG_DIR"
    else
        __besman_echo_white "No ShellGPT configuration found. Skipping..."
    fi

    # Remove virtual environment
    if [[ -d "$HOME/sgpt_env" ]]; then
        __besman_echo_white "Removing Python virtual environment..."
        rm -rf "$HOME/sgpt_env"
    fi

    # Remove Ollama model
    __besman_echo_white "Checking for Ollama model: mistral:7b-instruct..."
    if ollama list | grep -q "mistral:7b-instruct"; then
        __besman_echo_white "Removing Ollama model mistral:7b-instruct..."
        ollama rm mistral:7b-instruct
    else
        __besman_echo_white "Model mistral:7b-instruct not found. Skipping..."
    fi

    # Remove Ollama
    if command -v ollama &>/dev/null; then
        __besman_echo_white "Uninstalling Ollama..."

        # Stop and disable the service before deleting files
        sudo systemctl stop ollama
        sudo systemctl disable ollama

        # Remove Ollama binaries and cached models
        sudo rm -rf /usr/local/bin/ollama
        sudo rm -rf ~/.ollama
    else
        __besman_echo_white "Ollama is not installed. Skipping..."
    fi

    # Remove installed assessment tools
    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] && readarray -d ',' -t ASSESSMENT_TOOLS <<<"$BESMAN_ASSESSMENT_TOOLS"

    for tool in ${ASSESSMENT_TOOLS[*]}; do
        case $tool in
        sonarqube)
            docker stop sonarqube-$BESMAN_ARTIFACT_NAME && docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME
            ;;
        fossology)
            docker stop fossology-$BESMAN_ARTIFACT_NAME && docker rm -f fossology-$BESMAN_ARTIFACT_NAME
            ;;
        criticality_score)
            rm -rf $(which criticality_score)
            ;;
        spdx-sbom-generator)
            rm -rf $BESMAN_ARTIFACT_DIR/spdx-sbom-generator*
            ;;
        cyclonedx-sbom-generator)
            sudo npm uninstall -g @cyclonedx/cdxgen
            ;;
        esac
    done

    __besman_echo_white "Uninstallation complete."
}

__besman_validate() {
    __besman_echo_white "Validating environment for $BESMAN_ENV_NAME..."
    local available_deps=()
    local missing_deps=()

    declare -A dependencies=(
        ["curl"]="curl --version"
        ["git"]="git --version"
        ["Python 3.10.9"]="python3.10 --version"
        ["pip"]="pip --version"
        ["Ollama"]="command -v ollama"
        ["ShellGPT"]="command -v sgpt"
        ["Virtual Environment"]="[[ -d $HOME/sgpt_env ]]"
    )

    for dep in "${!dependencies[@]}"; do
        if ${dependencies[$dep]} &>/dev/null; then
            available_deps+=("$dep")
        else
            missing_deps+=("$dep")
        fi
    done

    # Check if the Ollama model exists
    if ollama list | grep -q "mistral:7b-instruct"; then
        available_deps+=("Ollama model - mistral:7b-instruct")
    else
        missing_deps+=("Ollama model - mistral:7b-instruct")
    fi

    __besman_echo_white "Validation Summary:"
    __besman_echo_white "Available dependencies: ${available_deps[*]}"
    __besman_echo_yellow "Missing dependencies: ${missing_deps[*]}"

    # Validate installed assessment tools
    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] && readarray -d ',' -t ASSESSMENT_TOOLS <<<"$BESMAN_ASSESSMENT_TOOLS"

    for tool in ${ASSESSMENT_TOOLS[*]}; do
        case $tool in
        criticality_score)
            command -v criticality_score >/dev/null && __besman_echo_white "criticality_score: Installed" || __besman_echo_white "criticality_score: Missing"
            ;;
        sonarqube)
            docker ps -a --format "{{.Names}}" | grep -q sonarqube-$BESMAN_ARTIFACT_NAME && __besman_echo_white "sonarqube: Installed" || __besman_echo_white "sonarqube: Missing"
            ;;
        fossology)
            docker ps -a --format "{{.Names}}" | grep -q fossology-$BESMAN_ARTIFACT_NAME && __besman_echo_white "fossology: Installed" || __besman_echo_white "fossology: Missing"
            ;;
        spdx-sbom-generator)
            [[ -f $BESMAN_ARTIFACT_DIR/spdx-sbom-generator ]] && __besman_echo_white "spdx-sbom-generator: Installed" || __besman_echo_white "spdx-sbom-generator: Missing"
            ;;
        cyclonedx-sbom-generator)
            command -v cdxgen >/dev/null && __besman_echo_white "cyclonedx-sbom-generator: Installed" || __besman_echo_white "cyclonedx-sbom-generator: Missing"
            ;;
        esac
    done

    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        return 1
    fi

    __besman_echo_white "Validation complete."
}

__besman_update() {
    __besman_echo_white "Updating environment for $BESMAN_ENV_NAME..."
    # Reinstall tools if versions need to be updated
    __besman_uninstall
    __besman_install
}

__besman_reset() {
    __besman_echo_white "Resetting environment for $BESMAN_ENV_NAME..."
    __besman_uninstall
    __besman_install
    __besman_echo_white "Reset complete."
}
