#!/bin/bash

# # Loading configuration from the YAML file
# function load_config() {
#     local config_file="$1"
#     eval $(parse_yaml "$config_file" "config_")
# }

# # Function to parse YAML file
# function parse_yaml() {
#     local file=$1
#     python3 -c "
# import sys
# import yaml

# def parse_yaml(file):
#     with open(file, 'r') as f:
#         data = yaml.safe_load(f)
#         for key, value in data.items():
#             print(f'{key}={value}')

# parse_yaml('$file')
# "
# }

# Install the assessment tools and dependencies
function __besman_install() {
    echo "Starting installation..."

    # Install dependencies
    __besman_install_docker
    __besman_install_go
    __besman_install_snap

    # Clone the required repositories
    echo "Cloning the assessment tools repositories..."
    __besman_install_tools

    echo "Installation complete."
}

# Install Docker if not already installed
function __besman_install_docker() {
    if ! command -v docker &>/dev/null; then
        echo "Docker is not installed. Installing Docker..."
        sudo apt update
        sudo apt install -y ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        sudo usermod -aG docker $USER
        sudo systemctl restart docker
    else
        echo "Docker is already installed."
    fi
}

# Install Snap if not already installed
function __besman_install_snap() {
    if ! command -v snap &>/dev/null; then
        echo "Snap is not installed. Installing Snap..."
        sudo apt update
        sudo apt install snapd
    else
        echo "Snap is already installed."
    fi
}

# Install Go if not already installed
function __besman_install_go() {
    if ! command -v go &>/dev/null; then
        echo "Go is not installed. Installing Go..."
        sudo snap install go --classic
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    else
        echo "Go is already installed."
    fi
}

# Install assessment tools
# Install assessment tools
function __besman_install_tools() {
    tools=("semgrep" "codeql" "bandit" "findsecbugs" "owasp" "syft" "grype" "trivy" "cyclonedx-cli" "scancode-toolkit" "spdx-tool")
    
    for tool in "${tools[@]}"; do
        echo "Installing $tool..."
        case $tool in
            "semgrep")
                pip install semgrep
                ;;
            "codeql")
                curl -L https://github.com/github/codeql-cli-binaries/releases/download/v2.9.2/codeql-linux64.zip -o codeql.zip
                unzip codeql.zip -d $HOME/codeql
                ;;
            "bandit")
                pip install bandit
                ;;
            "findsecbugs")
                git clone https://github.com/find-sec-bugs/find-sec-bugs.git
                cd find-sec-bugs && ./gradlew build
                ;;
            "owasp")
                git clone https://github.com/OWASP/OWASP-Dependency-Check.git
                cd OWASP-Dependency-Check && ./mvnw clean install
                ;;
            "syft")
                curl -sSfL https://github.com/anchore/syft/releases/download/v0.38.0/syft-linux-amd64-v0.38.0.tar.gz | tar -xvzf - -C /usr/local/bin syft
                ;;
            "grype")
                curl -sSfL https://github.com/anchore/grype/releases/download/v0.62.0/grype-linux-amd64-0.62.0.tar.gz | tar -xvzf - -C /usr/local/bin grype
                ;;
            "trivy")
                curl -sfL https://github.com/aquasecurity/trivy/releases/download/v0.25.2/trivy_0.25.2_Linux-64bit.tar.gz | tar -xvzf - -C /usr/local/bin trivy
                ;;
            "cyclonedx-cli")
                curl -sSfL https://github.com/CycloneDX/cyclonedx-cli/releases/download/v0.3.0/cyclonedx-cli-linux-amd64-0.3.0.tar.gz | tar -xvzf - -C /usr/local/bin cyclonedx-cli
                ;;
            "scancode-toolkit")
                git clone https://github.com/nexB/scancode-toolkit.git
                cd scancode-toolkit && python3 setup.py install
                ;;
            "spdx-tool")
                curl -sSfL https://github.com/spdx/tools/releases/download/v2.2.0/spdx-tools-linux-amd64.tar.gz | tar -xvzf - -C /usr/local/bin spdx
                ;;
            *)
                echo "Unknown tool: $tool"
                ;;
        esac
    done
}


# Uninstall the tools and dependencies
function __besman_uninstall() {
    echo "Uninstalling the environment..."

    # Uninstall tools
    __besman_uninstall_tools
    # Remove Docker and Go if installed
    __besman_remove_docker
    __besman_remove_go

    echo "Uninstallation complete."
}

# Uninstall all assessment tools
function __besman_uninstall_tools() {
    tools=("semgrep" "codeql" "bandit" "findsecbugs" "owasp" "syft" "grype" "trivy" "cyclonedx-cli" "scancode-toolkit" "spdx-tool")

    for tool in "${tools[@]}"; do
        echo "Uninstalling $tool..."
        case $tool in
            "semgrep")
                pip uninstall -y semgrep
                ;;
            "codeql")
                rm -rf $HOME/codeql
                ;;
            "bandit")
                pip uninstall -y bandit
                ;;
            "findsecbugs")
                rm -rf find-sec-bugs
                ;;
            "owasp")
                rm -rf OWASP-Dependency-Check
                ;;
            "syft")
                rm -rf /usr/local/bin/syft
                ;;
            "grype")
                rm -rf /usr/local/bin/grype
                ;;
            "trivy")
                rm -rf /usr/local/bin/trivy
                ;;
            "cyclonedx-cli")
                rm -rf /usr/local/bin/cyclonedx-cli
                ;;
            "scancode-toolkit")
                rm -rf scancode-toolkit
                ;;
            "spdx-tool")
                rm -rf /usr/local/bin/spdx
                ;;
            *)
                echo "Unknown tool: $tool"
                ;;
        esac
    done
}

# Remove Docker if installed
function __besman_remove_docker() {
    if command -v docker &>/dev/null; then
        echo "Removing Docker..."
        sudo apt purge -y docker-ce docker-ce-cli containerd.io
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd
        sudo rm -rf /usr/share/keyrings/docker-archive-keyring.gpg
        sudo rm -f /etc/apt/sources.list.d/docker.list
        sudo deluser $USER docker
        sudo groupdel docker
        sudo apt update
    fi
}

# Remove Go if installed
function __besman_remove_go() {
    if command -v go &>/dev/null; then
        echo "Removing Go..."
        sudo snap remove go -y
    fi
}

# Validate the environment setup
function __besman_validate() {
    echo "Validating the environment..."

    # Check Docker, Go, and installed tools
    command -v docker &>/dev/null && echo "Docker is installed."
    command -v go &>/dev/null && echo "Go is installed."
    command -v semgrep &>/dev/null && echo "Semgrep is installed."
    command -v codeql &>/dev/null && echo "CodeQL is installed."

    echo "Validation complete."
}

# Update the environment setup
function __besman_update() {
    echo "Updating the environment..."
    __besman_uninstall
    __besman_install
    echo "Update complete."
}

# Reset the environment setup to default configuration
function __besman_reset() {
    echo "Resetting the environment..."
    __besman_uninstall
    __besman_install
    echo "Reset complete."
}

# Main execution flow
if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <install|uninstall|validate|update|reset> [config_file]"
    exit 1
fi

action=$1
config_file=$2

# Load config if provided
if [[ -f $config_file ]]; then
    load_config $config_file
fi

case $action in
    install)
        __besman_install
        ;;
    uninstall)
        __besman_uninstall
        ;;
    validate)
        __besman_validate
        ;;
    update)
        __besman_update
        ;;
    reset)
        __besman_reset
        ;;
    *)
        echo "Invalid action: $action"
        exit 1
        ;;
esac
