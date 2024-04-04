#!/bin/bash

# Check if Yarn is installed
if ! command -v yarn &> /dev/null
then
    echo "Yarn is not installed. Installing Yarn..."
    # Add Yarn repository key
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    # Add Yarn repository
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    # Update package index
    sudo apt update
    # Install Yarn
    sudo apt install yarn -y
fi

# Clone OpenCTI Frontend repository

cd $HOME/CRS_Work/projects/opencti/opencti-platform/opencti-front

# Install dependencies using Yarn
yarn install

# Build frontend
yarn build

# Serve frontend
yarn start


#sleep 30 # Wait for the server to start (you may adjust the duration if needed)
#firefox http://localhost:4000

echo "OpenCTI Frontend is now running!"
