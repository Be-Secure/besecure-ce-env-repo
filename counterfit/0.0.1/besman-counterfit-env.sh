#!/bin/bash

function __besman_install
{   
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    REQUIRED_VERSION="3.8"
    if [[ $(echo "$PYTHON_VERSION $REQUIRED_VERSION" | awk '{print ($1 >= $2)}') == 1 ]]; then
        echo "Python 3.8 or newer is already installed."
    else
        echo "Python 3.8 or newer is not installed. Installing Python..."
        sudo apt-get update
        sudo apt-get install -y python3.8 python3.8-venv python3.8-dev
        sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
    fi

    if command -v pip3 &> /dev/null; then
        echo "pip is already installed."
    else
        echo "Installing pip..."
        sudo apt-get update
        sudo apt-get install -y python3-pip
    fi

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

    echo "Creating conda environment 'counterfit_env'..."
    conda create -y -n counterfit_env python=3.8
    echo "Activating conda environment 'counterfit_env'..."
    source activate counterfit_env

    echo "Cloning the Counterfit repository..."
    git clone --single-branch --branch dist https://github.com/pramit-d/counterfit
    cd counterfit
    echo "Installing Python packages from requirements.txt..."
    pip install -r requirements.txt
    python3 -c "import nltk;  nltk.download('stopwords')"
    echo "Installing Counterfit tool..."
    pip install -e .
    bash
    echo "CounterFit installation complete!"
}

function __besman_uninstall
{
    echo "Uninstall"
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

