#!/bin/bash

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
function __besman_install {

    __besman_check_vcs_exist || return 1   # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1   # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    __besman_check_for_ansible || return 1 # Checks if ansible is installed or not.
    __besman_create_roles_config_file      # Creates the role config file with the parameters from env config

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

    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi

    # Please add the rest of the code here for installation
<<<<<<< HEAD
=======
function __besman_install_opencti-RT-env
{
    
=======
function __besman_install_opencti-RT-env {

>>>>>>> 26141c1 (opencti BT & RT environment with install, uninstall and validate function complete)
    __besman_check_for_gh || return 1
    __besman_check_github_id || return 1
    __besman_check_for_ansible || return 1
    __besman_update_requirements_file
    __besman_ansible_galaxy_install_roles_from_requirements
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    if [[ -d $BESMAN_OSSP_CLONE_PATH ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_OSSP"
    else
        __besman_gh_clone "$BESMAN_ORG" "$BESMAN_OSSP" "$BESMAN_OSSP_CLONE_PATH"
    fi
    # Please add the rest of the code here for installation

    # opencti-dev environment script
    echo -e "\nopencti dev modules setup start..."
    #!/bin/bash

<<<<<<< HEAD
>>>>>>> 0de428a (BR-RT environment for opencti project & added packagemanager and IDE for newrelic-java-agent)
=======
    #------------------------------------------------------------------------------------------
    # Check if Docker is installed
    if ! command -v docker &>/dev/null; then
        install_docker
    else
        echo -e "\nDocker is already there to use."
    fi

>>>>>>> 26141c1 (opencti BT & RT environment with install, uninstall and validate function complete)
    # Function to install Docker
    install_docker() {
        echo -e "\nInstalling Docker..."
=======
    # Function to install Docker
    install_docker() {
        echo "Installing Docker..."
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
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
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
        echo "Docker installed successfully."
    }

    # Check if Docker is installed
    if ! command -v docker &>/dev/null; then
        install_docker
    else
        echo "Docker is already there to use."
    fi

<<<<<<< HEAD
<<<<<<< HEAD
=======
    # Function to stop and remove a container if it's running
    stop_and_remove_container() {
        local container_name=$1
        if docker ps -a --format '{{.Names}}' | grep -q "$container_name"; then
            echo "Stopping and removing existing $container_name container..."
            docker stop "$container_name" &>/dev/null
            docker rm "$container_name" &>/dev/null
        fi
=======
        echo -e "\nDocker installed successfully.\n"
>>>>>>> 26141c1 (opencti BT & RT environment with install, uninstall and validate function complete)
    }

    #------------------------------------------------------------------------------------------
    # Stop and remove existing containers if they are already running
    stop_and_remove_container "opencti-dev-redis"
    stop_and_remove_container "opencti-dev-redis-insight"
    stop_and_remove_container "opencti-dev-elasticsearch"
    stop_and_remove_container "opencti-dev-kibana"
    stop_and_remove_container "opencti-dev-minio"
    stop_and_remove_container "opencti-dev-rabbitmq"
    stop_and_remove_container "opencti-dev-jaegertracing"

    # Function to stop and remove a container if it's running
    stop_and_remove_container() {
        local container_name=$1
        if docker ps -a --format '{{.Names}}' | grep -q "$container_name"; then
            echo -e "\nStopping and removing existing $container_name container..."
            docker stop "$container_name" &>/dev/null
            docker rm "$container_name" &>/dev/null
        fi
    }

    #------------------------------------------------------------------------------------------
    # Now pull the images and start the containers
    # Define variables to store image tags
    global REDIS_IMAGE="redis:7.2.4"
    global REDIS_INSIGHT_IMAGE="redislabs/redisinsight:latest"
    global ELASTICSEARCH_IMAGE="docker.elastic.co/elasticsearch/elasticsearch:8.12.0"
    global KIBANA_IMAGE="docker.elastic.co/kibana/kibana:8.12.0"
    global MINIO_IMAGE="minio/minio:latest"
    global RABBITMQ_IMAGE="rabbitmq:3.12-management"
    global JAEGERT_IMAGE="jaegertracing/all-in-one:latest"
    # Starting Redis
    echo -e "\nStarting Redis..."
    docker run -d --name opencti-dev-redis -p 6379:6379 $REDIS_IMAGE

    # Starting Redis Insight
    echo -e "\nStarting Redis Insight..."
    docker run -d --name opencti-dev-redis-insight -p 8001:8001 $REDIS_INSIGHT_IMAGE

    # Starting Elasticsearch
    echo -e "\nStarting Elasticsearch..."
    docker run -d --name opencti-dev-elasticsearch \
        -p 9200:9200 -p 9300:9300 \
        -v esdata:/usr/share/elasticsearch/data \
        -v essnapshots:/usr/share/elasticsearch/snapshots \
        -e "discovery.type=single-node" \
        -e "xpack.ml.enabled=false" \
        -e "xpack.security.enabled=false" \
        -e "ES_JAVA_OPTS=-Xms2G -Xmx2G" \
        --ulimit memlock=-1:-1 --ulimit nofile=65536:65536 \
        $ELASTICSEARCH_IMAGE

    # Starting Kibana
    echo -e "\nStarting Kibana..."
    docker run -d --name opencti-dev-kibana \
        -p 5601:5601 \
        -e "ELASTICSEARCH_HOSTS=http://localhost:9200" \
        --link opencti-dev-elasticsearch:elasticsearch \
        $KIBANA_IMAGE

    # Starting Minio
    echo -e "\nStarting Minio..."
    docker run -d --name opencti-dev-minio \
        -p 9000:9000 -p 9001:9001 -p 35300:35300 \
        -e "MINIO_ROOT_USER=ChangeMe" \
        -e "MINIO_ROOT_PASSWORD=ChangeMe" \
        $MINIO_IMAGE server /data --console-address ":9001"

    # Starting RabbitMQ
    echo -e "\nStarting RabbitMQ..."
    docker run -d --name opencti-dev-rabbitmq \
        -p 5672:5672 -p 15672:15672 \
        $RABBITMQ_IMAGE

    # Starting Jaeger Tracing
    echo -e "\nStarting Jaeger Tracing..."
    docker run -d --name opencti-dev-jaegertracing \
        -p 16686:16686 -p 4318:4318 \
        $JAEGERT_IMAGE

    echo -e "\nAll services started successfully!"

    echo -e "\ndev-module setup completed."

    #------------------------------------------------------------------------------------------
    echo -e "\ngraphql setup start...."
    #!/bin/bash

>>>>>>> 0de428a (BR-RT environment for opencti project & added packagemanager and IDE for newrelic-java-agent)
    # Check if Yarn is installed
    if ! command -v yarn &>/dev/null; then
        echo -e "\nYarn is not installed. Installing Yarn..."
=======
    # Check if Yarn is installed
    if ! command -v yarn &>/dev/null; then
        echo "Yarn is not installed. Installing Yarn..."
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
        # Add Yarn repository key
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        # Add Yarn repository
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        # Update package index
        sudo apt update
        # Install Yarn
        sudo apt install yarn -y
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
    else 
        echo "yarn is already there to use." 
=======
    else
        echo "yarn is already there to use."
>>>>>>> 8cac454 (added RT env - sonarqube, fossology, criticality_score setup)
    fi

<<<<<<< HEAD
=======
    fi

    cd $HOME/$BESMAN_OSSP/opencti-platform/opencti-graphql

    # Install dependencies using Yarn
    yarn install

    # Build GraphQL backend
    yarn build

    # Start GraphQL server
    yarn start &

    echo -e "graphql setup completed....\n"

    #------------------------------------------------------------------------------------------
    echo -e "\nworker setup start...."
    #!/bin/bash

>>>>>>> 0de428a (BR-RT environment for opencti project & added packagemanager and IDE for newrelic-java-agent)
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
    # Check if Python is installed
    if ! command -v python3 &>/dev/null; then
        echo "Python is not installed. Installing Python..."
        sudo apt update
        sudo apt install python3 -y
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
    else 
=======
    else
>>>>>>> 8cac454 (added RT env - sonarqube, fossology, criticality_score setup)
        echo "Python is already there to use."
=======
>>>>>>> 0de428a (BR-RT environment for opencti project & added packagemanager and IDE for newrelic-java-agent)
=======
    else 
        echo "Python is already there to use."
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
    fi

    # Check if pip is installed
    if ! command -v pip3 &>/dev/null; then
        echo "pip is not installed. Installing pip..."
        sudo apt update
        sudo apt install python3-pip -y
<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
    else 
=======
    else
>>>>>>> 8cac454 (added RT env - sonarqube, fossology, criticality_score setup)
        echo "pip is already there is use."
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

    # Create a new container
    echo "Creating new container 'fossology-env'..."
    docker create --name fossology-env -p 8081:80 fossology/fossology

    ## criticality_score - env setup
    # snap is required for go installation
    echo "installing snap ..."
    if ! [ -x "$(command -v snap)" ]; then
        sudo apt update
        sudo apt install snapd
    else
        echo "snap is already available"
    fi

    # go is required to install criticality_score
    echo "installing go ..."
    if ! [ -x "$(command -v go)" ]; then
        sudo snap install --classic --channel=1.21/stable go
        export GOPATH=$HOME/go
        export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
    else
        echo "go is already available"
    fi

    # criticality_score is require to perform the action
    echo -e "installing criticality_score ..."
    if ! [ -x "$(command -v criticality_score)" ]; then
        go install github.com/ossf/criticality_score/cmd/criticality_score@latest
        echo -e "criticality_score is installed\n"
    else
        echo "criticality_score is already available"
    fi

    ## setup snyk using yarn

    echo -e "\nopencti RT env installation is complete"
}

function __besman_uninstall {
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
    echo "opencti RT env un-installation is complete"

}

function __besman_update {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
<<<<<<< HEAD
=======
    fi

    # Navigate to the directory containing the worker script
    cd $HOME/$BESMAN_OSSP/opencti-worker/src

    # Install dependencies using pip
    pip3 install -r requirements.txt

    # Start the worker
    python3 worker.py &

    echo -e "worker setup completed....\n"

    #------------------------------------------------------------------------------------------
    echo -e "\nfront-end setup start....\n"
    #!/bin/bash

    # Check if Yarn is installed
    if ! command -v yarn &>/dev/null; then
        echo "Yarn is not installed. Installing Yarn..."
        # Add Yarn repository key
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        # Add Yarn repository
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        # Update package index
        sudo apt update
        # Install Yarn
        sudo apt install yarn -y
    fi

    # Clone OpenCTI Frontend repository

    cd $HOME/$BESMAN_OSSP/opencti-platform/opencti-front

    # Install dependencies using Yarn
    yarn install

    # Build frontend
    yarn build

    # Serve frontend
    yarn start &

    sleep 30 # Wait for the server to start (you may adjust the duration if needed)
    firefox http://localhost:4000

    echo -e "\nfront-end setup completed...."

    echo -e "\nopencti local setup completed.\n"

    #------------------------------------------------------------------------------------------
}

function __besman_uninstall_opencti-RT-env {
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=remove role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    if [[ -d $BESMAN_OSSP_CLONE_PATH ]]; then
        __besman_echo_white "Removing $BESMAN_OSSP_CLONE_PATH..."
        rm -rf "$BESMAN_OSSP_CLONE_PATH"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_OSSP_CLONE_PATH"
    fi
    # Please add the rest of the code here for uninstallation

    # Stop and remove existing containers if they are already running
    stop_and_remove_container "opencti-dev-redis"
    stop_and_remove_container "opencti-dev-redis-insight"
    stop_and_remove_container "opencti-dev-elasticsearch"
    stop_and_remove_container "opencti-dev-kibana"
    stop_and_remove_container "opencti-dev-minio"
    stop_and_remove_container "opencti-dev-rabbitmq"
    stop_and_remove_container "opencti-dev-jaegertracing"

    # Function to stop and remove a container if it's running
    stop_and_remove_container() {
        local container_name=$1
        if docker ps -a --format '{{.Names}}' | grep -q "$container_name"; then
            echo -e "\nStopping and removing existing $container_name container..."
            docker stop "$container_name" &>/dev/null
            docker rm "$container_name" &>/dev/null
        fi
    }

    # Remove Docker images
    docker rmi $REDIS_IMAGE $REDIS_INSIGHT_IMAGE $ELASTICSEARCH_IMAGE $KIBANA_IMAGE $MINIO_IMAGE $RABBITMQ_IMAGE $JAEGERT_IMAGE

    # Remove Docker package
    sudo apt purge docker-ce docker-ce-cli containerd.io

    # Remove user from Docker group (if needed)
    sudo deluser $USER docker

    # Remove packages
    sudo apt remove docker-ce docker-ce-cli containerd.io

    # Uninstall Yarn
    sudo apt purge yarn

    # Remove Yarn repository file
    sudo rm /etc/apt/sources.list.d/yarn.list

    # Update package index
    sudo apt update

    echo -e "\nUninstallation completed successfully.\n"

}

function __besman_update_opencti-RT-env {
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
>>>>>>> 0de428a (BR-RT environment for opencti project & added packagemanager and IDE for newrelic-java-agent)
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
    # Please add the rest of the code here for update

}

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
function __besman_validate {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
<<<<<<< HEAD
=======
function __besman_validate_opencti-RT-env
{
=======
function __besman_validate_opencti-RT-env {
>>>>>>> 26141c1 (opencti BT & RT environment with install, uninstall and validate function complete)
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
>>>>>>> 0de428a (BR-RT environment for opencti project & added packagemanager and IDE for newrelic-java-agent)
    # Please add the rest of the code here for validate

    # Check if Docker is installed
    if ! command -v docker &>/dev/null; then
        echo "Error: Docker is not installed."
        exit 1
    else
        echo -e "Docker is installed"
    fi

    # Function to check if a Docker image exists
    check_docker_image() {
        local image_name=$1
        if ! docker image inspect "$image_name" &>/dev/null; then
            echo "Error: Docker image $image_name not found."
            exit 1
        else
            echo -e "Docker image $image_name is installed"
        fi
    }

    # Function to check if a Docker container exists
    check_docker_container() {
        local container_name=$1
        if ! docker ps -a --format '{{.Names}}' | grep -q "$container_name"; then
            echo "Error: Docker container $container_name not found."
            exit 1
        else
            echo -e "Docker container $container_name is available"
        fi
    }

    # Check if Docker images exist
    check_docker_image "$REDIS_IMAGE"
    check_docker_image "$REDIS_INSIGHT_IMAGE"
    check_docker_image "$ELASTICSEARCH_IMAGE"
    check_docker_image "$KIBANA_IMAGE"
    check_docker_image "$MINIO_IMAGE"
    check_docker_image "$RABBITMQ_IMAGE"
    check_docker_image "$JAEGERT_IMAGE"

    # Check if Docker containers exist
    check_docker_container "opencti-dev-redis"
    check_docker_container "opencti-dev-redis-insight"
    check_docker_container "opencti-dev-elasticsearch"
    check_docker_container "opencti-dev-kibana"
    check_docker_container "opencti-dev-minio"
    check_docker_container "opencti-dev-rabbitmq"
    check_docker_container "opencti-dev-jaegertracing"

    echo "All Docker images and containers are available."

    # Function to check if Python 3 is installed
    check_python3() {
        if ! command -v python3 &>/dev/null; then
            echo "Error: Python 3 is not installed."
            exit 1
        else
            echo -e "Python3 is installed"
        fi
    }

    # Function to check if Pip is installed
    check_pip() {
        if ! command -v pip &>/dev/null; then
            echo "Error: Pip is not installed."
            exit 1
        else
            echo -e "Pip is installed"
        fi
    }

    # Function to check if Yarn is installed
    check_yarn() {
        if ! command -v yarn &>/dev/null; then
            echo "Error: Yarn is not installed."
            exit 1
        else
            echo -e "Yarn is installed"
        fi
    }

    # Call functions to check for Yarn, Python 3, and Pip
    check_python3
    check_pip
    check_yarn

    echo "All required tools are available."

}

<<<<<<< HEAD
<<<<<<< HEAD
=======
    # Please add the rest of the code here for validate

}

>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
function __besman_reset {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
<<<<<<< HEAD
=======
function __besman_reset_opencti-RT-env
{
=======
function __besman_reset_opencti-RT-env {
>>>>>>> 26141c1 (opencti BT & RT environment with install, uninstall and validate function complete)
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
>>>>>>> 0de428a (BR-RT environment for opencti project & added packagemanager and IDE for newrelic-java-agent)
=======
>>>>>>> a52779c (updated opencti RT env with correct versioning - 0.0.1)
    # Please add the rest of the code here for reset

}
