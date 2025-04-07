#!/bin/bash

function __besman_install {

    __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1 # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE

    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-ml-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-ml-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi
    ## Please add the rest of the code here for installation

    # Step 1: Install Ollama
    __besman_echo_white "[INFO] Installing Ollama..."
    if ! command -v ollama &>/dev/null; then
        curl -fsSL https://ollama.ai/install.sh | sh
    else
        __besman_echo_green "[INFO] Ollama is already installed."
    fi

    # Step 2: Start Ollama daemon (if not running)
    __besman_echo_white "[INFO] Starting Ollama..."
    if ! pgrep -x "ollama" >/dev/null; then
        nohup ollama serve >/dev/null 2>&1 &
        disown
        sleep 5 # Allow Ollama some time to start
    else
        __besman_echo_green "[INFO] Ollama is already running."
    fi

    # Step 3: Ensure `jq` is installed for JSON processing
    if ! command -v jq &>/dev/null; then
        __besman_echo_white "[INFO] Installing jq for JSON parsing..."
        sudo apt update && sudo apt install -y jq
    fi

    # Step 4: Pull the Gemma 3B model
    __besman_echo_white "[INFO] Pulling $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION model..."
    if ollama pull $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION; then
        __besman_echo_white "[SUCCESS] Model pulled successfully!"
    else
        __besman_echo_red "[ERROR] Failed to pull model. Check Ollama logs."
        exit 1
    fi

    # Step 5: Verify available model declared in config file
    __besman_echo_white "[INFO] Available models:"
    if ollama list | grep -q $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION; then
        __besman_echo_green "[INFO] Model $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION is available."
    else
        __besman_echo_red "[INFO] Model $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION is not available."
        exit 1
    fi

    # Step 6: Verify Ollama is running on the correct port
    if ! sudo lsof -i :11434 | grep -q LISTEN; then
        __besman_echo_red "[ERROR] Ollama is not running on port 11434."
        exit 1
    else
        __besman_echo_green "Ollama is running on port 11434."
    fi

    # check if python3 is installed if not install it.
    if [[ -z $(which python3) ]]; then
        __besman_echo_white "Python3 is not installed. Installing python3."
        sudo apt-get update
        sudo apt-get install python3 -y
        [[ -z $(which python3) ]] && __besman_echo_red "Python3 installation failed" && return 1
    else
        __besman_echo_green "Python3 is installed already."
    fi

    # Install pip
    if ! command -v pip3 &>/dev/null; then
        __besman_echo_white "[INFO] Installing pip..."
        sudo apt-get install -y python3-pip
        [[ -z $(which pip3) ]] && __besman_echo_red "Pip installation failed" && return 1
    else
        __besman_echo_green "[INFO] Pip is already installed."
    fi

    # Install boto3
    __besman_echo_white "[INFO] Installing boto3..."
    pip3 install --upgrade boto3
    [[ $? -ne 0 ]] && __besman_echo_red "[ERROR] Failed to install boto3." && return 1
    __besman_echo_green "[SUCCESS] boto3 installed successfully."

    # clone PurpleLlama
    if [[ ! -d "$BESMAN_TOOL_PATH" ]]; then
        __besman_echo_white "Cloning Repository PurpleLlama"
        __besman_repo_clone "$BESMAN_ORG" "PurpleLlama" "$BESMAN_TOOL_PATH" || return 1
    else
        __besman_echo_green "Repository PurpleLlama already exists at $BESMAN_TOOL_PATH/PurpleLlama. Skipping clone."
    fi

    # setup CybersecurityBenchmarks using PurpleLlama
    __besman_echo_white "Installing Cybersecurity Benchmarks using PurpleLlama."
    # creating virtual environments
    python3 -m venv ~/.venvs/cyberseceval
    source ~/.venvs/cyberseceval/bin/activate
    cd "$BESMAN_TOOL_PATH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH" && return 1; }
    pip3 install -r CybersecurityBenchmarks/requirements.txt

    __besman_echo_no_colour ""
    __besman_echo_green "CybersecurityBenchmarks installed successfully"

}

function __besman_uninstall {

    # Please add the rest of the code here for uninstallation

    __besman_echo_white "[INFO] Uninstalling boto3..."
    pip3 uninstall -y boto3

    __besman_echo_white "[INFO] Removing pulled Ollama model..."
    ollama rm $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION

    __besman_echo_white "[INFO] Removing Ollama binary (manual cleanup)..."
    sudo rm -rf /usr/local/bin/ollama ~/.ollama

    __besman_echo_white "[INFO] Removing assessment datastore..."
    rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    __besman_echo_white "[INFO] Removing PurpleLlama repo..."
    rm -rf "$BESMAN_TOOL_PATH/PurpleLlama"

    __besman_echo_white "[INFO] Removing CyberSecEval virtual environment..."
    rm -rf ~/.venvs/cyberseceval

    __besman_echo_red "[UNINSTALL COMPLETE]"
}

function __besman_update {

    # Please add the rest of the code here for update

    __besman_echo_white "[INFO] Updating system packages..."
    sudo apt-get update -y && sudo apt-get upgrade -y

    # Update Python3 (Ubuntu-specific logic for minor updates)
    __besman_echo_white "[INFO] Checking for Python3 updates..."
    sudo apt-get install --only-upgrade -y python3
    [[ $? -ne 0 ]] && __besman_echo_red "[ERROR] Failed to update Python3." && return 1
    __besman_echo_green "[SUCCESS] Python3 updated (if updates were available)."

    # Update pip3 globally
    __besman_echo_white "[INFO] Updating global pip3..."
    python3 -m pip install --upgrade pip
    [[ $? -ne 0 ]] && __besman_echo_red "[ERROR] Failed to update pip3." && return 1
    __besman_echo_green "[SUCCESS] pip3 updated successfully."

    # Update boto3 globally
    __besman_echo_white "[INFO] Updating global boto3..."
    pip3 install --upgrade boto3
    [[ $? -ne 0 ]] && __besman_echo_red "[ERROR] Failed to update boto3." && return 1
    __besman_echo_green "[SUCCESS] boto3 updated successfully."

    # Update PurpleLlama repo if it exists
    if [[ -d "$BESMAN_TOOL_PATH/PurpleLlama" ]]; then
        __besman_echo_white "[INFO] Updating PurpleLlama repository..."
        cd "$BESMAN_TOOL_PATH/PurpleLlama" && git pull
        [[ $? -ne 0 ]] && __besman_echo_red "[ERROR] Failed to update PurpleLlama repo." && return 1
        __besman_echo_green "[SUCCESS] PurpleLlama updated successfully."
    else
        __besman_echo_red "[WARNING] PurpleLlama repository not found. Skipping update."
    fi

    # Reinstall/Upgrade requirements inside venv
    if [[ -d ~/.venvs/cyberseceval ]]; then
        __besman_echo_white "[INFO] Updating dependencies inside cyberseceval venv..."
        source ~/.venvs/cyberseceval/bin/activate
        pip install --upgrade -r "$BESMAN_TOOL_PATH/CybersecurityBenchmarks/requirements.txt"
        deactivate
        __besman_echo_green "[SUCCESS] CybersecurityBenchmarks dependencies updated."
    else
        __besman_echo_red "[WARNING] Virtual environment not found. Skipping venv dependency update."
    fi

    __besman_echo_green "[INFO] Update completed successfully."

}

function __besman_validate {

    # Please add the rest of the code here for validate

    local missing_dependencies=()

    __besman_echo_white "[INFO] Validating system dependencies..."

    # Validate Python3
    if ! command -v python3 &>/dev/null; then
        __besman_echo_red "[ERROR] Python3 is missing."
        missing_dependencies+=("python3")
    else
        __besman_echo_green "[OK] Python3 is installed."
    fi

    # Validate pip3
    if ! command -v pip3 &>/dev/null; then
        __besman_echo_red "[ERROR] pip3 is missing."
        missing_dependencies+=("pip3")
    else
        __besman_echo_green "[OK] pip3 is installed."
    fi

    # Validate boto3
    if ! python3 -c "import boto3" &>/dev/null; then
        __besman_echo_red "[ERROR] boto3 is not installed globally."
        missing_dependencies+=("boto3")
    else
        __besman_echo_green "[OK] boto3 is installed globally."
    fi

    # Validate jq
    if ! command -v jq &>/dev/null; then
        __besman_echo_red "[ERROR] jq is missing."
        missing_dependencies+=("jq")
    else
        __besman_echo_green "[OK] jq is installed."
    fi

    # Validate Ollama
    if ! command -v ollama &>/dev/null; then
        __besman_echo_red "[ERROR] Ollama is missing."
        missing_dependencies+=("ollama")
    else
        __besman_echo_green "[OK] Ollama is installed."
    fi

    # Validate Ollama service
    if ! sudo lsof -i :11434 | grep -q LISTEN; then
        __besman_echo_red "[ERROR] Ollama is not running on port 11434."
        missing_dependencies+=("ollama-port")
    else
        __besman_echo_green "[OK] Ollama is running on port 11434."
    fi

    # Validate model existence in Ollama
    if ! ollama list | grep -q "$BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION"; then
        __besman_echo_red "[ERROR] Model $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION not found in Ollama."
        missing_dependencies+=("ollama-model")
    else
        __besman_echo_green "[OK] Model $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION is available."
    fi

    # Validate PurpleLlama repo
    if [[ ! -d "$BESMAN_TOOL_PATH/PurpleLlama" ]]; then
        __besman_echo_red "[ERROR] PurpleLlama repository is missing."
        missing_dependencies+=("PurpleLlama")
    else
        __besman_echo_green "[OK] PurpleLlama repository is present."
    fi

    # Validate Python venv
    if [[ ! -d ~/.venvs/cyberseceval ]]; then
        __besman_echo_red "[ERROR] Python virtual environment for CyberSecEval is missing."
        missing_dependencies+=("cyberseceval-venv")
    else
        __besman_echo_green "[OK] Python virtual environment for CyberSecEval exists."

        # Validate venv requirements
        source ~/.venvs/cyberseceval/bin/activate
        missing_requirements=0
        while read -r pkg; do
            pkg_name=$(echo "$pkg" | cut -d= -f1)
            pip show "$pkg_name" &>/dev/null || {
                __besman_echo_red "[ERROR] $pkg_name missing in venv."
                missing_requirements=1
            }
        done <"$BESMAN_TOOL_PATH/CybersecurityBenchmarks/requirements.txt"
        deactivate

        [[ $missing_requirements -eq 0 ]] && __besman_echo_green "[OK] All venv dependencies installed."
    fi

    if [[ ${#missing_dependencies[@]} -eq 0 ]]; then
        __besman_echo_green "[INFO] Validation successful. All components are in place."
    else
        __besman_echo_red "[INFO] Validation failed. Missing components:"
        for dep in "${missing_dependencies[@]}"; do
            __besman_echo_red " - $dep"
        done
        return 1
    fi

}

function __besman_reset {

    # Please add the rest of the code here for reset

    __besman_echo_white "[INFO] Resetting llmSecurityBenchmark environment..."

    __besman_uninstall || {
        __besman_echo_red "[ERROR] Uninstallation failed. Aborting reset."
        return 1
    }

    __besman_install || {
        __besman_echo_red "[ERROR] Installation failed during reset."
        return 1
    }

    __besman_echo_green "[SUCCESS] Environment has been reset to a clean state."

}
