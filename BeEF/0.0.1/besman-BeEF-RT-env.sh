#!/bin/bash

# # Load configuration from YAML file
# CONFIG_FILE="config.yaml"
# if [! -f "$CONFIG_FILE" ]; then
#   echo "Error: Configuration file not found"
#   exit 1
# fi

# # Load YAML configuration
# TOOLS=$(yq e '.tools[] |.name' "$CONFIG_FILE")
# REPOSITORIES=$(yq e '.tools[] |.repository' "$CONFIG_FILE")
# DEPENDENCIES=$(yq e '.dependencies[]' "$CONFIG_FILE")

function __besman_install() {
  # Install dependencies
  echo "Installing dependencies..."
  for dependency in $DEPENDENCIES; do
    case $dependency in
      git)
        sudo apt-get update && sudo apt-get install -y git
        ;;
      python3)
        sudo apt-get update && sudo apt-get install -y python3
        ;;
      pip)
        sudo apt-get update && sudo apt-get install -y python3-pip
        ;;
      java)
        sudo apt-get update && sudo apt-get install -y default-jre
        ;;
      maven)
        sudo apt-get update && sudo apt-get install -y maven
        ;;
      beef)
        sudo apt-get update && sudo apt-get install -y beef
        ;;
      golang)
        sudo apt-get update && sudo apt-get install -y golang-go
        ;;
      nodejs)
        sudo apt-get update && sudo apt-get install -y nodejs
        ;;
      npm)
        sudo apt-get update && sudo apt-get install -y npm
        ;;
    esac
  done

  # Clone repositories
  echo "Cloning repositories..."
  for repository in $REPOSITORIES; do
    git clone "$repository"
  done

  # Install tools
  echo "Installing tools..."
  for tool in $TOOLS; do
    case $tool in
      Semgrep)
        cd semgrep && pip3 install.
        ;;
      CodeQL)
        cd codeql && mvn compile
        ;;
      Bandit)
        cd bandit && pip3 install.
        ;;
      FindSecBugs)
        cd find-sec-bugs && mvn package
        ;;
      OWASP)
        cd owasp-maven-plugin && mvn install
        ;;
      Syft)
        cd syft && go build.
        ;;
      Grype)
        cd grype && go build.
        ;;
      Trivy)
        cd trivy && go build.
        ;;
      CycloneDX CLI)
        cd cyclonedx-cli && npm install
        ;;
      ScanCode ToolKit)
        cd scancode-toolkit && pip3 install.
        ;;
      SPDX tool)
        cd tools && mvn compile
        ;;
    esac
  done
}

function __besman_uninstall() {
  # Uninstall dependencies
  echo "Uninstalling dependencies..."
  for dependency in $DEPENDENCIES; do
    case $dependency in
      git)
        sudo apt-get purge -y git
        ;;
      python3)
        sudo apt-get purge -y python3
        ;;
      pip)
        sudo apt-get purge -y python3-pip
        ;;
      java)
        sudo apt-get purge -y default-jre
        ;;
      maven)
        sudo apt-get purge -y maven
        ;;  
      beef)
        sudo apt-get purge -y beef
        ;;
      golang)
        sudo apt-get purge -y golang-go
        ;;
      nodejs)
        sudo apt-get purge -y nodejs
        ;;
      npm)
        sudo apt-get purge -y npm
        ;;
    esac
  done

  # Remove cloned repositories
  echo "Removing cloned repositories..."
  for repository in $REPOSITORIES; do
    repo_name=$(basename "$repository".git)
    rm -rf "$repo_name"
  done
}

function __besman_validate() {
  # Check if dependencies are installed
  echo "Validating dependencies..."
  for dependency in $DEPENDENCIES; do
    case $dependency in
      git)
        if! command -v git &> /dev/null; then
          echo "Git is not installed"
          return 1
        fi
        ;;
      python3)
        if! command -v python3 &> /dev/null; then
          echo "Python 3 is not installed"
          return 1
        fi
        ;;
      pip)
        if! command -v pip3 &> /dev/null; then
          echo "Pip is not installed"
          return 1
        fi
        ;;
      java)
        if! command -v java &> /dev/null; then
          echo "Java is not installed"
          return 1
        fi
        ;;
      maven)
        if! command -v mvn &> /dev/null; then
          echo "Maven is not installed"
          return 1
        fi
        ;;
      beef)
        if! command -v beef &> /dev/null; then
          echo "BeEF is not installed"
          return 1
        fi
        ;;
      golang)
        if! command -v go &> /dev/null; then
          echo "Go is not installed"
          return 1
        fi
        ;;
      nodejs)
        if! command -v node &> /dev/null; then
          echo "Node.js is not installed"
          return 1
        fi
        ;;
      npm)
        if! command -v npm &> /dev/null; then
          echo "npm is not installed"
          return 1
        fi
        ;;
    esac
  done

  # Check if tools are installed
  echo "Validating tools..."
  for tool in $TOOLS; do
    case $tool in
      Semgrep)
        if! command -v semgrep &> /dev/null; then
          echo "Semgrep is not installed"
          return 1
        fi
        ;;
      CodeQL)
        if! command -v codeql &> /dev/null; then
          echo "CodeQL is not installed"
          return 1
        fi
        ;;
      Bandit)
        if! command -v bandit &> /dev/null; then
          echo "Bandit is not installed"
          return 1
        fi
        ;;
      FindSecBugs)
        if! command -v findsecbugs &> /dev/null; then
          echo "FindSecBugs is not installed"
          return 1
        fi
        ;;
      OWASP)
        if! command -v owasp &> /dev/null; then
          echo "OWASP is not installed"
          return 1
        fi
        ;;
      Syft)
        if! command -v syft &> /dev/null; then
          echo "Syft is not installed"
          return 1
        fi
        ;;
      Grype)
        if! command -v grype &> /dev/null; then
          echo "Grype is not installed"
          return 1
        fi
        ;;
      Trivy)
        if! command -v trivy &> /dev/null; then
          echo "Trivy is not installed"
          return 1
        fi
        ;;
      CycloneDX CLI)
        if! command -v cyclonedx &> /dev/null; then
          echo "CycloneDX CLI is not installed"
          return 1
        fi
        ;;
      ScanCode ToolKit)
        if! command -v scancode &> /dev/null; then
          echo "ScanCode ToolKit is not installed"
          return 1
        fi
        ;;
      SPDX tool)
        if! command -v spdx &> /dev/null; then
          echo "SPDX tool is not installed"
          return 1
        fi
        ;;
    esac
  done
}

function __besman_update() {
  # Update dependencies
  echo "Updating dependencies..."
  for dependency in $DEPENDENCIES; do
    case $dependency in
      git)
        sudo apt-get update && sudo apt-get install -y git
        ;;
      python3)
        sudo apt-get update && sudo apt-get install -y python3
        ;;
      pip)
        sudo apt-get update && sudo apt-get install -y python3-pip
        ;;
      java)
        sudo apt-get update && sudo apt-get install -y default-jre
        ;;
      maven)
        sudo apt-get update && sudo apt-get install -y maven
        ;;
      beef)
        sudo apt-get update && sudo apt-get install -y beef
        ;;
      golang)
        sudo apt-get update && sudo apt-get install -y golang-go
        ;;
      nodejs)
        sudo apt-get update && sudo apt-get install -y nodejs
        ;;
      npm)
        sudo apt-get update && sudo apt-get install -y npm
        ;;
    esac
  done

  # Update tools
  echo "Updating tools..."
  for tool in $TOOLS; do
    case $tool in
      Semgrep)
        cd semgrep && git pull && pip3 install.
        ;;
      CodeQL)
        cd codeql && git pull && mvn compile
        ;;
      Bandit)
        cd bandit && git pull && pip3 install.
        ;;
      FindSecBugs)
        cd find-sec-bugs && git pull && mvn package
        ;;
      OWASP)
        cd owasp-maven-plugin && git pull && mvn install
        ;;
      Syft)
        cd syft && git pull && go build.
        ;;
      Grype)
        cd grype && git pull && go build.
        ;;
      Trivy)
        cd trivy && git pull && go build.
        ;;
      CycloneDX CLI)
        cd cyclonedx-cli && git pull && npm install
        ;;
      ScanCode ToolKit)
        cd scancode-toolkit && git pull && pip3 install.
        ;;
      SPDX tool)
        cd tools && git pull && mvn compile
        ;;
    esac
  done
}

function __besman_reset() {
  # Reset dependencies
  echo "Resetting dependencies..."
  for dependency in $DEPENDENCIES; do
    case $dependency in
      git)
        sudo apt-get purge -y git
        sudo apt-get install -y git
        ;;
      python3)
        sudo apt-get purge -y python3
        sudo apt-get install -y python3
        ;;
      pip)
        sudo apt-get purge -y python3-pip
        sudo apt-get install -y python3-pip
        ;;
      java)
        sudo apt-get purge -y default-jre
        sudo apt-get install -y default-jre
        ;;
      maven)
        sudo apt-get purge -y maven
        sudo apt-get install -y maven
        ;;
      beef)
        sudo apt-get purge -y beef
        sudo apt-get install -y beef
        ;;
      golang)
        sudo apt-get purge -y golang-go
        sudo apt-get install -y golang-go
        ;;
      nodejs)
        sudo apt-get purge -y nodejs
        sudo apt-get install -y nodejs
        ;;
      npm)
        sudo apt-get purge -y npm
        sudo apt-get install -y npm
        ;;
    esac
  done

  # Reset tools
  echo "Resetting tools..."
  for tool in $TOOLS; do
    case $tool in
      Semgrep)
        cd semgrep && git reset --hard && pip3 install.
        ;;
      CodeQL)
        cd codeql && git reset --hard && mvn compile
        ;;
      Bandit)
        cd bandit && git reset --hard && pip3 install.
        ;;
      FindSecBugs)
        cd find-sec-bugs && git reset --hard && mvn package
        ;;
      OWASP)
        cd owasp-maven-plugin && git reset --hard && mvn install
        ;;
      Syft)
        cd syft && git reset --hard && go build.
        ;;
      Grype)
        cd grype && git reset --hard && go build.
        ;;
      Trivy)
        cd trivy && git reset --hard && go build.
        ;;
      CycloneDX CLI)
        cd cyclonedx-cli && git reset --hard && npm install
        ;;
      ScanCode ToolKit)
        cd scancode-toolkit && git reset --hard && pip3 install.
        ;;
      SPDX tool)
        cd tools && git reset --hard && mvn compile
        ;;
    esac
  done
}

# Call the desired function
case $1 in
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
    ;;
esac