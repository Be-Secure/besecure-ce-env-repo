#!/bin/bash

function __besman_install {

    __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1 # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    # __besman_check_for_ansible || return 1 # Checks if ansible is installed or not.
    # __besman_create_roles_config_file      # Creates the role config file with the parameters from env config

    # # Requirements file is used to list the required ansible roles. The data for requirements file comes from BESMAN_ANSIBLE_ROLES env var.
    # # This function updates the requirements file from BESMAN_ANSIBLE_ROLES env var.
    # __besman_update_requirements_file
    # __besman_ansible_galaxy_install_roles_from_requirements # Downloads the ansible roles mentioned in BESMAN_ANSIBLE_ROLES to BESMAN_ANSIBLE_ROLES_PATH
    # # This function checks for the playbook BESMAN_ARTIFACT_TRIGGER_PLAYBOOK under BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH.
    # # The trigger playbook is used to run the ansible roles.
    # __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    # [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook # Creates the trigger playbook if not present.
    # # Runs the trigger playbook. We are also passing these variables - bes_command=install; role_path=$BESMAN_ANSIBLE_ROLES_PATH
    # __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
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

    install_CommonDep

    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] && readarray -d ',' -t ASSESSMENT_TOOLS <<<"$BESMAN_ASSESSMENT_TOOLS"

    if [ ! -z $ASSESSMENT_TOOLS ]; then
        for tool in ${ASSESSMENT_TOOLS[*]}; do

            install_$tool

        done
        echo "bes assessment tools installation done"
    fi

    cd $BESMAN_ARTIFACT_DIR
    yarn install

}

function __besman_uninstall {
    # __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    # [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    # __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=remove role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi
    # Please add the rest of the code here for uninstallation
    uninstall_criticality_score() {
        __besman_echo_white "Uninstalling criticality_score..."
        # Remove criticality_score
        sudo rm -rf $GOPATH/bin/criticality_score
        __besman_echo_white "criticality_score uninstalled successfully."
    }

    uninstall_docker() {
        echo "Uninstalling Docker..."
        # Stop and remove Docker containers
        stop_and_remove_containers
        # Remove Docker Engine
        sudo apt purge -y docker-ce docker-ce-cli containerd.io
        # Remove Docker GPG key
        sudo rm -rf /usr/share/keyrings/docker-archive-keyring.gpg
        # Remove Docker repository
        sudo rm -f /etc/apt/sources.list.d/docker.list
        # Remove current user from Docker group
        sudo deluser $USER docker
        __besman_echo_white "Docker containers removed & Docker uninstalled successfully"
    }

    stop_and_remove_containers() {
        if [ "$(docker ps -aq -f name=sonarqube-oasp-seller-app)" ]; then
            docker stop sonarqube-oasp-seller-app fossology-oasp-seller-app
            docker container rm --force sonarqube-oasp-seller-app
        fi

        if [ "$(docker ps -aq -f name=fossology-oasp-seller-app)" ]; then
            docker stop fossology-oasp-seller-app
            docker container rm --force fossology-oasp-seller-app
        fi
    }

    if ! [ -x "$(command -v criticality_score)" ]; then
        uninstall_criticality_score
    fi

    if command -v docker &>/dev/null; then
        uninstall_docker
    fi

}

function __besman_update {
    # __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    # [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    # __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for update

    __besman_echo_white "update"
}

function __besman_validate {
    # __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    # [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    # __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for validate
    __besman_echo_white "validate"

    # Function to validate Docker installation
    validate_docker() {
        if ! command -v docker &>/dev/null; then
            __besman_echo_white "Docker is not installed."
            return 1
        fi
    }

    # Function to validate Docker containers
    validate_docker_containers() {
        # Check if the sonarqube-oasp-seller-app container exists and is running
        if [ "$(docker ps -q -f name=sonarqube-oasp-seller-app)" ]; then
            __besman_echo_white "The sonarqube-oasp-seller-app container is running."
        else
            # Check if the container exists but is stopped
            if [ "$(docker ps -a -q -f name=sonarqube-oasp-seller-app)" ]; then
                __besman_echo_white "The sonarqube-oasp-seller-app container exists but is not running."
                return 1
            else
                __besman_echo_white "The sonarqube-oasp-seller-app container does not exist."
                return 1
            fi
        fi

        # Check if the sonarqube-oasp-seller-app container exists and is running
        if [ "$(docker ps -q -f name=fossology-oasp-seller-app)" ]; then
            __besman_echo_white "The fossology-oasp-seller-app container is running."
        else
            # Check if the container exists but is stopped
            if [ "$(docker ps -a -q -f name=fossology-oasp-seller-app)" ]; then
                __besman_echo_white "The fossology-oasp-seller-app container exists but is not running."
                return 1
            else
                __besman_echo_white "The fossology-oasp-seller-app container does not exist."
                return 1
            fi
        fi
    }

    # Function to validate Yarn installation
    validate_yarn() {
        if ! command -v yarn &>/dev/null; then
            echo "Yarn is not installed."
            return 1
        fi
    }

    # Function to validate snap installation
    validate_snap() {
        if ! command -v snap &>/dev/null; then
            echo "snap is not installed."
            return 1
        fi
    }

    # Function to validate go installation
    validate_go() {
        if ! command -v go &>/dev/null; then
            echo "go is not installed."
            return 1
        fi
    }

    # Function to validate criticality_score installation
    validate_criticality_score() {
        if ! command -v criticality_score &>/dev/null; then
            echo "criticality_score is not installed."
            return 1
        fi
    }

    validate_environment() {
        # Array to store error messages
        declare -a errors

        validate_docker || errors+=("Docker")
        validate_docker_containers || errors+=("Docker containers")
        validate_yarn || errors+=("Yarn")
        validate_snap || errors+=("snap")
        validate_go || errors+=("go")
        validate_criticality_score || errors+=("criticality_score")

    }
    validate_environment

}

function __besman_reset {
    # __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    # [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    # __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for reset
    __besman_echo_white "reset"

}

###
## function for each bes tool declared in steps file
###

function install_CommonDep {

    __besman_echo_white "Check & install docker"
    if ! command -v docker &>/dev/null; then
        __besman_echo_white "Docker is not installed. Installing Docker..."
        # Docker installation steps
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
        sudo apt update
        sudo apt-cache policy docker-ce
        sudo apt install -y docker-ce
        sudo systemctl status docker --no-pager
        sudo usermod -aG docker $USER
        __besman_echo_white "Docker installation completed."
    else
        __besman_echo_white "Docker is already installed."
    fi

    __besman_echo_white "check is npm & yarn is installed"
    if ! command -v npm &>/dev/null; then
        sudo apt update
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
        sudo apt install -y nodejs
        npm install --global yarn
    else
        __besman_echo_white "npm is already available"
    fi

    # snap is required for go installation
    __besman_echo_white "installing snap ..."
    if ! [ -x "$(command -v snap)" ]; then
        sudo apt update
        sudo apt install snapd
    else
        __besman_echo_white "snap is already available"
    fi

    # go is required to install criticality_score
    __besman_echo_white "installing go ..."
    if ! [ -x "$(command -v go)" ]; then
        sudo snap install go --classic
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    else
        __besman_echo_white "go is already available"
    fi

    return 0
}

function install_sonarqube {
    __besman_echo_white "check for sonarqube-docker container"
    if [ "$(docker ps -aq -f name=sonarqube-oasp-seller-app)" ]; then
        # If a container exists, stop and remove it
        __besman_echo_white "Removing existing container 'sonarqube-oasp-seller-app'..."
        docker stop sonarqube-oasp-seller-app
        docker container rm --force sonarqube-oasp-seller-app
    fi
    __besman_echo_white "creating sonarqube container for env - oasp-seller-app ..."
    docker create --name sonarqube-oasp-seller-app -p 9000:9000 sonarqube
    docker start sonarqube-oasp-seller-app

    return 0
}

function install_fossology {
    __besman_echo_white "check for fossology-docker container ..."
    if [ "$(docker ps -aq -f name=fossology-oasp-seller-app)" ]; then
        # If a container exists, stop and remove it
        echo "Removing existing container 'fossology-oasp-seller-app'..."
        docker stop fossology-oasp-seller-app
        docker container rm --force fossology-oasp-seller-app
    fi

    # Create fossology-docker container
    __besman_echo_white "creating fossology container for env - oasp-seller-app ..."
    docker create --name fossology-oasp-seller-app -p 8081:80 fossology/fossology
    docker start fossology-oasp-seller-app

    return 0

}

function install_scorecard {

    return 0

}

function install_criticality_score {
    __besman_echo_white "installing criticality_score ..."
    if ! [ -x "$(command -v criticality_score)" ]; then
        go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
        __besman_echo_white "criticality_score is installed\n"
    else
        __besman_echo_white "criticality_score is already available"
    fi

    return 0

}

function install_spdx-sbom-generator {

    return 0

}
