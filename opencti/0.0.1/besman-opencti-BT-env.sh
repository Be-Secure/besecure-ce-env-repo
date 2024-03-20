#!/bin/bash

function __besman_install_opencti-BT-env {

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

    #------------------------------------------------------------------------------------------
    # Check if Docker is installed
    if ! command -v docker &>/dev/null; then
        install_docker
    else
        echo -e "\nDocker is already there to use."
    fi

    # Function to install Docker
    install_docker() {
        echo -e "\nInstalling Docker..."
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
        echo -e "\nDocker installed successfully.\n"
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

    # Check if Yarn is installed
    if ! command -v yarn &>/dev/null; then
        echo -e "\nYarn is not installed. Installing Yarn..."
        # Add Yarn repository key
        curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
        # Add Yarn repository
        echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
        # Update package index
        sudo apt update
        # Install Yarn
        sudo apt install yarn -y
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

    # Check if Python is installed
    if ! command -v python3 &>/dev/null; then
        echo "Python is not installed. Installing Python..."
        sudo apt update
        sudo apt install python3 -y
    fi

    # Check if pip is installed
    if ! command -v pip3 &>/dev/null; then
        echo "pip is not installed. Installing pip..."
        sudo apt update
        sudo apt install python3-pip -y
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

function __besman_uninstall_opencti-BT-env {
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

function __besman_update_opencti-BT-env {
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for update

}

function __besman_validate_opencti-BT-env {
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
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

function __besman_reset_opencti-BT-env {
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for reset

}
