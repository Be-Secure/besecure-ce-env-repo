#!/bin/bash

function __besman_install
{
    echo "--------------------------------------------"
    echo "Starting CounterFit Installation..."
    echo "--------------------------------------------"
    
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
    conda create -y -n counterfit python=3.8
    echo "Activating conda environment 'counterfit'..."
    source activate counterfit

    echo "Cloning the CounterFit repository..."
    git clone --single-branch --branch dist https://github.com/pramit-d/counterfit
    cd counterfit
    echo "Installing Python packages from requirements.txt..."
    pip install -r requirements.txt
    python -c "import nltk;  nltk.download('stopwords')"
    echo "Installing CounterFit tool..."
    pip install -e .
    bash
}

function __besman_uninstall
{   
       echo "--------------------------------------------"
    echo "Starting CounterFit Uninstallation..."
    echo "--------------------------------------------"
    echo "Removing Anaconda distribution..."
    rm -rf anaconda3
    rm -rf ~/anaconda3
    sudo rm -rf /opt/anaconda3
    rm -rf .conda .art .keras nltk_data
    read -p "${bold}Do you want to remove the directory 'counterfit'? (y/n): " response
    if [[ "$response" == "y" || "$response" == "Y" || "$response" == "Yes" || "$response" == "yes" ]]; then
        if rm -rf $HOME/counterfit; then
            echo "Directory 'counterfit' has been removed."
        else
            echo "Failed to remove the directory 'counterfit'."
        fi
    else
        echo "Skipping the removal of 'counterfit' directory..."
    fi
    echo "-------------------------------------------------------"
    echo "CounterFit environment uninstallation completed!"
    echo "-------------------------------------------------------"
    bash
}

function __besman_update
{
    echo "Update"
}

function __besman_validate
{
    echo "Validate"
}

function __besman_reset
{
    echo "Reset"
}

__besman_install