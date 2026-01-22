#!/bin/bash

function __besman_install() {
    # Clone Odoo source code
    echo "Cloning Odoo source code..."
    if [ -d "$BESMAN_ARTIFACT_DIR" ]; then
        echo "Updating existing Odoo repository"
        cd "$BESMAN_ARTIFACT_DIR" && git pull
    else
        git clone "$BESMAN_ARTIFACT_URL" "$BESMAN_ARTIFACT_DIR"
    fi

    # Install system dependencies
    echo "Installing system dependencies..."
    sudo apt-get update
    sudo apt-get install -y python3 python3-pip build-essential libjpeg-dev libpng-dev libtiff-dev libpostgresql-dev libxml2-dev libxslt-dev

    # Install Docker and Docker Compose
    echo "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        sudo apt-get install -y docker.io
        sudo usermod -aG docker "$USER"
    fi

    echo "Installing Docker Compose..."
    if ! command -v docker-compose &> /dev/null; then
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Install assessment tools
    echo "Installing assessment tools..."

    # SPDX SBOM Generator
    if ! command -v spdx-sbom-generator &> /dev/null; then
        echo "Installing SPDX SBOM Generator..."
        curl -L -o "$BESMAN_TOOL_PATH/spdx-sbom-generator.tar.gz" "$BESMAN_SPDX_SBOM_ASSET_URL"
        tar -xzf "$BESMAN_TOOL_PATH/spdx-sbom-generator.tar.gz" -C "$BESMAN_TOOL_PATH"
        ln -sf "$BESMAN_TOOL_PATH/spdx-sbom-generator*/spdx-sbom-generator" /usr/local/bin/
    fi

    # SonarQube
    echo "Starting SonarQube container..."
    mkdir -p "$BESMAN_TOOL_PATH/sonarqube"
    docker-compose -f "$BESMAN_TOOL_PATH/sonarqube/docker-compose.yml" up -d

    # Criticality Score
    if ! command -v criticality_score &> /dev/null; then
        echo "Installing Criticality Score..."
        go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
    export PATH="$PATH:$(go env GOPATH)/bin"
fi

# Snyk
if ! command -v snyk &> /dev/null; then
    echo "Installing Snyk..."
    curl -o- https://static.snyk.io/tools/snyk-ocular| bash
fi

# Fossology
echo "Starting Fossology container..."
docker-compose -f "$BESMAN_TOOL_PATH/fossology/docker-compose.yml" up -d

    # Install Python dependencies
    echo "Installing Python dependencies..."
    pip3 install -r "$BESMAN_ARTIFACT_DIR/requirements.txt"

    # Initialize Odoo database
    echo "Initializing Odoo database..."
    cd "$BESMAN_ARTIFACT_DIR && ./odoo-bin.py -c "from odoo.cli.server import main; main()" -i
}

function __besman_uninstall() {
    echo "Stopping and uninstalling..."
    # Stop containers
    docker-compose -f "$BESMAN_TOOL_PATH/sonarqube/docker-compose.yml" down
    docker-compose -f "$BESMAN_TOOL_PATH/fossology/docker-compose.yml" down

    # Remove tools
    rm -rf "$BESMAN_ARTIFACT_DIR"
    rm -rf "$BESMAN_TOOL_PATH"/*

    # Uninstall Docker
    sudo apt-get purge -y docker.io docker-compose
}

function __besman_update() {
    echo "Updating environment..."
    # Update Odoo
    cd "$BESMAN_ARTIFACT_DIR" && git fetch && git checkout "$BESMAN_ARTIFACT_VERSION"

    # Update tools
    pip3 install --upgrade -r "$BESMAN_ARTIFACT_DIR/requirements.txt"

    # Restart containers
    docker-compose -f "$BESMAN_TOOL_PATH/sonarqube/docker-compose.yml" down && docker-compose up -d
    docker-compose -f "$BESMAN_TOOL_PATH/fossology/docker-compose.yml" down && docker-compose up -d
}

function __besman Validate() {
    # Check Docker status
    if ! command -v docker &> /dev/null || ! command -v docker-compose &> /dev/null; then
        echo "Docker or Docker Compose is not installed"
        return 1
    fi

    # Check tool installation
    if ! command -v criticality_score &> /dev/null || ! command -v snyk &> /dev/null; then
        echo "Required tools are missing"
        return 1
    fi

    # Check service status
    if ! docker ps | grep -q sonarqube && ! docker ps | grep -q fossology; then
        echo "Services are not running"
        return 1
}

function __besman_Reset() {
    # Reset database
    cd "$BESMAN_ARTIFACT_DIR && ./odoo-bin -c /etc/odoo/odoo.conf --stopall
    rm -rf "$BESMAN_ASSESSMENT_DATASTORE_DIR/*"

    # Restart services
    docker-compose -f "$BESMAN_TOOL_PATH/sonarqube/docker-compose.yml" down && docker-compose up -d
}

# Configuration file
export BESMAN_ARTIFACT_TYPE="project"
export BESMAN_ARTIFACT_NAME="odoo"
export BESMAN_ARTIFACT_VERSION="16.0"
export BESMAN_ARTIFACT_URL="https://github.com/odoo/odoo"
export BESMAN_ENV_NAME="odoo-sec-env"
export BESMAN_ARTIFACT_DIR="$HOME/bin/odoo"
export BESMAN_TOOL_PATH="/opt/security-tools"
export BESMAN_LAB_TYPE="Organization"
export BESMAN_LAB_NAME="security-audit"
export BESMAN_ASSESSMENT_DATASTORE_DIR="$HOME/assessment-reports"
export BESMAN_ASSESSMENT_DATASTORE_URL="https://github.com/bin/assessment-reports"
export BESMAN_ASSESSMENT_TOOLS="spdx-sbom-generator,sonarqube,criticality_score,snyk,fossology"