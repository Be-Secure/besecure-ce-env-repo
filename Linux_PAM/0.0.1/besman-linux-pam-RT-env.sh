#!/bin/bash

__besman_install() {
    echo "Installing Linux PAM environment..."

    # Clone the Linux PAM repository if it doesn't already exist
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "Directory $BESMAN_ARTIFACT_DIR already exists. Skipping clone."
    else
        echo "Cloning Linux PAM repository from $BESMAN_ARTIFACT_URL..."
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

    # Install dependencies for Linux PAM
    echo "Installing dependencies for Linux PAM..."
    sudo apt update && sudo apt install -y build-essential libtool autoconf automake flex bison libaudit-dev libselinux1-dev libpam0g-dev || {
        echo "Failed to install dependencies."
        return 1
    }

    # Install assessment tools
    echo "Installing assessment tools..."
    for tool in $(echo "$BESMAN_ASSESSMENT_TOOLS" | tr ',' ' '); do
        case "$tool" in
            spdx-sbom-generator)
                echo "Installing spdx-sbom-generator..."
                curl -L -o "$BESMAN_TOOL_PATH/spdx-sbom-generator.tar.gz" "$BESMAN_SPDX_SBOM_ASSET_URL" || {
                    echo "Failed to download spdx-sbom-generator."
                    return 1
                }
                tar -xzf "$BESMAN_TOOL_PATH/spdx-sbom-generator.tar.gz" -C "$BESMAN_TOOL_PATH" || {
                    echo "Failed to extract spdx-sbom-generator."
                    return 1
                }
                ;;
            sonarqube)
                echo "Installing SonarQube..."
                docker pull sonarqube || {
                    echo "Failed to pull SonarQube Docker image."
                    return 1
                }
                docker run -d --name sonarqube -p 9000:9000 sonarqube || {
                    echo "Failed to start SonarQube container."
                    return 1
                }
                ;;
            criticality_score)
                echo "Installing criticality_score..."
                go install github.com/ossf/criticality_score@latest || {
                    echo "Failed to install criticality_score."
                    return 1
                }
                ;;
            snyk)
                echo "Installing Snyk..."
                curl -s https://static.snyk.io/cli/latest/snyk-linux -o "$BESMAN_TOOL_PATH/snyk" || {
                    echo "Failed to download Snyk."
                    return 1
                }
                chmod +x "$BESMAN_TOOL_PATH/snyk" || {
                    echo "Failed to make Snyk executable."
                    return 1
                }
                ;;
            fossology)
                echo "Installing Fossology..."
                docker pull fossology/fossology || {
                    echo "Failed to pull Fossology Docker image."
                    return 1
                }
                docker run -d --name fossology -p 8081:80 fossology/fossology || {
                    echo "Failed to start Fossology container."
                    return 1
                }
                ;;
            CodeQL)
                echo "Installing CodeQL..."
                curl -L -o "$BESMAN_TOOL_PATH/codeql.zip" "$BESMAN_CODEQL_ASSET_URL" || {
                    echo "Failed to download CodeQL."
                    return 1
                }
                unzip "$BESMAN_TOOL_PATH/codeql.zip" -d "$BESMAN_TOOL_PATH" || {
                    echo "Failed to extract CodeQL."
                    return 1
                }
                ;;
            OWASP-Dependency-Check)
                echo "Installing OWASP Dependency-Check..."
                curl -L -o "$BESMAN_TOOL_PATH/dependency-check.zip" "$BESMAN_DEPENDENCY_CHECK_ASSET_URL" || {
                    echo "Failed to download OWASP Dependency-Check."
                    return 1
                }
                unzip "$BESMAN_TOOL_PATH/dependency-check.zip" -d "$BESMAN_TOOL_PATH" || {
                    echo "Failed to extract OWASP Dependency-Check."
                    return 1
                }
                ;;
            Syft)
                echo "Installing Syft..."
                curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b "$BESMAN_TOOL_PATH" || {
                    echo "Failed to install Syft."
                    return 1
                }
                ;;
            Trivy)
                echo "Installing Trivy..."
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b "$BESMAN_TOOL_PATH" || {
                    echo "Failed to install Trivy."
                    return 1
                }
                ;;
            CycloneDX-CLI)
                echo "Installing CycloneDX CLI..."
                curl -L -o "$BESMAN_TOOL_PATH/cyclonedx-cli.zip" "$BESMAN_CYCLONEDX_CLI_ASSET_URL" || {
                    echo "Failed to download CycloneDX CLI."
                    return 1
                }
                unzip "$BESMAN_TOOL_PATH/cyclonedx-cli.zip" -d "$BESMAN_TOOL_PATH" || {
                    echo "Failed to extract CycloneDX CLI."
                    return 1
                }
                ;;
            ScanCode-Toolkit)
                echo "Installing ScanCode Toolkit..."
                curl -L -o "$BESMAN_TOOL_PATH/scancode-toolkit.tar.gz" "$BESMAN_SCANCODE_ASSET_URL" || {
                    echo "Failed to download ScanCode Toolkit."
                    return 1
                }
                tar -xzf "$BESMAN_TOOL_PATH/scancode-toolkit.tar.gz" -C "$BESMAN_TOOL_PATH" || {
                    echo "Failed to extract ScanCode Toolkit."
                    return 1
                }
                ;;
            OpenSSF-Scorecard)
                echo "Installing OpenSSF Scorecard..."
                go install github.com/ossf/scorecard/v4@latest || {
                    echo "Failed to install OpenSSF Scorecard."
                    return 1
                }
                ;;
            *)
                echo "Unknown tool: $tool"
                return 1
                ;;
        esac
    done

    echo "Linux PAM environment installation completed."
}

__besman_uninstall() {
    echo "Uninstalling Linux PAM environment..."

    # Remove the cloned repository
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        echo "Directory $BESMAN_ARTIFACT_DIR does not exist."
    fi

    # Uninstall assessment tools
    echo "Uninstalling assessment tools..."
    for tool in $(echo "$BESMAN_ASSESSMENT_TOOLS" | tr ',' ' '); do
        case "$tool" in
            sonarqube)
                echo "Stopping and removing SonarQube container..."
                docker stop sonarqube && docker rm sonarqube || {
                    echo "Failed to remove SonarQube container."
                }
                ;;
            fossology)
                echo "Stopping and removing Fossology container..."
                docker stop fossology && docker rm fossology || {
                    echo "Failed to remove Fossology container."
                }
                ;;
            *)
                echo "No specific uninstallation steps for $tool."
                ;;
        esac
    done

    echo "Linux PAM environment uninstallation completed."
}

__besman_update() {
    echo "Updating Linux PAM environment..."

    # Update the cloned repository
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "Updating Linux PAM repository..."
        cd "$BESMAN_ARTIFACT_DIR" && git pull origin "$BESMAN_ARTIFACT_VERSION" || {
            echo "Failed to update repository."
            return 1
        }
        cd "$HOME"
    else
        echo "Directory $BESMAN_ARTIFACT_DIR does not exist."
    fi

    echo "Linux PAM environment update completed."
}

__besman_reset() {
    echo "Resetting Linux PAM environment..."

    # Reset the environment by uninstalling and reinstalling
    __besman_uninstall
    __besman_install

    echo "Linux PAM environment reset completed."
}

__besman_validate() {
    echo "Validating Linux PAM environment..."

    # Validate the cloned repository
    if [[ -d "$BESMAN_ARTIFACT_DIR" ]]; then
        echo "Repository $BESMAN_ARTIFACT_DIR exists."
    else
        echo "Repository $BESMAN_ARTIFACT_DIR does not exist."
        return 1
    fi

    # Validate assessment tools
    for tool in $(echo "$BESMAN_ASSESSMENT_TOOLS" | tr ',' ' '); do
        case "$tool" in
            sonarqube)
                if docker ps | grep -q sonarqube; then
                    echo "SonarQube container is running."
                else
                    echo "SonarQube container is not running."
                    return 1
                fi
                ;;
            fossology)
                if docker ps | grep -q fossology; then
                    echo "Fossology container is running."
                else
                    echo "Fossology container is not running."
                    return 1
                fi
                ;;
            *)
                echo "No specific validation steps for $tool."
                ;;
        esac
    done

    echo "Linux PAM environment validation completed."
}

# Execution details
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