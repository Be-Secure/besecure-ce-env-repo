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
    __besman_echo_red "Un-installation complete"
    # Please add the rest of the code here for uninstallation

}

function __besman_update {
    __besman_echo_red "Update complete"
    # Please add the rest of the code here for update

}

function __besman_validate {
    __besman_echo_red "Validation complete"
    # Please add the rest of the code here for validate

}

function __besman_reset {
    __besman_echo_red "Reset complete"
    # Please add the rest of the code here for reset

}
