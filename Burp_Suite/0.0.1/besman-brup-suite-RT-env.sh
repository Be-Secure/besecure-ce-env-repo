#!/bin/bash

# # Function to parse YAML file
# parse_yaml() {
#    local prefix=$2
#    local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
#    sed -ne "s|^\($s\):|\1|" \
#         -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
#         -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
#    awk -F$fs '{
#       indent = length($1)/2;
#       vname[indent] = $2;
#       for (i in vname) {if (i > indent) {delete vname[i]}}
#       if (length($3) > 0) {
#          vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
#          printf("%s%s%s=\"%s\"\n", "'$prefix'", vn, $2, $3);
#       }
#    }'
# }

# # Load configuration
# eval $(parse_yaml besman-brup-suite-RT-env-config.yaml "config_")

function __besman_install(){
    echo "Installing assessment tools and dependencies..."

    # Install prerequisites
    sudo apt-get update
    sudo apt-get install -y git curl jq python3-pip openjdk-11-jre

    # Clone repositories and install tools
    git clone "${config_tools_semgrep}" || { echo "Failed to clone Semgrep"; exit 1; }
    git clone "${config_tools_codeql}" || { echo "Failed to clone CodeQL"; exit 1; }
    git clone "${config_tools_bandit}" || { echo "Failed to clone Bandit"; exit 1; }
    git clone "${config_tools_find_sec_bugs}" || { echo "Failed to clone FindSecBugs"; exit 1; }
    git clone "${config_tools_syft}" || { echo "Failed to clone Syft"; exit 1; }
    git clone "${config_tools_grype}" || { echo "Failed to clone Grype"; exit 1; }
    git clone "${config_tools_trivy}" || { echo "Failed to clone Trivy"; exit 1; }
    git clone "${config_tools_cyclonedx_cli}" || { echo "Failed to clone CycloneDX CLI"; exit 1; }
    git clone "${config_tools_scancode_toolkit}" || { echo "Failed to clone ScanCode ToolKit"; exit 1; }
    git clone "${config_tools_spdx_tools}" || { echo "Failed to clone SPDX Tools"; exit 1; }

    # Install each tool using its specific method
    # Example for Semgrep
    cd semgrep && pip install . && cd ..

    # Repeat for other tools...
    echo "Installation complete."
}

function __besman_uninstall(){
    echo "Uninstalling assessment tools and dependencies..."
    # Example for Semgrep
    pip uninstall -y semgrep

    # Repeat for other tools...
    echo "Uninstallation complete."
}

function __besman_validate(){
    echo "Validating installation of tools..."
    # Check if tools are installed
    command -v semgrep >/dev/null 2>&1 && echo "Semgrep is installed" || echo "Semgrep is not installed"
    # Repeat for other tools...
}

function __besman_update(){
    echo "Updating assessment tools..."
    # Example for Semgrep
    cd semgrep && git pull && pip install . && cd ..

    # Repeat for other tools...
    echo "Update complete."
}

function __besman_reset(){
    echo "Resetting tools to default configuration..."
    # Example reset logic
    rm -rf semgrep
    # Repeat for other tools...
    echo "Reset complete."
}

# Execute based on the first argument
case "$1" in
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
        echo "Usage: $0 {install|uninstall|validate|update|reset}"
        exit 1
esac