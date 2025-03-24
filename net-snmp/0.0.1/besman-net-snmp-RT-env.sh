#!/bin/bash

# Load configuration from the YAML file
#not needed while Uploading only for testing
BESMAN_ARTIFACT_URL=$(yq eval '.besman.BESMAN_ARTIFACT_URL' besman-net-snmp-RT-env-config.yaml)
BESMAN_ARTIFACT_VERSION=$(yq eval '.besman.BESMAN_ARTIFACT_VERSION' besman-net-snmp-RT-env-config.yaml)
BESMAN_SPDX_SBOM_ASSET_URL=$(yq eval '.besman.spdx_sbom_asset_url' besman-net-snmp-RT-env-config.yaml)
BESMAN_CODEQL_ASSET_URL=$(yq eval '.besman.codeql_asset_url' besman-net-snmp-RT-env-config.yaml)
BESMAN_DEPENDENCY_CHECK_ASSET_URL=$(yq eval '.besman.dependency_check_asset_url' besman-net-snmp-RT-env-config.yaml)
BESMAN_critical_score_url=$(yq eval '.besman.critical_score_url' besman-net-snmp-RT-env-config.yaml)

__besman_install() {
    # Write the code for environment installation here.
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "The clone path already contains a directory named $BESMAN_ARTIFACT_NAME."
    else
        echo "Cloning source code repo from $BESMAN_ARTIFACT_URL"
        git clone "$BESMAN_ARTIFACT_URL" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Install dependencies
    echo "Installing dependencies for net-snmp..."
    sudo apt-get update
    sudo apt-get install -y build-essential libtool autoconf libssl-dev libperl-dev

    # Install assessment tools
    echo "Installing assessment tools..."
    # Install SPDX SBOM Generator
    if ! command -v spdx-sbom-generator &>/dev/null; then
        echo "Installing spdx-sbom-generator..."
        curl -L -o /tmp/spdx-sbom-generator.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"
        tar -xzf /tmp/spdx-sbom-generator.tar.gz -C /usr/local/bin
        rm /tmp/spdx-sbom-generator.tar.gz
    fi

    # Install SonarQube
    if ! docker ps -a | grep -q sonarqube; then
        echo "Installing SonarQube..."
        docker run -d --name sonarqube -p 9000:9000 sonarqube
    fi

    # Install Criticality Score
    if ! command -v criticality_score &>/dev/null; then
        echo "Installing criticality_score..."
        go install "$BESMAN_critical_score_url"
    fi

    # Install Snyk
    if ! command -v snyk &>/dev/null; then
        echo "Installing Snyk..."
        npm install -g snyk
    fi

    # Install Fossology
    if ! docker ps -a | grep -q fossology; then
        echo "Installing Fossology..."
        docker run -d --name fossology -p 8081:80 fossology/fossology
    fi

    # Install CodeQL
    if ! command -v codeql &>/dev/null; then
        echo "Installing CodeQL..."
        curl -L -o /tmp/codeql.zip "$BESMAN_CODEQL_ASSET_URL"
        unzip /tmp/codeql.zip -d /opt/codeql
        rm /tmp/codeql.zip
        export PATH=$PATH:/opt/codeql/codeql
    fi

    # Install OWASP Dependency-Check
    if ! command -v dependency-check &>/dev/null; then
        echo "Installing OWASP Dependency-Check..."
        curl -L -o /tmp/dependency-check.zip "$BESMAN_DEPENDENCY_CHECK_ASSET_URL"
        unzip /tmp/dependency-check.zip -d /opt/dependency-check
        rm /tmp/dependency-check.zip
        export PATH=$PATH:/opt/dependency-check/bin
    fi

    # Install Syft
    if ! command -v syft &>/dev/null; then
        echo "Installing Syft..."
        curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
    fi

    # Install Trivy
    if ! command -v trivy &>/dev/null; then
        echo "Installing Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
}

__besman_uninstall() {
    # Write the code for environment uninstallation here.
    echo "Uninstalling net-snmp environment..."

    # Remove the artifact directory
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    fi

    # Uninstall assessment tools
    echo "Uninstalling assessment tools..."
    # Uninstall SPDX SBOM Generator
    if command -v spdx-sbom-generator &>/dev/null; then
        echo "Uninstalling spdx-sbom-generator..."
        rm -f /usr/local/bin/spdx-sbom-generator
    fi

    # Uninstall SonarQube
    if docker ps -a | grep -q sonarqube; then
        echo "Uninstalling SonarQube..."
        docker stop sonarqube
        docker rm sonarqube
    fi

    # Uninstall Criticality Score
    if command -v criticality_score &>/dev/null; then
        echo "Uninstalling criticality_score..."
        rm -f $(which criticality_score)
    fi

    # Uninstall Snyk
    if command -v snyk &>/dev/null; then
        echo "Uninstalling Snyk..."
        npm uninstall -g snyk
    fi

    # Uninstall Fossology
    if docker ps -a | grep -q fossology; then
        echo "Uninstalling Fossology..."
        docker stop fossology
        docker rm fossology
    fi

    # Uninstall CodeQL
    if command -v codeql &>/dev/null; then
        echo "Uninstalling CodeQL..."
        rm -rf /opt/codeql
    fi

    # Uninstall OWASP Dependency-Check
    if command -v dependency-check &>/dev/null; then
        echo "Uninstalling OWASP Dependency-Check..."
        rm -rf /opt/dependency-check
    fi

    # Uninstall Syft
    if command -v syft &>/dev/null; then
        echo "Uninstalling Syft..."
        rm -f /usr/local/bin/syft
    fi

    # Uninstall Trivy
    if command -v trivy &>/dev/null; then
        echo "Uninstalling Trivy..."
        rm -f /usr/local/bin/trivy
    fi
}

__besman_update() {
    # Write the code for environment updation here.
    echo "Updating net-snmp environment..."

    # Update the artifact directory
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "Updating $BESMAN_ARTIFACT_DIR..."
        cd "$BESMAN_ARTIFACT_DIR"
        git pull origin "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Update assessment tools
    echo "Updating assessment tools..."
    # Update SPDX SBOM Generator
    if command -v spdx-sbom-generator &>/dev/null; then
        echo "Updating spdx-sbom-generator..."
        curl -L -o /tmp/spdx-sbom-generator.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"
        tar -xzf /tmp/spdx-sbom-generator.tar.gz -C /usr/local/bin
        rm /tmp/spdx-sbom-generator.tar.gz
    fi

    # Update SonarQube
    if docker ps -a | grep -q sonarqube; then
        echo "Updating SonarQube..."
        docker stop sonarqube
        docker rm sonarqube
        docker run -d --name sonarqube -p 9000:9000 sonarqube
    fi

    # Update Criticality Score
    if command -v criticality_score &>/dev/null; then
        echo "Updating criticality_score..."
        go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
    fi

    # Update Snyk
    if command -v snyk &>/dev/null; then
        echo "Updating Snyk..."
        npm install -g snyk@latest
    fi

    # Update Fossology
    if docker ps -a | grep -q fossology; then
        echo "Updating Fossology..."
        docker stop fossology
        docker rm fossology
        docker run -d --name fossology -p 8081:80 fossology/fossology
    fi

    # Update CodeQL
    if command -v codeql &>/dev/null; then
        echo "Updating CodeQL..."
        curl -L -o /tmp/codeql.zip "$BESMAN_CODEQL_ASSET_URL"
        unzip /tmp/codeql.zip -d /opt/codeql
        rm /tmp/codeql.zip
    fi

    # Update OWASP Dependency-Check
    if command -v dependency-check &>/dev/null; then
        echo "Updating OWASP Dependency-Check..."
        curl -L -o /tmp/dependency-check.zip "$BESMAN_DEPENDENCY_CHECK_ASSET_URL"
        unzip /tmp/dependency-check.zip -d /opt/dependency-check
        rm /tmp/dependency-check.zip
    fi

    # Update Syft
    if command -v syft &>/dev/null; then
        echo "Updating Syft..."
        curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
    fi

    # Update Trivy
    if command -v trivy &>/dev/null; then
        echo "Updating Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
}

__besman_reset() {
    # Write the code for environment resetting here.
    echo "Resetting net-snmp environment..."

    # Reset the artifact directory
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "Resetting $BESMAN_ARTIFACT_DIR..."
        cd "$BESMAN_ARTIFACT_DIR"
        git reset --hard
        git clean -fd
        cd "$HOME"
    fi

    # Reset assessment tools
    echo "Resetting assessment tools..."
    # Reset SPDX SBOM Generator
    if command -v spdx-sbom-generator &>/dev/null; then
        echo "Resetting spdx-sbom-generator..."
        curl -L -o /tmp/spdx-sbom-generator.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"
        tar -xzf /tmp/spdx-sbom-generator.tar.gz -C /usr/local/bin
        rm /tmp/spdx-sbom-generator.tar.gz
    fi

    # Reset SonarQube
    if docker ps -a | grep -q sonarqube; then
        echo "Resetting SonarQube..."
        docker stop sonarqube
        docker rm sonarqube
        docker run -d --name sonarqube -p 9000:9000 sonarqube
    fi

    # Reset Criticality Score
    if command -v criticality_score &>/dev/null; then
        echo "Resetting criticality_score..."
        go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
    fi

    # Reset Snyk
    if command -v snyk &>/dev/null; then
        echo "Resetting Snyk..."
        npm install -g snyk@latest
    fi

    # Reset Fossology
    if docker ps -a | grep -q fossology; then
        echo "Resetting Fossology..."
        docker stop fossology
        docker rm fossology
        docker run -d --name fossology -p 8081:80 fossology/fossology
    fi

    # Reset CodeQL
    if command -v codeql &>/dev/null; then
        echo "Resetting CodeQL..."
        curl -L -o /tmp/codeql.zip "$BESMAN_CODEQL_ASSET_URL"
        unzip /tmp/codeql.zip -d /opt/codeql
        rm /tmp/codeql.zip
    fi

    # Reset OWASP Dependency-Check
    if command -v dependency-check &>/dev/null; then
        echo "Resetting OWASP Dependency-Check..."
        curl -L -o /tmp/dependency-check.zip "$BESMAN_DEPENDENCY_CHECK_ASSET_URL"
        unzip /tmp/dependency-check.zip -d /opt/dependency-check
        rm /tmp/dependency-check.zip
    fi

    # Reset Syft
    if command -v syft &>/dev/null; then
        echo "Resetting Syft..."
        curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin
    fi

    # Reset Trivy
    if command -v trivy &>/dev/null; then
        echo "Resetting Trivy..."
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    fi
}

__besman_validate() {
    # Write the code for environment validation here.
    echo "Validating net-snmp environment..."

    validationStatus=1
    declare -a errors

    # Validate artifact directory
    if [[ ! -d $BESMAN_ARTIFACT_DIR ]]; then
        echo "Artifact directory $BESMAN_ARTIFACT_DIR does not exist."
        validationStatus=0
        errors+=("Artifact directory")
    fi

    # Validate assessment tools
    # Validate SPDX SBOM Generator
    if ! command -v spdx-sbom-generator &>/dev/null; then
        echo "SPDX SBOM Generator is not installed."
        validationStatus=0
        errors+=("SPDX SBOM Generator")
    fi

    # Validate SonarQube
    if ! docker ps -a | grep -q sonarqube; then
        echo "SonarQube is not installed."
        validationStatus=0
        errors+=("SonarQube")
    fi

    # Validate Criticality Score
    if ! command -v criticality_score &>/dev/null; then
        echo "Criticality Score is not installed."
        validationStatus=0
        errors+=("Criticality Score")
    fi

    # Validate Snyk
    if ! command -v snyk &>/dev/null; then
        echo "Snyk is not installed."
        validationStatus=0
        errors+=("Snyk")
    fi

    # Validate Fossology
    if ! docker ps -a | grep -q fossology; then
        echo "Fossology is not installed."
        validationStatus=0
        errors+=("Fossology")
    fi

    # Validate CodeQL
    if ! command -v codeql &>/dev/null; then
        echo "CodeQL is not installed."
        validationStatus=0
        errors+=("CodeQL")
    fi

    # Validate OWASP Dependency-Check
    if ! command -v dependency-check &>/dev/null; then
        echo "OWASP Dependency-Check is not installed."
        validationStatus=0
        errors+=("OWASP Dependency-Check")
    fi

    # Validate Syft
    if ! command -v syft &>/dev/null; then
        echo "Syft is not installed."
        validationStatus=0
        errors+=("Syft")
    fi

    # Validate Trivy
    if ! command -v trivy &>/dev/null; then
        echo "Trivy is not installed."
        validationStatus=0
        errors+=("Trivy")
    fi

    if [[ $validationStatus -eq 1 ]]; then
        echo "Validation successful."
    else
        echo "Validation failed with errors: ${errors[@]}"
    fi
}
