#!/bin/bash

# Exit script on error

set -e

# Function to install, uninstall, update, validate, and reset tools

besman_install() {

    TOOL_NAME=$1

    INSTALL_COMMAND=$2

    UNINSTALL_COMMAND=$3

    UPDATE_COMMAND=$4

    VALIDATE_COMMAND=$5

    RESET_COMMAND=$6

    COMMAND=$7

    ACTION=$8  # install, uninstall, update, validate, reset

    case $ACTION in

        install)

            if ! command -v $COMMAND &> /dev/null; then

                echo "$TOOL_NAME not found, installing..."

                eval "$INSTALL_COMMAND"

            else

                echo "$TOOL_NAME is already installed."

            fi

            ;;

        uninstall)

            if command -v $COMMAND &> /dev/null; then

                echo "Uninstalling $TOOL_NAME..."

                eval "$UNINSTALL_COMMAND"

            else

                echo "$TOOL_NAME is not installed."

            fi

            ;;

        update)

            if command -v $COMMAND &> /dev/null; then

                echo "Updating $TOOL_NAME..."

                eval "$UPDATE_COMMAND"

            else

                echo "$TOOL_NAME is not installed. Installing instead..."

                eval "$INSTALL_COMMAND"

            fi

            ;;

        validate)

            if command -v $COMMAND &> /dev/null; then

                echo "Validating $TOOL_NAME..."

                eval "$VALIDATE_COMMAND"

            else

                echo "$TOOL_NAME is not installed. Cannot validate."

            fi

            ;;

        reset)

            if command -v $COMMAND &> /dev/null; then

                echo "Resetting $TOOL_NAME..."

                eval "$RESET_COMMAND"

            else

                echo "$TOOL_NAME is not installed. Cannot reset."

            fi

            ;;

        *)

            echo "Invalid action: $ACTION"

            exit 1

            ;;

    esac

}

echo "Validating required tools..."

sudo apt update -y

# Load tools from config.yml

CONFIG_FILE="config.yml"

for tool in $(yq e '.tools[].name' $CONFIG_FILE); do

    INSTALL_CMD=$(yq e ".tools[] | select(.name == \"$tool\").install" $CONFIG_FILE)

    UNINSTALL_CMD=$(yq e ".tools[] | select(.name == \"$tool\").uninstall" $CONFIG_FILE)

    UPDATE_CMD=$(yq e ".tools[] | select(.name == \"$tool\").update" $CONFIG_FILE)

    VALIDATE_CMD=$(yq e ".tools[] | select(.name == \"$tool\").validate" $CONFIG_FILE)

    RESET_CMD=$(yq e ".tools[] | select(.name == \"$tool\").reset" $CONFIG_FILE)

    COMMAND=$(yq e ".tools[] | select(.name == \"$tool\").command" $CONFIG_FILE)

    besman_install "$tool" "$INSTALL_CMD" "$UNINSTALL_CMD" "$UPDATE_CMD" "$VALIDATE_CMD" "$RESET_CMD" "$COMMAND" "install"

done

echo "All necessary tools are installed. Proceeding with vulnerability scanning..."

# Run npm update to ensure dependencies are up to date

echo "Updating project dependencies..."

npm update

echo "Starting vulnerability scanning..."

# Run npm audit to check for vulnerabilities

echo "Running npm audit to check for vulnerabilities..."

npm audit --json > npm-audit-report.json

if [ -s npm-audit-report.json ]; then

    echo "Vulnerabilities found by npm audit! Generating report..."

    cat npm-audit-report.json | jq .

else

    echo "No vulnerabilities found via npm audit."

fi

# Run Snyk test to find more vulnerabilities

echo "Running Snyk to check for vulnerabilities..."

snyk test --all-projects > snyk-report.txt

if [ -s snyk-report.txt ]; then

    echo "Snyk found vulnerabilities! Check snyk-report.txt for details."

else

    echo "No vulnerabilities found by Snyk."

fi

# Run Retire.js to scan for JavaScript vulnerabilities

echo "Running Retire.js to scan for vulnerabilities in JS libraries..."

retire --scan . > retire-report.txt

if [ -s retire-report.txt ]; then

    echo "Retire.js found vulnerabilities! Check retire-report.txt for details."

else

    echo "No vulnerabilities found by Retire.js."

fi

echo "Vulnerability scanning completed!"