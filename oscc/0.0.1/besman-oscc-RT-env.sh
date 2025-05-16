#!/bin/bash

function __besman_install {

    __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1 # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    # Clones the source code repo.
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi
    # Please add the rest of the code here for installation

    # ************************* env dependency *********************************

    ## Name:docker
    __besman_echo_white "Check if docker is installed or not"
    if [ ! -x "$(command -v docker)" ]; then
        __besman_echo_white "Docker is not installed. Installing Docker..."
        __besman_echo_white "installing docker ..."
        sudo apt update
        sudo apt install -y ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io

        # sudo groupadd -f docker
        sudo usermod -aG docker $USER
        sudo systemctl restart docker
        # newgrp docker

        #sudo su - $USER

        # Check if Docker is successfully installed and running
        if ! command -v docker &>/dev/null; then
            __besman_echo_white "Docker installation failed or Docker is not available."
        else
            docker version
        fi

        __besman_echo_white "Docker installation is completed"
    else
        __besman_echo_white "Docker is already installed."
    fi

    ## Name:snap to use go
    __besman_echo_white "check if snap is installed or not"
    if ! [ -x "$(command -v snap)" ]; then
        __besman_echo_white "installing snap ..."
        sudo apt update
        sudo apt install snapd
    else
        __besman_echo_white "snap is already available"
    fi

    ## Name:go to use criticality_score
    __besman_echo_white "check if go is intalled or not"
    if ! [ -x "$(command -v go)" ]; then
        __besman_echo_white "installing go ..."
        sudo snap install go --classic
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    else
        __besman_echo_white "go is already available"
    fi

    # ********************** Assessment tools ********************************

    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] && readarray -d ',' -t ASSESSMENT_TOOLS <<<"$BESMAN_ASSESSMENT_TOOLS"

    if [ ! -z $ASSESSMENT_TOOLS ]; then
        for tool in ${ASSESSMENT_TOOLS[*]}; do
            if [[ $tool == *:* ]]; then
                tool_name=${tool%%:*}    # Get the tool name
                tool_version=${tool##*:} # Get the tool version
            else
                tool_name=$tool # Get the tool name
                tool_version="" # No version specified
            fi

            __besman_echo_white "installling tool - $tool : version - $tool_version"

            case $tool_name in
            criticality_score)
                __besman_echo_white "check for criticality_score"
                if ! [ -x "$(command -v criticality_score)" ]; then
                    __besman_echo_white "installing criticality_score ..."
                    go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
                    __besman_echo_white "criticality_score is installed\n"
                else
                    __besman_echo_white "criticality_score is already available"
                fi
                ;;
            sonarqube)
                __besman_echo_white "Installing sonarqube..."
                if [ "$(docker ps -aq -f name=sonarqube-$BESMAN_ARTIFACT_NAME)" ]; then
                    # If a container exists, stop and remove it
                    __besman_echo_white "Removing existing container 'sonarqube-$BESMAN_ARTIFACT_NAME'..."
                    docker stop sonarqube-$BESMAN_ARTIFACT_NAME
                    docker container rm --force sonarqube-$BESMAN_ARTIFACT_NAME
                fi
                # Create sonarqube-docker container
                __besman_echo_white "creating sonarqube container for env - $BESMAN_ARTIFACT_NAME ..."
                docker create --name sonarqube-$BESMAN_ARTIFACT_NAME -p 9000:9000 sonarqube
                docker start sonarqube-$BESMAN_ARTIFACT_NAME

                __besman_echo_white "sonarqube installation is done & $BESMAN_ARTIFACT_NAME container is up"
                ;;
            fossology)
                __besman_echo_white "Installing fossology..."
                __besman_echo_white "check for fossology-docker container"
                if [ "$(docker ps -aq -f name=fossology-$BESMAN_ARTIFACT_NAME)" ]; then
                    # If a container exists, stop and remove it
                    __besman_echo_white "Removing existing container 'fossology-$BESMAN_ARTIFACT_NAME'..."
                    docker stop fossology-$BESMAN_ARTIFACT_NAME
                    docker container rm --force fossology-$BESMAN_ARTIFACT_NAME
                fi

                # Create fossology-docker container
                __besman_echo_white "creating fossology container for env - $BESMAN_ARTIFACT_NAME ..."
                docker create --name fossology-$BESMAN_ARTIFACT_NAME -p 9001:80 fossology/fossology
                docker start fossology-$BESMAN_ARTIFACT_NAME

                __besman_echo_white "fossology installation is done & $BESMAN_ARTIFACT_NAME container is up"
                ;;
            spdx-sbom-generator)
                __besman_echo_white "Installing spdx-sbom-generator..."
                __besman_echo_white "Installing spdx-sbom-generator from github ..."
                # URL of the asset
                __besman_echo_white "Asset URL - $BESMAN_SPDX_SBOM_ASSET_URL"
                # Download the asset
                __besman_echo_white "Downloading the asset ..."
                curl -L -o $BESMAN_TOOL_PATH/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"

                # Check if the download was successful
                if [ $? -eq 0 ]; then
                    __besman_echo_white "Download completed successfully."

                    # Extract the downloaded file
                    __besman_echo_white "Extracting the asset..."
                    cd $BESMAN_TOOL_PATH
                    tar -xzf spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz
                    __besman_echo_white "Extraction completed."
                    cd -
                else
                    __besman_echo_white "Download failed."
                fi

                __besman_echo_white "spdx-sbom-generator installation is done."
                ;;
            *)
                echo "No installation steps found for $tool_name."
                ;;
            esac
        done
        echo "bes assessment tools installation done"
    fi

}

function __besman_uninstall {
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi

    # Please add the rest of the code here for uninstallation

    if [ ! -z $ASSESSMENT_TOOLS ]; then
        for tool in ${ASSESSMENT_TOOLS[*]}; do
            if [[ $tool == *:* ]]; then
                tool_name=${tool%%:*}    # Get the tool name
                tool_version=${tool##*:} # Get the tool version
            else
                tool_name=$tool # Get the tool name
                tool_version="" # No version specified
            fi

            __besman_echo_white "Uninstallling tool - $tool : version - $tool_version"

            case $tool_name in
            criticality_score)
                __besman_echo_white "check for criticality_score"
                if [ -x "$(command -v criticality_score)" ]; then
                    __besman_echo_white "uninstalling criticality_score ..."
                    go install github.com/ossf/criticality_score/v2/cmd/criticality_score@none

		    [[ -f $GOPATH/bin/criticality_score ]] && rm -rf $GOPATH/bin/criticality_score

                    __besman_echo_white "criticality_score is uninstalled\n"
                else
                    __besman_echo_white "criticality_score is not installed"
                fi
                ;;
            sonarqube)
                __besman_echo_white "Uninstalling sonarqube..."
                if [ "$(docker ps -aq -f name=sonarqube-$BESMAN_ARTIFACT_NAME)" ]; then
                    # If a container exists, stop and remove it
                    __besman_echo_white "Removing existing container 'sonarqube-$BESMAN_ARTIFACT_NAME'..."
                    docker stop sonarqube-$BESMAN_ARTIFACT_NAME
                    docker container rm --force sonarqube-$BESMAN_ARTIFACT_NAME
                fi
                __besman_echo_white "sonarqube uninstallation is done"
                ;;
            fossology)
                __besman_echo_white "Uninstalling fossology..."
                __besman_echo_white "check for fossology-docker container"
                if [ "$(docker ps -aq -f name=fossology-$BESMAN_ARTIFACT_NAME)" ]; then
                    # If a container exists, stop and remove it
                    __besman_echo_white "Removing existing container 'fossology-$BESMAN_ARTIFACT_NAME'..."
                    docker stop fossology-$BESMAN_ARTIFACT_NAME
                    docker container rm --force fossology-$BESMAN_ARTIFACT_NAME
                fi
                __besman_echo_white "fossology uninstallation is done"
                ;;
            spdx-sbom-generator)
                __besman_echo_white "Uninstalling spdx-sbom-generator..."
                # URL of the asset
                __besman_echo_white "Asset URL - $BESMAN_SPDX_SBOM_ASSET_URL"
                # Download the asset
                __besman_echo_white "Downloading the asset ..."
                curl -L -o $BESMAN_TOOL_PATH/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz "$BESMAN_SPDX_SBOM_ASSET_URL"
                [[ -f $BESMAN_TOOL_PATH/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz]] && rm -f $BESMAN_TOOL_PATH/spdx-sbom-generator-v0.0.15-linux-amd64.tar.gz
                [[ -d $BESMAN_ARTIFACT_DIR/spdx-sbom-generator* ]] && rm -rf $BESMAN_ARTIFACT_DIR/spdx-sbom-generator*

                __besman_echo_white "spdx-sbom-generator uninstallation is done."
                ;;
            *)
                echo "No uninstallation steps found for $tool_name."
                ;;
            esac
        done
        echo "bes assessment tools uninstallation done"
    fi

    # check docker & containers
    if command -v docker &>/dev/null; then

        # Remove Docker Engine
        # Purge Docker packages and dependencies
        echo "Removing Docker ..."
        sudo apt purge -y docker-ce docker-ce-cli containerd.io

        # Remove Docker’s data and configuration files
        sudo rm -rf /var/lib/docker
        sudo rm -rf /var/lib/containerd

        # Remove Docker GPG key and repository
        sudo rm -rf /usr/share/keyrings/docker-archive-keyring.gpg
        sudo rm -f /etc/apt/sources.list.d/docker.list

        # Remove Docker group
        sudo deluser $USER docker
        sudo groupdel docker

        sudo apt update
        echo "Docker removed successfully"

    fi

    # Check go
    if command -v go &>/dev/null; then
        __besman_echo_white "Removing go..."
        # Remove go
        sudo snap remove go -y
        __besman_echo_white "Go removed successfully."
    fi

    # Clean up unused packages
    sudo apt autoremove -y
}

function __besman_update {

    # Please add the rest of the code here for update
    __besman_echo_white "update"

}

function __besman_validate {

    # Please add the rest of the code here for validate
    __besman_echo_white "validate"

    validationStatus=1
    declare -a errors

    # validate Docker installation
    if ! command -v docker &>/dev/null; then
        __besman_echo_white "Docker is not installed."
        validationStatus=0
        errors+=("Docker")
    fi

    # validate Docker containers
    # Check if the sonarqube container exists and running
    if [ "$(docker ps -q -f name=sonarqube-$BESMAN_ARTIFACT_NAME)" ]; then
        __besman_echo_white "The sonarqube-$BESMAN_ARTIFACT_NAME container is running."
    else
        # Check if the container exists but is stopped
        if [ "$(docker ps -a -q -f name=sonarqube-$BESMAN_ARTIFACT_NAME)" ]; then
            __besman_echo_white "The sonarqube-$BESMAN_ARTIFACT_NAME container exists but is not running."
            validationStatus=0
            errors+=("Docker container - sonarqube-$BESMAN_ARTIFACT_NAME is not running")
        else
            __besman_echo_white "The sonarqube-$BESMAN_ARTIFACT_NAME container does not exist."
            validationStatus=0
            errors+=("Docker container - sonarqube-$BESMAN_ARTIFACT_NAME is missing")
        fi
    fi

    # Check if the fossology container exists and running
    if [ "$(docker ps -q -f name=fossology-$BESMAN_ARTIFACT_NAME)" ]; then
        __besman_echo_white "The fossology-$BESMAN_ARTIFACT_NAME container is running."
    else
        # Check if the container exists but is stopped
        if [ "$(docker ps -a -q -f name=fossology-$BESMAN_ARTIFACT_NAME)" ]; then
            __besman_echo_white "The fossology-$BESMAN_ARTIFACT_NAME container exists but is not running."
            validationStatus=0
            errors+=("Docker container - fossology-$BESMAN_ARTIFACT_NAME is not running")
        else
            __besman_echo_white "The fossology-$BESMAN_ARTIFACT_NAME container does not exist."
            validationStatus=0
            errors+=("Docker container - fossology-$BESMAN_ARTIFACT_NAME is missing")
        fi
    fi

    # validate snap installation
    if ! command -v snap &>/dev/null; then
        __besman_echo_white "snap is not installed."
        validationStatus=0
        errors+=("snap is missing")
    fi

    # validate go installation
    if ! command -v go &>/dev/null; then
        __besman_echo_white "go is not installed."
        validationStatus=0
        errors+=("go is missing")
    fi

    # validate criticality_score installation
    if ! command -v criticality_score &>/dev/null; then
        __besman_echo_white "criticality_score is not installed."
        validationStatus=0
        errors+=("criticality_score is missing")
    fi

    __besman_echo_white "errors: " ${errors[@]}

}

function __besman_reset {
    # Please add the rest of the code here for reset
    __besman_echo_white "reset"
}
