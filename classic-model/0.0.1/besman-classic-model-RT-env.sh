#!/bin/bash

function __besman_install
{
    __besman_check_github_id || return 1
    echo "------------------------------------------------------"
    echo "Starting CounterFit Installation..."
    echo "------------------------------------------------------"
    install_counterfit
    echo "------------------------------------------------------"
    echo "CounterFit environment installation completed!"
    echo "------------------------------------------------------"
    echo "------------------------------------------------------"
    echo "Starting Watchtower Installation..."
    echo "------------------------------------------------------"
    install_watchtower
    echo "------------------------------------------------------"
    echo "Watchtower environment installation completed!"
    echo "------------------------------------------------------"
    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]] 
    then
        __besman_echo_white "ML Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning ML assessment datastore from $BESMAN_USER_NAMESPACE/besecure-ml-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-ml-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi
    bash
}

function __besman_uninstall
{   
    echo "-------------------------------------------------------"
    echo "Starting CounterFit Uninstallation..."
    echo "-------------------------------------------------------"
    uninstall_counterfit
    echo "-------------------------------------------------------"
    echo "CounterFit environment uninstallation completed!"
    echo "-------------------------------------------------------"
    echo "-------------------------------------------------------"
    echo "Starting Watchtower Uninstallation..."
    echo "-------------------------------------------------------"
    uninstall_watchtower
    echo "-------------------------------------------------------"
    echo "Watchtower environment uninstallation completed!"
    echo "-------------------------------------------------------"
    bash
}

function __besman_update
{
    echo "No update available."
}

function __besman_validate
{
    echo "Validate method not implemented yet."
}

function __besman_reset
{       
    echo "Reset method not implemented yet."
}

function install_counterfit() {
    sudo apt-get install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
    echo "Checking for Anaconda..."
    if command -v conda &> /dev/null; then
        echo "Anaconda is already installed."
    else
        echo "Installing Anaconda..."
        wget https://repo.anaconda.com/archive/Anaconda3-2023.03-Linux-x86_64.sh -O /tmp/anaconda.sh
        bash /tmp/anaconda.sh -b -p $HOME/anaconda3
        eval "$($HOME/anaconda3/bin/conda shell.bash hook)"
        conda init bash
        source ~/.bashrc
        rm /tmp/anaconda.sh
    fi
    eval "$(conda shell.bash hook)"
    echo "Creating conda environment 'counterfit'..."
    conda update conda -y
    conda create --yes -n counterfit python=3.8.0
    echo "Activating conda environment 'counterfit'..."
    conda activate counterfit
    echo "Cloning the CounterFit repository..."
    git clone --single-branch --branch $BESMAN_COUNTERFIT_BRANCH $BESMAN_COUNTERFIT_URL $BESMAN_COUNTERFIT_LOCAL_PATH
    echo "Installing Python packages from requirements.txt..."
    python3 -m pip install -r $BESMAN_COUNTERFIT_LOCAL_PATH/requirements.txt
    echo "Installing CounterFit tool..."
    python3 -m pip install -e $BESMAN_COUNTERFIT_LOCAL_PATH
    python3 -c "import nltk;  nltk.download('stopwords')" && conda deactivate
    conda config --set auto_activate_base false
}

function uninstall_counterfit(){
    AUTO_DELETE=${1:-false}
    echo "Removing Anaconda distribution..."
    conda activate
    conda init --reverse --all
    rm -rf anaconda3
    rm -rf ~/anaconda3
    sudo rm -rf /opt/anaconda3
    rm -rf .conda .art .keras nltk_data
    
    if [ "$AUTO_DELETE" = true ]; then
        echo "Removing the directory '$BESMAN_COUNTERFIT_LOCAL_PATH'..."
        rm -rf $BESMAN_COUNTERFIT_LOCAL_PATH && echo "Directory 'counterfit' has been removed." || echo "Failed to remove the directory 'counterfit'."
    else
        read -p "${bold}Do you want to remove the directory '$BESMAN_COUNTERFIT_LOCAL_PATH'? (y/n): " response
        if [[ "$response" == "y" || "$response" == "Y" || "$response" == "Yes" || "$response" == "yes" ]]; then
            if rm -rf $BESMAN_COUNTERFIT_LOCAL_PATH; then
                echo "Directory '$BESMAN_COUNTERFIT_LOCAL_PATH' has been removed."
            else
                echo "Failed to remove the directory '$BESMAN_COUNTERFIT_LOCAL_PATH'."
            fi
        else
            echo "Skipping the removal of '$BESMAN_COUNTERFIT_LOCAL_PATH' directory..."
        fi
    fi
}

function install_watchtower(){
    command_exists() {
        command -v "$1" >/dev/null 2>&1
    }

    if ! command_exists python3; then
        echo "Python3 is not installed. Installing Python3..."
        sudo apt-get update
        sudo apt-get install -y python3
    fi

    if ! command_exists git; then
        echo "Git is not installed. Installing Git..."
        sudo apt-get install -y git
    fi

    if ! python3 -m venv --help > /dev/null 2>&1; then
        echo "venv module is not available. Installing python3-venv..."
        sudo apt-get install -y python3-venv
    fi

    echo "Creating a virtual environment watchtower_env..."
    python3 -m venv $HOME/watchtower_env

    echo "Activating watchtower_env..."
    source $HOME/watchtower_env/bin/activate

    echo "Cloning the Watchtower repository..."
    if [ ! -d "$HOME/watchtower/" ]; then
        git clone --branch $BESMAN_WATCHTOWER_VERSION --depth 1 $BESMAN_WATCHTOWER_URL $HOME/watchtower/
    fi

    echo "Installing Watchtower dependencies..."
    pip install -r $HOME/watchtower/src/requirements.txt

    echo "Downloading the spaCy language model..."
    python3 -m spacy download en_core_web_lg
}

function uninstall_watchtower(){
    echo "Removing watchtower_env..."
    if [ -d "$HOME/watchtower_env" ]; then
        rm -rf $HOME/watchtower_env
    else
        echo "watchtower_env not found."
    fi

    echo "Removing the Watchtower repository..."
    if [ -d "$HOME/watchtower/" ]; then
        rm -rf $HOME/watchtower/
    else
        echo "Watchtower repository directory not found."
    fi
}
