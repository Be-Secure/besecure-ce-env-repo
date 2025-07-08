#!/bin/bash

#------------------------------------------
# INSTALL
#------------------------------------------
function __besman_install {
    set -x

    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1

    #------------------------------------------
    # Helper Function for Package Check/Install
    #------------------------------------------
    function check_and_install() {
        local pkg="$1"
        if ! command -v "$pkg" &>/dev/null; then
            __besman_echo_white "$pkg not found. Installing..."
            sudo apt-get install -y "$pkg"
        else
            __besman_echo_white "$pkg already installed."
        fi
    }

    # Update package index once
    __besman_echo_white "Updating apt cache..."
    sudo apt-get update -y

    # Check and install required system packages
    check_and_install git
    check_and_install python3
    check_and_install python3-pip
    check_and_install python3-venv
    check_and_install pytest

    # Create environment directory if missing
    __besman_echo_white "Preparing environment directory..."
    mkdir -p "$BESMAN_ENV_DIR"
    mkdir -p "$BESMAN_TOOLS_DIR"

    # Create virtual environment
    __besman_echo_white "Creating virtual environment at: $BESMAN_ENV_DIR/$BESMAN_VENV_NAME"
    python3 -m venv "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME"
    source "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME/bin/activate"

    # Upgrade pip inside venv
    __besman_echo_white "⬆️ Upgrading pip in virtual environment..."
    pip install --upgrade pip

    # Install Jupyter Notebook and ipykernel
    if ! python -c "import notebook" &>/dev/null; then
        __besman_echo_white "Installing Jupyter Notebook in venv..."
        pip install notebook
    else
        __besman_echo_white "Jupyter Notebook already installed in venv."
    fi

    pip install ipykernel
    # Register kernel for Jupyter
    python -m ipykernel install --user --name "$BESMAN_VENV_NAME" --display-name "Python ($BESMAN_VENV_NAME)"

    #-----------------------------------------------
    # Tool - ART
    #-----------------------------------------------
    __besman_echo_white "Cloning ART from $BESMAN_ART_REPO..."
    cd "$BESMAN_TOOLS_DIR"

    if [ ! -d "adversarial-robustness-toolbox" ]; then
        git clone "$BESMAN_ART_REPO"
    else
        __besman_echo_white "ART repository already cloned."
    fi

    cd adversarial-robustness-toolbox
    pip install -r requirements_test.txt

    __besman_echo_white "⚙️ Installing ART dependencies..."
    pip install .

    __besman_echo_white "Installation completed successfully!"
}

#------------------------------------------
# UNINSTALL
#------------------------------------------
function __besman_uninstall {

    __besman_echo_white "Uninstalling ML Assessment Environment..."

    # Remove virtual environment
    if [ -d "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME" ]; then
        rm -rf "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME"
        __besman_echo_white "Virtual environment removed."
    else
        __besman_echo_white "Virtual environment does not exist."
    fi

    # Optionally remove cloned repositories
    if [ -d "$BESMAN_TOOLS_DIR/adversarial-robustness-toolbox" ]; then
        rm -rf "$BESMAN_TOOLS_DIR/adversarial-robustness-toolbox"
        __besman_echo_white "ART repository removed."
    fi

    __besman_echo_white "Uninstallation completed."
}

#------------------------------------------
# UPDATE
#------------------------------------------
function __besman_update {
    __besman_echo_white "Updating environment..."

    # Example: Pull latest changes in repos
    # cd "$BESMAN_TOOLS_DIR/watchtower" && git pull
    cd "$BESMAN_TOOLS_DIR/adversarial-robustness-toolbox" && git pull

    # Reinstall packages if needed
    source "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME/bin/activate"
    pip install --upgrade .

    __besman_echo_white "Update completed."
}

#------------------------------------------
# VALIDATE
#------------------------------------------
function __besman_validate {

    __besman_echo_white "Validating environment..."

    # Check virtual environment exists
    if [ ! -d "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME" ]; then
        __besman_echo_white "Virtual environment missing."
        return 1
    fi

    source "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME/bin/activate"

    # Check ART
    python -c "import art" &>/dev/null
    if [ $? -eq 0 ]; then
        __besman_echo_white "ART import successful."
    else
        __besman_echo_white "ART not properly installed."
        return 1
    fi

    # Check Jupyter
    python -c "import notebook" &>/dev/null
    if [ $? -eq 0 ]; then
        __besman_echo_white "Jupyter Notebook import successful."
    else
        __besman_echo_white "Jupyter Notebook not installed."
        return 1
    fi

    __besman_echo_white "Environment validation complete. All checks passed."
}

#------------------------------------------
# RESET
#------------------------------------------
function __besman_reset {
    __besman_echo_white "Resetting ML Assessment Environment..."
    __besman_uninstall
    __besman_install
}
