#!/bin/bash

# Check if Python is installed
if ! command -v python3 &> /dev/null
then
    echo "Python is not installed. Installing Python..."
    sudo apt update
    sudo apt install python3 -y
fi

# Check if pip is installed
if ! command -v pip3 &> /dev/null
then
    echo "pip is not installed. Installing pip..."
    sudo apt update
    sudo apt install python3-pip -y
fi

# Navigate to the directory containing the worker script
cd $HOME/CRS_Work/projects/opencti/opencti-worker/src

# Install dependencies using pip
pip3 install -r requirements.txt

# Start the worker
python3 worker.py

