#!/bin/bash

# Function to install TensorFlow and transformers
function install_packages {
    echo "Installing TensorFlow..."
    pip install TensorFlow

    if [ $? -eq 0 ]; then
        echo "TensorFlow installed successfully."
    else
        echo "Failed to install TensorFlow."
        return 1
    fi

    echo "Installing transformers..."
    pip install transformers

    if [ $? -eq 0 ]; then
        echo "Transformers installed successfully."
    else
        echo "Failed to install transformers."
        return 1
    fi

    return 0
}

# Main installation function
function __besman_install {
    echo "Starting installation process..."

    # Check if pip is installed
    if ! command -v pip &>/dev/null; then
        echo "pip is not installed. Please install pip first."
        return 1
    fi

    # Install TensorFlow and transformers
    install_packages

    if [ $? -eq 0 ]; then
        echo "All packages installed successfully."
    else
        echo "Installation failed."
        return 1
    fi
}

# Main uninstallation function
function __besman_uninstall {
    echo "Starting uninstallation process..."

    echo "Uninstalling TensorFlow..."
    pip uninstall -y TensorFlow

    if [ $? -eq 0 ]; then
        echo "TensorFlow uninstalled successfully."
    else
        echo "Failed to uninstall TensorFlow."
    fi

    echo "Uninstalling transformers..."
    pip uninstall -y transformers

    if [ $? -eq 0 ]; then
        echo "Transformers uninstalled successfully."
    else
        echo "Failed to uninstall transformers."
    fi

    echo "Uninstallation process completed."
}

# Main update function
function __besman_update {
    echo "Updating TensorFlow and transformers..."

    echo "Updating TensorFlow..."
    pip install --upgrade TensorFlow

    if [ $? -eq 0 ]; then
        echo "TensorFlow updated successfully."
    else
        echo "Failed to update TensorFlow."
    fi

    echo "Updating transformers..."
    pip install --upgrade transformers

    if [ $? -eq 0 ]; then
        echo "Transformers updated successfully."
    else
        echo "Failed to update transformers."
    fi

    echo "Update process completed."
}

# Main validate function
function __besman_validate {
    echo "Validating installations..."

    validationStatus=1
    declare -a errors

    # Validate TensorFlow installation
    if ! pip show TensorFlow &>/dev/null; then
        echo "TensorFlow is not installed."
        validationStatus=0
        errors+=("TensorFlow")
    fi

    # Validate transformers installation
    if ! pip show transformers &>/dev/null; then
        echo "Transformers is not installed."
        validationStatus=0
        errors+=("Transformers")
    fi

    if [ $validationStatus -eq 1 ]; then
        echo "All packages are installed correctly."
    else
        echo "Validation failed. Missing packages: ${errors[@]}"
    fi

    return $validationStatus
}

# Main reset function
function __besman_reset {
    echo "Resetting environment..."

    __besman_uninstall
    __besman_install

    echo "Reset process completed."
}

