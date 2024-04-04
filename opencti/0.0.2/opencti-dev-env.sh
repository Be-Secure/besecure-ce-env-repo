#!/bin/bash

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
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    # Add current user to Docker group
    sudo usermod -aG docker $USER
    echo "Docker installed successfully."
}

# Check if Docker is installed
if ! command -v docker &> /dev/null
then
    install_docker
else echo "Docker is already there to use."
fi

# Function to stop and remove a container if it's running
stop_and_remove_container() {
    local container_name=$1
    if docker ps -a --format '{{.Names}}' | grep -q "$container_name"; then
        echo "Stopping and removing existing $container_name container..."
        docker stop "$container_name" &> /dev/null
        docker rm "$container_name" &> /dev/null
    fi
}

# Stop and remove existing containers if they are already running
stop_and_remove_container "opencti-dev-redis"
stop_and_remove_container "opencti-dev-redis-insight"
stop_and_remove_container "opencti-dev-elasticsearch"
stop_and_remove_container "opencti-dev-kibana"
stop_and_remove_container "opencti-dev-minio"
stop_and_remove_container "opencti-dev-rabbitmq"
stop_and_remove_container "opencti-dev-jaegertracing"

# Now start the containers
# Starting Redis
echo "Starting Redis..."
docker run -d --name opencti-dev-redis -p 6379:6379 redis:7.2.4

# Starting Redis Insight
echo "Starting Redis Insight..."
docker run -d --name opencti-dev-redis-insight -p 8001:8001 redislabs/redisinsight:latest

# Starting Elasticsearch
echo "Starting Elasticsearch..."
docker run -d --name opencti-dev-elasticsearch \
  -p 9200:9200 -p 9300:9300 \
  -v esdata:/usr/share/elasticsearch/data \
  -v essnapshots:/usr/share/elasticsearch/snapshots \
  -e "discovery.type=single-node" \
  -e "xpack.ml.enabled=false" \
  -e "xpack.security.enabled=false" \
  -e "ES_JAVA_OPTS=-Xms2G -Xmx2G" \
  --ulimit memlock=-1:-1 --ulimit nofile=65536:65536 \
  docker.elastic.co/elasticsearch/elasticsearch:8.12.0

# Starting Kibana
echo "Starting Kibana..."
docker run -d --name opencti-dev-kibana \
  -p 5601:5601 \
  -e "ELASTICSEARCH_HOSTS=http://localhost:9200" \
  --link opencti-dev-elasticsearch:elasticsearch \
  docker.elastic.co/kibana/kibana:8.12.0

# Starting Minio
echo "Starting Minio..."
docker run -d --name opencti-dev-minio \
  -p 9000:9000 -p 9001:9001 -p 35300:35300 \
  -e "MINIO_ROOT_USER=ChangeMe" \
  -e "MINIO_ROOT_PASSWORD=ChangeMe" \
  minio/minio:latest server /data --console-address ":9001"

# Starting RabbitMQ
echo "Starting RabbitMQ..."
docker run -d --name opencti-dev-rabbitmq \
  -p 5672:5672 -p 15672:15672 \
  rabbitmq:3.12-management

# Starting Jaeger Tracing
echo "Starting Jaeger Tracing..."
docker run -d --name opencti-dev-jaegertracing \
  -p 16686:16686 -p 4318:4318 \
  jaegertracing/all-in-one:latest

echo "All services started successfully!"

