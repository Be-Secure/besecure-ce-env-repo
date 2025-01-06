#!/bin/bash

function __besman_install {
    # Checks if GitHub CLI is present or not.
    __besman_check_vcs_exist || return 1

    # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    __besman_check_github_id || return 1

    # check if python3 is installed if not install it.
    if [[ -z $(which python3) ]]; then
        __besman_echo_white "Python3 is not installed. Installing python3..."
        sudo apt-get update
        sudo apt-get install python3 -y
        [[ -z $(which python3) ]] && __besman_echo_red "Python3 installation failed" && return 1
    fi

    __besman_repo_clone "$BESMAN_ORG" "PurpleLlama" "$BESMAN_TOOL_PATH" || return 1

    __besman_echo_white "Installing Cybersecurity Benchmarks..."
    python3 -m venv ~/.venvs/cyberseceval
    source ~/.venvs/cyberseceval/bin/activate
    cd "$BESMAN_TOOL_PATH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH" && return 1; }
    pip3 install -r CybersecurityBenchmarks/requirements.txt
    python3 -m pip install transformers torch boto3
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to install CybersecurityBenchmarks" && return 1
    deactivate
    __besman_echo_no_colour ""
    __besman_echo_green "CybersecurityBenchmarks installed successfully"
    __besman_echo_no_colour ""
    __besman_echo_white "Installing codeshield"
    python3 -m venv ~/.venvs/codeshield_env
    source ~/.venvs/codeshield_env/bin/activate
    python3 -m pip install codeshield
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to install codeshield" && return 1
    __besman_echo_no_colour ""
    __besman_echo_green "codeshield installed successfully"
    deactivate
    cd "$HOME"
}

function __besman_uninstall {

    __besman_echo_white "Uninstalling CybersecurityBenchmarks..."
    source ~/.venvs/cyberseceval/bin/activate
    cd "$BESMAN_TOOL_PATH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH" && return 1; }
    pip3 uninstall -y CybersecurityBenchmarks
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to uninstall CybersecurityBenchmarks" && return 1
    deactivate
    __besman_echo_no_colour ""
    __besman_echo_green "CybersecurityBenchmarks uninstalled successfully"
    __besman_echo_no_colour ""
    __besman_echo_white "Uninstalling codeshield"
    source ~/.venvs/codeshield_env/bin/activate
    python3 -m pip uninstall -y codeshield
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to uninstall codeshield" && return 1
    deactivate
    __besman_echo_no_colour ""
    __besman_echo_green "codeshield uninstalled successfully"
    __besman_echo_no_colour ""
    __besman_echo_white "Removing $BESMAN_TOOL_PATH"
    rm -rf "$BESMAN_TOOL_PATH"
    [[ $? -ne 0 ]] && __besman_echo_red "Failed to remove $BESMAN_TOOL_PATH" && return 1
    __besman_echo_no_colour ""
    __besman_echo_green "$BESMAN_TOOL_PATH removed successfully"
    __besman_echo_no_colour ""
    __besman_echo_green "Uninstallation completed successfully"
    [[ -d ~/.venvs/codeshield_env ]] && rm -rf ~/.venvs/codeshield_env
    [[ -d ~/.venvs/cyberseceval ]] && rm -rf ~/.venvs/cyberseceval
    cd "$HOME"

}

# function __besman_update {

# }

# function __besman_validate {

# }

# function __besman_reset {

# }
