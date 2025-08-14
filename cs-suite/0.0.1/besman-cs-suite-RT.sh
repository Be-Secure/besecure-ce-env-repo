function __besman_install {
    # Install dependencies of Cloud Security Suite (CS-Suite)
    echo "Installing dependencies of Cloud Security Suite (CS-Suite)..."
    if ! command -v git &>/dev/null; then
        if sudo apt update; then
            :
        else
            echo "Error: Failed to update package list"
        fi
        if sudo apt install -y git; then
            :
        else
            echo "Error: Failed to install Git"
        fi
    fi
    if ! command -v curl &>/dev/null; then
        if sudo apt install -y curl; then
            :
        else
            echo "Error: Failed to install Curl"
        fi
    fi
    if ! command -v unzip &>/dev/null; then
        if sudo apt install -y unzip; then
            :
        else
            echo "Error: Failed to install Unzip"
        fi
    fi
    if ! command -v zip &>/dev/null; then
        if sudo apt install -y zip; then
            :
        else
            echo "Error: Failed to install Zip"
        fi
    fi
    if ! command -v jq &>/dev/null; then
        if sudo apt install -y jq; then
            :
        else
            echo "Error: Failed to install JQ"
        fi
    fi

    # Install Docker
    echo "Installing Docker..."
    if ! command -v docker &>/dev/null; then
        if sudo apt install -y ca-certificates curl software-properties-common; then
            :
        else
            echo "Error: Failed to install Docker dependencies"
        fi
        if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; then
            :
        else
            echo "Error: Failed to add Docker GPG key"
        fi
        if sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"; then
            :
        else
            echo "Error: Failed to add Docker repository"
        fi
        if sudo apt update; then
            :
        else
            echo "Error: Failed to update package list"
        fi
        if sudo apt install -y docker-ce docker-ce-cli containerd.io; then
            :
        else
            echo "Error: Failed to install Docker"
        fi
        if sudo usermod -aG docker $USER; then
            :
        else
            echo "Error: Failed to add user to Docker group"
        fi
        if sudo systemctl restart docker; then
            :
        else
            echo "Error: Failed to restart Docker service"
        fi
    fi

    # Install Snap
    echo "Installing Snap..."
    if ! command -v snap &>/dev/null; then
        if sudo apt install -y snapd; then
            :
        else
            echo "Error: Failed to install Snap"
        fi
    fi

    # Install Go
    echo "Installing Go..."
    if ! command -v go &>/dev/null; then
        if sudo snap install go --classic; then
            :
        else
            echo "Error: Failed to install Go"
        fi
        export GOPATH=/usr/local
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    fi

    # Install SonarQube
    echo "Installing SonarQube..."
    if [ "$(docker ps -aq -f name=sonarqube)" ]; then
        :
    else
        if docker create --name sonarqube -p 9000:9000 sonarqube; then
            :
        else
            echo "Error: Failed to create SonarQube container"
        fi
        if docker start sonarqube; then
            :
        else
            echo "Error: Failed to start SonarQube container"
        fi
    fi

    # Install spdx-sbom-generator
    echo "Installing spdx-sbom-generator..."
    if ! command -v spdx-sbom-generator &>/dev/null; then
        if curl -L -o spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz https://github.com/spdx/spdx-sbom-generator/releases/download/v0.0.15/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz; then
            :
        else
            echo "Error: Failed to download spdx-sbom-generator"
        fi
        if tar -xzf spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz; then
            :
        else
            echo "Error: Failed to extract spdx-sbom-generator"
        fi
        if sudo mv spdx-sbom-generator /usr/local/bin/; then
            :
        else
            echo "Error: Failed to move spdx-sbom-generator to /usr/local/bin/"
        fi
        if sudo chmod +x /usr/local/bin/spdx-sbom-generator; then
            :
        else
            echo "Error: Failed to make spdx-sbom-generator executable"
        fi
    fi

    # Install Critically_Score
    echo "Installing Critically_Score..."
    if ! command -v criticality_score &>/dev/null; then
        if go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest; then
            :
        else
            echo "Error: Failed to install Critically_Score"
        fi
    fi

    # Install Fossology
    echo "Installing Fossology..."
    if [ "$(docker ps -aq -f name=fossology)" ]; then
        :
    else
        if docker create --name fossology -p 8081:80 fossology/fossology; then
            :
        else
            echo "Error: Failed to create Fossology container"
        fi
        if docker start fossology; then
            :
        else
            echo "Error: Failed to start Fossology container"
        fi
    fi

    # Clone the Cloud Security Suite (CS-Suite) repository
    echo "Cloning the Cloud Security Suite CS-Suite repository..."
    if [ -d "cs-suite" ]; then
        :
    else
        if git clone https://github.com/cloud-security-suite/cs-suite.git; then
            :
        else
            echo "Error: Failed to clone cs-suite repository"
        fi
    fi
}

function __besman_uninstall {
    # Uninstall tools and dependencies
    echo "Uninstalling tools and dependencies..."

    # Uninstall Docker
    echo "Uninstalling Docker..."
    if command -v docker &>/dev/null; then
        if sudo apt purge -y docker-ce docker-ce-cli containerd.io; then
            :
        else
            echo "Error: Failed to uninstall Docker"
        fi
        if sudo rm -rf /var/lib/docker; then
            :
        else
            echo "Error: Failed to remove Docker data directory"
        fi
        if sudo rm -rf /var/lib/containerd; then
            :
        else
            echo "Error: Failed to remove Containerd data directory"
        fi
        if sudo deluser $USER docker; then
            :
        else
            echo "Error: Failed to remove user from Docker group"
        fi
        if sudo groupdel docker; then
            :
        else
            echo "Error: Failed to remove Docker group"
        fi
    fi

    # Uninstall Snap
    echo "Uninstalling Snap..."
    if command -v snap &>/dev/null; then
        if sudo apt purge -y snapd; then
            :
        else
            echo "Error: Failed to uninstall Snap"
        fi
    fi

    # Uninstall Go
    echo "Uninstalling Go..."
    if command -v go &>/dev/null; then
        if sudo snap remove go -y; then
            :
        else
            echo "Error: Failed to uninstall Go"
        fi
    fi

    # Uninstall SonarQube
    echo "Uninstalling SonarQube..."
    if [ "$(docker ps -aq -f name=sonarqube)" ]; then
        if docker stop sonarqube; then
            :
        else
            echo "Error: Failed to stop SonarQube container"
        fi
        if docker container rm --force sonarqube; then
            :
        else
            echo "Error: Failed to remove SonarQube container"
        fi
    fi

    # Uninstall spdx-sbom-generator
    echo "Uninstalling spdx-sbom-generator..."
    if command -v spdx-sbom-generator &>/dev/null; then
        if sudo rm -f /usr/local/bin/spdx-sbom-generator; then
            :
        else
            echo "Error: Failed to remove spdx-sbom-generator"
        fi
    fi

    # Uninstall Critically_Score
    echo "Uninstalling Critically_Score..."
    if command -v criticality_score &>/dev/null; then
        if go install github.com/ossf/criticality_score/v2/cmd/criticality_score@none; then
            :
        else
            echo "Error: Failed to uninstall Critically_Score"
        fi
    fi

    # Uninstall Fossology
    echo "Uninstalling Fossology..."
    if [ "$(docker ps -aq -f name=fossology)" ]; then
        if docker stop fossology; then
            :
        else
            echo "Error: Failed to stop Fossology container"
        fi
        if docker container rm --force fossology; then
            :
        else
            echo "Error: Failed to remove Fossology container"
        fi
    fi

    # Remove the cs-suite directory
    echo "Removing the cs-suite directory..."
    if [ -d "cs-suite" ]; then
        if rm -rf cs-suite; then
            :
        else
            echo "Error: Failed to remove cs-suite directory"
        fi
    fi
}

function __besman_update {
    # Update tools and dependencies
    echo "Updating tools and dependencies..."

    # Update Docker
    echo "Updating Docker..."
    if command -v docker &>/dev/null; then
        if sudo apt update; then
            :
        else
            echo "Error: Failed to update package list"
        fi
        if sudo apt install -y docker-ce docker-ce-cli containerd.io; then
            :
        else
            echo "Error: Failed to update Docker"
        fi
    fi

    # Update Snap
    echo "Updating Snap..."
    if command -v snap &>/dev/null; then
        if sudo snap refresh; then
            :
        else
            echo "Error: Failed to update Snap"
        fi
    fi

    # Update Go
    echo "Updating Go..."
    if command -v go &>/dev/null; then
        if sudo snap refresh go; then
            :
        else
            echo "Error: Failed to update Go"
        fi
    fi

    # Update SonarQube
    echo "Updating SonarQube..."
    if [ "$(docker ps -aq -f name=sonarqube)" ]; then
        if docker stop sonarqube; then
            :
        else
            echo "Error: Failed to stop SonarQube container"
        fi
        if docker container rm --force sonarqube; then
            :
        else
            echo "Error: Failed to remove SonarQube container"
        fi
    fi
    if docker create --name sonarqube -p 9000:9000 sonarqube; then
        :
    else
        echo "Error: Failed to create SonarQube container"
    fi
    if docker start sonarqube; then
        :
    else
        echo "Error: Failed to start SonarQube container"
    fi

    # Update spdx-sbom-generator
    echo "Updating spdx-sbom-generator..."
    if command -v spdx-sbom-generator &>/dev/null; then
        if curl -L -o spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz https://github.com/spdx/spdx-sbom-generator/releases/download/v0.0.15/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz; then
            :
        else
            echo "Error: Failed to download spdx-sbom-generator"
        fi
        if tar -xzf spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz; then
            :
        else
            echo "Error: Failed to extract spdx-sbom-generator"
        fi
        if sudo mv spdx-sbom-generator /usr/local/bin/; then
            :
        else
            echo "Error: Failed to move spdx-sbom-generator to /usr/local/bin/"
        fi
        if sudo chmod +x /usr/local/bin/spdx-sbom-generator; then
            :
        else
            echo "Error: Failed to make spdx-sbom-generator executable"
        fi
    fi

    # Update Critically_Score
    echo "Updating Critically_Score..."
    if command -v criticality_score &>/dev/null; then
        if go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest; then
            :
        else
            echo "Error: Failed to update Critically_Score"
        fi
    else
        if go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest; then
            :
        else
            echo "Error: Failed to install Critically_Score"
        fi
    fi

    # Update Fossology
    echo "Updating Fossology..."
    if [ "$(docker ps -aq -f name=fossology)" ]; then
        if docker stop fossology; then
            :
        else
            echo "Error: Failed to stop Fossology container"
        fi
        if docker container rm --force fossology; then
            :
        else
            echo "Error: Failed to remove Fossology container"
        fi
    fi
    if docker create --name fossology -p 8081:80 fossology/fossology; then
        :
    else
        echo "Error: Failed to create Fossology container"
    fi
    if docker start fossology; then
        :
    else
        echo "Error: Failed to start Fossology container"
    fi

    # Update cs-suite
    echo "Updating cs-suite..."
    if [ -d "cs-suite" ]; then
        if cd cs-suite; then
            :
        else
            echo "Error: Failed to change directory to cs-suite"
        fi
        if git pull; then
            :
        else
            echo "Error: Failed to pull latest changes from cs-suite repository"
        fi
        if cd..; then
            :
        else
            echo "Error: Failed to change directory to parent directory"
        fi
    else
        if git clone https://github.com/cloud-security-suite/cs-suite.git; then
            :
        else
            echo "Error: Failed to clone cs-suite repository"
        fi
    fi
}

function __besman_validate {
    # Validate the installation of tools and dependencies
    echo "Validating the installation of tools and dependencies..."

    # Check if Docker is installed
    if command -v docker &>/dev/null; then
        echo "Docker is installed."
    else
        echo "Docker is not installed."
    fi

    # Check if Snap is installed
    if command -v snap &>/dev/null; then
        echo "Snap is installed."
    else
        echo "Snap is not installed."
    fi

    # Check if Go is installed
    if command -v go &>/dev/null; then
        echo "Go is installed."
    else
        echo "Go is not installed."
    fi

    # Check if SonarQube is installed
    if [ "$(docker ps -aq -f name=sonarqube)" ]; then
        echo "SonarQube is installed."
    else
        echo "SonarQube is not installed."
    fi

    # Check if spdx-sbom-generator is installed
    if command -v spdx-sbom-generator &>/dev/null; then
        echo "spdx-sbom-generator is installed."
    else
        echo "spdx-sbom-generator is not installed."
    fi

    # Check if Critically_Score is installed
    if command -v criticality_score &>/dev/null; then
        echo "Critically_Score is installed."
    else
        echo "Critically_Score is not installed."
    fi

    # Check if Fossology is installed
    if [ "$(docker ps -aq -f name=fossology)" ]; then
        echo "Fossology is installed."
    else
        echo "Fossology is not installed."
    fi
}

function __besman_reset {
    # Reset tools and dependencies to their default configurations
    echo "Resetting tools and dependencies to their default configurations..."

    # Reset Docker
    echo "Resetting Docker..."
    if command -v docker &>/dev/null; then
        if sudo systemctl restart docker; then
            :
        else
            echo "Error: Failed to restart Docker service"
        fi
    fi

    # Reset Snap
    echo "Resetting Snap..."
    if command -v snap &>/dev/null; then
        if sudo snap refresh; then
            :
        else
            echo "Error: Failed to update Snap"
        fi
    fi

    # Reset Go
    echo "Resetting Go..."
    if command -v go &>/dev/null; then
        if go env -w GOPATH=$HOME/go; then
            :
        else
            echo "Error: Failed to set GOPATH"
        fi
        if go env -w GOROOT=/usr/local/go; then
            :
        else
            echo "Error: Failed to set GOROOT"
        fi
    fi

    # Reset SonarQube
    echo "Resetting SonarQube..."
    if [ "$(docker ps -aq -f name=sonarqube)" ]; then
        if docker stop sonarqube; then
            : 
        else
            echo "Error: Failed to stop SonarQube container"
        fi
        if docker container rm --force sonarqube; then
            :
        else
            echo "Error: Failed to remove SonarQube container"
        fi
    fi
    if docker create --name sonarqube -p 9000:9000 sonarqube; then
        : 
    else
        echo "Error: Failed to create SonarQube container"
    fi
    if docker start sonarqube; then
        :
    else
        echo "Error: Failed to start SonarQube container"
    fi

    # Reset spdx-sbom-generator
    echo "Resetting spdx-sbom-generator..."
    if command -v spdx-sbom-generator &>/dev/null; then
        if curl -L -o spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz https://github.com/spdx/spdx-sbom-generator/releases/download/v0.0.15/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz; then
            :
        else
            echo "Error: Failed to download spdx-sbom-generator"
        fi
        if tar -xzf spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz; then
            :
        else
            echo "Error: Failed to extract spdx-sbom-generator"
        fi
        if sudo mv spdx-sbom-generator /usr/local/bin/; then
            :
        else
            echo "Error: Failed to move spdx-sbom-generator to /usr/local/bin/"
        fi
        if sudo chmod +x /usr/local/bin/spdx-sbom-generator; then
            :
        else
            echo "Error: Failed to make spdx-sbom-generator executable"
        fi
    fi

    # Reset Critically_Score
    echo "Resetting Critically_Score..."
    if command -v criticality_score &>/dev/null; then
        if go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest; then
            :
        else
            echo "Error: Failed to update Critically_Score"
        fi
    else
        if go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest; then
            :
        else
            echo "Error: Failed to install Critically_Score"
        fi
    fi

    # Reset Fossology
    echo "Resetting Fossology..."
    if [ "$(docker ps -aq -f name=fossology)" ]; then
        if docker stop fossology; then
            :
        else
            echo "Error: Failed to stop Fossology container"
        fi
        if docker container rm --force fossology; then
            :
        else
            echo "Error: Failed to remove Fossology container"
        fi
    fi
    if docker create --name fossology -p 8081:80 fossology/fossology; then
        :
    else
        echo "Error: Failed to create Fossology container"
    fi
    if docker start fossology; then
        :
    else
        echo "Error: Failed to start Fossology container"
    fi
}

# Call the functions based on the command-line arguments
case $1 in
    install)
        __besman_install
        ;;
    uninstall)
        __besman_uninstall
        ;;
    update)
        __besman_update
        ;;
    validate)
        __besman_validate
        ;;
    reset)
        __besman_reset
        ;;
    *)
        echo "Usage: install uninstall update validate reset"
        ;;
esac
