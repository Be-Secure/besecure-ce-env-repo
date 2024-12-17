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
}

function __besman_uninstall
{
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=remove role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi

    # Please add the rest of the code here for uninstallation

    # check criticality_score
    if command -v criticality_score &>/dev/null; then
        __besman_echo_white "Removing criticality_score..."
        # Remove criticality_score
        sudo rm -rf $GOPATH/bin/criticality_score
        sudo apt update
        __besman_echo_white "criticality_score removed successfully."
    fi

    # Check go
    if command -v go &>/dev/null; then
        __besman_echo_white "Removing go..."
        # Remove go
        sudo snap remove go -y
        __besman_echo_white "Go removed successfully."
    fi

    # check docker & containers
    if command -v docker &>/dev/null; then

        # remove sonarqube container
        __besman_echo_white "Un-installing sonarqube..."
        __besman_echo_white "removing container ..."
        if [ "$(docker ps -aq -f name=sonarqube-$BESMAN_ARTIFACT_DIR)" ]; then
            docker stop sonarqube-$BESMAN_ARTIFACT_DIR
            docker container rm --force sonarqube-$BESMAN_ARTIFACT_DIR

            __besman_echo_white "Docker containers sonarqube-$BESMAN_ARTIFACT_DIR removed"
        fi

        # remove fossology container
        __besman_echo_white "Un-installing fossology..."
        __besman_echo_white "removing container ..."
        if [ "$(docker ps -aq -f name=fossology-$BESMAN_ARTIFACT_DIR)" ]; then
            docker stop fossology-$BESMAN_ARTIFACT_DIR
            docker container rm --force fossology-$BESMAN_ARTIFACT_DIR
            __besman_echo_white "Docker containers fossology-$BESMAN_ARTIFACT_DIR removed"
        fi

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
