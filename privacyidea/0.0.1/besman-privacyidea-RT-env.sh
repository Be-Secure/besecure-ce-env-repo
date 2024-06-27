#!/bin/bash

function __besman_install
{

    __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1 # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE 
    __besman_check_for_ansible || return 1 # Checks if ansible is installed or not.
    __besman_create_roles_config_file # Creates the role config file with the parameters from env config
    
    # Requirements file is used to list the required ansible roles. The data for requirements file comes from BESMAN_ANSIBLE_ROLES env var.
    # This function updates the requirements file from BESMAN_ANSIBLE_ROLES env var.
    __besman_update_requirements_file 
    __besman_ansible_galaxy_install_roles_from_requirements # Downloads the ansible roles mentioned in BESMAN_ANSIBLE_ROLES to BESMAN_ANSIBLE_ROLES_PATH
    # This function checks for the playbook BESMAN_ARTIFACT_TRIGGER_PLAYBOOK under BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH.
    # The trigger playbook is used to run the ansible roles.
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook # Creates the trigger playbook if not present.
    # Runs the trigger playbook. We are also passing these variables - bes_command=install; role_path=$BESMAN_ANSIBLE_ROLES_PATH
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Clones the source code repo.
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]] 
    then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi
    # Please add the rest of the code here for installation
    # Check if Python is installed
    if ! command -v python3 &>/dev/null; then
        echo "Python is not installed. Installing Python..."
        sudo apt update
        sudo apt install python3 -y
    else
        echo "Python is already there to use."
    fi

    # Check if pip is installed
    if ! command -v pip3 &>/dev/null; then
        echo "pip is not installed. Installing pip..."
        sudo apt update
        sudo apt install python3-pip -y
    else
        echo "pip is already there is use."
    fi

    # Function to install Docker
    install_docker() {
        echo "Installing Docker..."
        # Update package index
        sudo apt update
        # Install dependencies
        sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
        # Add Docker GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        # Add Docker repository
        echo \
            "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        # Install Docker Engine
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        # Add current user to Docker group
        sudo usermod -aG docker $USER
        echo "Docker installed successfully."
    }

    # Check if Docker is installed
    if ! command -v docker &>/dev/null; then
        install_docker
    else
        echo "Docker is already there to use."
    fi

    echo "creating and setting-up sonarqube docker container for sonarqube scan"
    if [ "$(docker ps -aq -f name=sonarqube-env)" ]; then
        # If a container exists, stop and remove it
        echo "Removing existing container 'sonarqube-env'..."
        docker stop sonarqube-env
        docker rm --force sonarqube-env
    fi

    # create sonarqube docker image and container - env setup
    docker create --name sonarqube-env -p 9000:9000 sonarqube

    # create fossology docker image and container - env setup
    # Check if a container with the name "fossology-env" already exists
    echo "creating and setting-up fossology docker container for fossology scan"
    if [ "$(docker ps -aq -f name=fossology-env)" ]; then
        # If a container exists, stop and remove it
        echo "Removing existing container 'fossology-env'..."
        docker stop fossology-env
        docker rm --force fossology-env
    fi

    # create fossology docker image and container - env setup
    echo "Creating new container 'fossology-env'..."
    docker create --name fossology-env -p 8081:80 fossology/fossology

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
    # Function to stop and remove Docker containers
    stop_and_remove_containers() {
        echo "Stopping and removing Docker containers..."
        # Stop and remove sonarqube-env container if it exists
        if [ "$(docker ps -aq -f name=sonarqube-env)" ]; then
            echo "Stopping and removing container 'sonarqube-env'..."
            docker stop sonarqube-env
            docker rm --force sonarqube-env
        fi
        # Stop and remove fossology-env container if it exists
        if [ "$(docker ps -aq -f name=fossology-env)" ]; then
            echo "Stopping and removing container 'fossology-env'..."
            docker stop fossology-env
            docker rm --force fossology-env
        fi
        echo "Docker containers stopped and removed successfully."
    }

    # Function to uninstall Docker
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
        echo "Docker uninstalled successfully."
    }

    # Check if Docker is installed
    if command -v docker &>/dev/null; then
        uninstall_docker
    fi

}

function __besman_update
{
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for update

}

function __besman_validate
{
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for validate
    validate_python() {
        if ! command -v python3 &>/dev/null; then
            echo "Python is not installed."
            return 1
        fi
    }

    # Function to validate pip installation
    validate_pip() {
        if ! command -v pip3 &>/dev/null; then
            echo "pip is not installed."
            return 1
        fi
    }

    # Function to validate Docker installation
    validate_docker() {
        if ! command -v docker &>/dev/null; then
            echo "Docker is not installed."
            return 1
        fi
    }

    # Function to validate Docker containers
    validate_docker_containers() {
        # Validate sonarqube-env container
        if ! docker ps -a --format '{{.Names}}' | grep -q 'sonarqube-env'; then
            echo "Docker container 'sonarqube-env' is not running."
            return 1
        fi
        # Validate fossology-env container
        if ! docker ps -a --format '{{.Names}}' | grep -q 'fossology-env'; then
            echo "Docker container 'fossology-env' is not running."
            return 1
        fi
    }

    # Main validation function
    validate_environment() {
        # Array to store error messages
        declare -a errors

        # Validate all components and store errors
        validate_python || errors+=("Python")
        validate_pip || errors+=("pip")
        validate_docker || errors+=("Docker")
        validate_docker_containers || errors+=("Docker containers")

        # Check if any error message is present
        if [ ${#errors[@]} -eq 0 ]; then
            echo "All requirements satisfied. Environment is set up successfully."
        else
            echo "Some requirements are not satisfied. Please install the following:"
            for error in "${errors[@]}"; do
                echo "- $error"
            done
        fi
    }

    # Run validation
    validate_environment

}

function __besman_reset
{
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for reset

}
