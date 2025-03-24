#!/bin/bash

# Source the configuration file
# source iptables-security-env.yaml

__besman_install() {
    echo "Installing iptables environment..."
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "Directory $BESMAN_ARTIFACT_DIR already exists. Skipping clone."
    else
        echo "Cloning iptables repository from $BESMAN_ARTIFACT_URL..."
        git clone "$BESMAN_ARTIFACT_URL" "$BESMAN_ARTIFACT_DIR" || {
            echo "Failed to clone repository."
            return 1
        }
        cd "$BESMAN_ARTIFACT_DIR" && git checkout "$BESMAN_ARTIFACT_VERSION" || {
            echo "Failed to checkout version $BESMAN_ARTIFACT_VERSION."
            return 1
        }
        cd "$HOME"
    fi

    echo "Installing dependencies for iptables..."
    sudo apt update && sudo apt install -y autoconf libtool bison flex || {
        echo "Failed to install dependencies."
        return 1
    }

    echo "Installing assessment tools..."
    declare -a tools=("spdx-sbom-generator" "sonarqube" "criticality_score" "snyk" "fossology" "CodeQL" "OWASP-Dependency-Check" "Syft" "Trivy" "CycloneDX-CLI" "ScanCode-Toolkit" "OpenSSF-Scorecard")
    for tool in "${tools[@]}"; do
        case "$tool" in
            spdx-sbom-generator)
                echo "Installing SPDX SBOM Generator..."
                curl -L -o "$BESMAN_TOOL_PATH/spdx-sbom-generator" "$BESMAN_SPDX_SBOM_ASSET_URL" && chmod +x "$BESMAN_TOOL_PATH/spdx-sbom-generator"
                ;;
            sonarqube)
                echo "Setting up SonarQube..."
                docker pull "$BESMAN_SONARQUBE_DOCKER_IMAGE"
                docker run -d --name sonarqube -p 9000:9000 sonarqube
                ;;
            criticality_score)
                echo "Installing Criticality Score..."
                go get -u "$BESMAN_CRITICALITY_SCORE_URL"
                ;;
            snyk)
                echo "Installing Snyk..."
                $BESMAN_SNYK_INSTALLATION_COMMAND
                ;;
            fossology)
                echo "Setting up Fossology..."
                docker pull "$BESMAN_FOSSOLOGY_DOCKER_IMAGE"
                docker run -d --name fossology -p 8081:80 fossology/fossology
                ;;
            CodeQL)
                echo "Installing CodeQL..."
                curl -L -o "$BESMAN_TOOL_PATH/codeql.zip" "$BESMAN_CODEQL_ASSET_URL" && unzip "$BESMAN_TOOL_PATH/codeql.zip" -d "$BESMAN_TOOL_PATH"
                ;;
            OWASP-Dependency-Check)
                echo "Installing OWASP Dependency-Check..."
                curl -L -o "$BESMAN_TOOL_PATH/dependency-check.zip" "$BESMAN_OWASP_DEPENDENCY_CHECK_URL" && unzip "$BESMAN_TOOL_PATH/dependency-check.zip" -d "$BESMAN_TOOL_PATH"
                ;;
            Syft)
                echo "Installing Syft..."
                curl -sSfL "$BESMAN_SYFT_INSTALLATION_SCRIPT" | sh -s -- -b "$BESMAN_TOOL_PATH"
                ;;
            Trivy)
                echo "Installing Trivy..."
                curl -sfL "$BESMAN_TRIVY_INSTALLATION_SCRIPT" | sh -s -- -b "$BESMAN_TOOL_PATH"
                ;;
            CycloneDX-CLI)
                echo "Installing CycloneDX CLI..."
                curl -L -o "$BESMAN_TOOL_PATH/cyclonedx-cli.zip" "$BESMAN_CYCLONEDX_CLI_ASSET_URL" && unzip "$BESMAN_TOOL_PATH/cyclonedx-cli.zip" -d "$BESMAN_TOOL_PATH"
                ;;
            ScanCode-Toolkit)
                echo "Installing ScanCode Toolkit..."
                curl -L -o "$BESMAN_TOOL_PATH/scancode-toolkit.zip" "$BESMAN_SCANCODE_TOOLKIT_URL" && unzip "$BESMAN_TOOL_PATH/scancode-toolkit.zip" -d "$BESMAN_TOOL_PATH"
                ;;
            OpenSSF-Scorecard)
                echo "Installing OpenSSF Scorecard..."
                go get -u "$BESMAN_OPENSSF_SCORECARD_URL"
                ;;
            *)
                echo "Unknown tool: $tool"
                return 1
                ;;
        esac
    done
    echo "iptables environment installation completed."
}

__besman_uninstall() {
    echo "Uninstalling iptables environment..."
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        echo "Directory $BESMAN_ARTIFACT_DIR does not exist."
    fi

    echo "Uninstalling assessment tools..."
    docker stop sonarqube && docker rm sonarqube
    docker stop fossology && docker rm fossology

    echo "iptables environment uninstallation completed."
}

__besman_update() {
    echo "Updating iptables environment..."
    cd "$BESMAN_ARTIFACT_DIR" && git pull
    echo "iptables environment update completed."
}

__besman_reset() {
    echo "Resetting iptables environment..."
    __besman_uninstall
    __besman_install
    echo "iptables environment reset completed."
}

__besman_validate() {
    echo "Validating iptables environment..."
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "iptables source directory exists."
    else
        echo "iptables source directory does not exist."
        return 1
    fi
    echo "iptables environment validation completed."
}

# Execution logic based on command line argument
case "$1" in
    install)
        __besman_install
        ;;
    uninstall)
        __besman_uninstall
        ;;
    update)
        __besman_update
        ;;
    reset)
        __besman_reset
        ;;
    validate)
        __besman_validate
        ;;
    *)
        echo "Usage: $0 {install|uninstall|update|reset|validate}"
        exit 1
        ;;
esac