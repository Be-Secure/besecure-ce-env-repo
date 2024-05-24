#!/bin/bash

function __besman_install
{
    echo "------------------------------------------------------"
    echo "Starting CounterFit Installation..."
    echo "------------------------------------------------------"
    install_counterfit
    echo "-------------------------------------------------------"
    echo "CounterFit environment installation completed!"
    echo "-------------------------------------------------------"
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
    conda update -c conda-forge --all -y
    conda create --yes -n counterfit python=3.8.0
    echo "Activating conda environment 'counterfit'..."
    conda activate counterfit
    echo "Cloning the CounterFit repository..."
    git clone --single-branch --branch $BESMAN_COUNTERFIT_BRANCH $BESMAN_COUNTERFIT_URL $BESMAN_COUNTERFIT_LOCAL_PATH
    cd counterfit
    echo "Installing Python packages from requirements.txt..."
    pip install -r requirements.txt
    echo "Installing CounterFit tool..."
    pip install -e .
    python -c "import nltk;  nltk.download('stopwords')"
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
        echo "Removing the directory 'counterfit'..."
        rm -rf $BESMAN_COUNTERFIT_LOCAL_PATH && echo "Directory 'counterfit' has been removed." || echo "Failed to remove the directory 'counterfit'."
    else
        read -p "${bold}Do you want to remove the directory 'counterfit'? (y/n): " response
        if [[ "$response" == "y" || "$response" == "Y" || "$response" == "Yes" || "$response" == "yes" ]]; then
            if rm -rf $BESMAN_COUNTERFIT_LOCAL_PATH; then
                echo "Directory 'counterfit' has been removed."
            else
                echo "Failed to remove the directory 'counterfit'."
            fi
        else
            echo "Skipping the removal of 'counterfit' directory..."
        fi
    fi
}