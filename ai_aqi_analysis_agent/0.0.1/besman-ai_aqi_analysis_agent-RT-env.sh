#!/usr/bin/env bash

function __besman_install {
    __besman_echo_white "Installing environment for AI AQI Analysis Agent..."

    # Check pre-requisites
    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1

    # Clone the POI repo
    if [[ -d "$BESMAN_POI_DIR" ]]; then
        __besman_echo_white "Repo already cloned at $BESMAN_POI_DIR"
    else
        git clone "$BESMAN_POI_REPO_URL" "$BESMAN_POI_DIR" || {
            __besman_echo_red "Failed to clone repository."
            return 1
        }
    fi

    cd "$BESMAN_POI_DIR" || return 1

    # Check for Python environment
    if ! command -v python3 >/dev/null; then
        __besman_echo_white "Installing Python3..."
        sudo apt-get update
        sudo apt-get install -y python3 python3-venv python3-pip
    fi

    # Create Python virtual environment
    python3 -m venv "$BESMAN_VENV_PATH"
    source "$BESMAN_VENV_PATH/bin/activate"

    pip install --upgrade pip

    # Install dependencies from requirements.txt if it exists
    if [[ -f requirements.txt ]]; then
        __besman_echo_white "Installing Python dependencies from requirements.txt..."
        pip install -r requirements.txt
    else
        __besman_echo_yellow "No requirements.txt found. Skipping Python dependencies."
    fi

    deactivate

    __besman_echo_white "Installation completed successfully!"
}

function __besman_uninstall {
    __besman_echo_white "Uninstalling AI AQI Analysis Agent environment..."

    rm -rf "$BESMAN_POI_DIR"
    rm -rf "$BESMAN_VENV_PATH"

    __besman_echo_white "Environment removed successfully!"
}

function __besman_validate {
    __besman_echo_white "Validating AI AQI Analysis Agent environment..."

    if [[ ! -d "$BESMAN_POI_DIR" ]]; then
        __besman_echo_red "POI repo not found at $BESMAN_POI_DIR"
        return 1
    fi

    if [[ ! -d "$BESMAN_VENV_PATH" ]]; then
        __besman_echo_red "Virtual environment not found at $BESMAN_VENV_PATH"
        return 1
    fi

    __besman_echo_green "Validation successful. Environment appears correctly set up."
}

function __besman_update {
    __besman_echo_white "Updating AI AQI Analysis Agent..."

    if [[ -d "$BESMAN_POI_DIR" ]]; then
        cd "$BESMAN_POI_DIR" || return 1
        git pull
    else
        __besman_echo_red "Repo directory not found. Cannot update."
        return 1
    fi
}

function __besman_reset {
    __besman_echo_white "Resetting AI AQI Analysis Agent environment..."
    __besman_uninstall
    __besman_install
}
