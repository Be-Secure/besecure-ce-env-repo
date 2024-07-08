#!/bin/bash

function __besman_install
{
    __besman_check_github_id || return 1
    echo "------------------------------------------------------"
    echo "Starting PurpleLama Installation..."
    echo "------------------------------------------------------"
    install_purpleLlama
    echo "------------------------------------------------------"
    echo "Purplelama environment installation completed!"
    echo "------------------------------------------------------"

}

function __besman_uninstall
{
    
}

function __besman_update
{
    echo "Reset method not implemented yet."
}

function __besman_validate
{
    echo "Reset method not implemented yet."
}

function __besman_reset
{
    echo "Reset method not implemented yet."
}


function install_purpleLlama() {
    echo "Cloning the PurpleLama repository..."
    git clone --single-branch --branch $BESMAN_PURPLELAMA_BRANCH $BESMAN_PURPLELAMA_URL $BESMAN_PURPLELAMA_LOCAL_PATH

    echo "Installing required dependency..."
    sudo apt -y update
    sudo apt -y upgrade
    sudo apt install -y python3-pip
    cargo install weggli --rev=9d97d462854a9b682874b259f70cc5a97a70f2cc --git=https://github.com/weggli-rs/weggli
    export WEGGLI_PATH=weggli
    python3 -m venv ~/.venvs/CybersecurityBenchmarks
    source ~/.venvs/CybersecurityBenchmarks/bin/activate
    export DATASETS=$PWD/CybersecurityBenchmarks/datasets

    echo "Installing Python packages from requirements.txt..."
    cd $BESMAN_PURPLELAMA_LOCAL_PATH
    pip3 install -r CybersecurityBenchmarks/requirements.txt
    python3 -m CybersecurityBenchmarks.benchmark.run --help
}

function uninstall_PurpleLlama(){
    AUTO_DELETE=${1:-false}
    
    if [ "$AUTO_DELETE" = true ]; then
        echo "Removing the directory '$BESMAN_PURPLELAMA_LOCAL_PATH'..."
        rm -rf $BESMAN_PURPLELAMA_LOCAL_PATH && echo "Directory 'PurpleLlama' has been removed." || echo "Failed to remove the directory 'PurpleLlama'."
    else
        read -p "${bold}Do you want to remove the directory '$BESMAN_PURPLELAMA_LOCAL_PATH'? (y/n): " response
        if [[ "$response" == "y" || "$response" == "Y" || "$response" == "Yes" || "$response" == "yes" ]]; then
            if rm -rf $BESMAN_PURPLELAMA_LOCAL_PATH; then
                echo "Directory '$BESMAN_PURPLELAMA_LOCAL_PATH' has been removed."
            else
                echo "Failed to remove the directory '$BESMAN_PURPLELAMA_LOCAL_PATH'."
            fi
        else
            echo "Skipping the removal of '$BESMAN_PURPLELAMA_LOCAL_PATH' directory..."
        fi
    fi
}

