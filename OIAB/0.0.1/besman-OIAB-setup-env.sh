#!/bin/bash

function __besman_install_docker() {

    __besman_echo_no_colour "Checking if Docker is installed..."

    if command -v docker >/dev/null 2>&1; then
        __besman_echo_yellow "Docker is already installed"
        docker --version
    else
        __besman_echo_white "Docker not found. Installing Docker..."

        # Update package index
        sudo apt-get update

        # Install required packages
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            gnupg \
            lsb-release

        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

        # Set up stable repository
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
          $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

        # Install Docker Engine
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io

        # Start Docker service
        sudo systemctl start docker
        sudo systemctl enable docker

        # Add current user to docker group
        sudo usermod -aG docker $USER

        __besman_echo_yellow "Docker installed successfully!"
        docker --version
    fi
}

function __besman_install_buyer_ui() {
    if [[ -d $BESMAN_OIAB_BUYER_UI_DIR ]]; then
        __besman_echo_white "Buyer ui code found"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_ORG/$BESMAN_OIAB_BUYER_UI"
        __besman_repo_clone "$BESMAN_ORG" "$BESMAN_OIAB_BUYER_UI" "$BESMAN_OIAB_BUYER_UI_DIR" || return 1
    fi
    cd "$BESMAN_OIAB_BUYER_UI_DIR" || return 1
    __besman_echo_white "Installing $BESMAN_OIAB_BUYER_UI"
    __besman_echo_yellow "Building OIAB buyer ui"

    # Check Dockerfile port
    if grep -q "EXPOSE 8001" Dockerfile; then
        __besman_echo_yellow "Port 8001 already exposed in Dockerfile"
    else
        sed -i "s/EXPOSE 80/EXPOSE 8001/g" Dockerfile
        __besman_echo_white "Updated Dockerfile port to 8001"
    fi

    # Check nginx.conf port
    if grep -q "listen 8001;" nginx.conf; then
        __besman_echo_yellow "Port 8001 already configured in nginx.conf"
    else
        sed -i "s/listen 80;/listen 8001;/g" nginx.conf
        __besman_echo_white "Updated nginx.conf port to 8001"
    fi

    docker build --build-arg VITE_API_BASE_URL="$BESMAN_IP_ADDRESS:8000" -t oiab-buyer-ui .
    docker run -d --name oiab-buyer-ui -p 8001:8001 oiab-buyer-ui
    cd "$HOME" || return 1

}

function __besman_install_buyer_app() {

    local env_file="$BESMAN_OIAB_BUYER_APP_DIR/.env.default"
    if [[ -d $BESMAN_OIAB_BUYER_APP_DIR ]]; then
        __besman_echo_white "Buyer app code found"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_ORG/$BESMAN_OIAB_BUYER_APP"
        __besman_repo_clone "$BESMAN_ORG" "$BESMAN_OIAB_BUYER_APP" "$BESMAN_OIAB_BUYER_APP_DIR" || return 1
    fi
    cd "$BESMAN_OIAB_BUYER_APP_DIR" || return 1
    # Check if MongoDB port is already mapped to 27018
    if grep -q "27018:27017" docker-compose.yml; then
        __besman_echo_yellow "MongoDB port already mapped to 27018"
    else
        sed -i 's/27017:27017/27018:27017/' docker-compose.yml
        __besman_echo_white "Updated MongoDB port mapping to 27018:27017"
    fi

    sed -i "s|PROTOCOL_SERVER_URL=.*|PROTOCOL_SERVER_URL=$BESMAN_IP_ADDRESS:5001|g" "$env_file"
    sed -i "s|BAP_ID=.*|BAP_ID=$BESMAN_BAP_ID|g" "$env_file"
    sed -i "s|BAP_URI=.*|BAP_URI=$BESMAN_BAP_URI|g" "$env_file"

    __besman_echo_white "Installing $BESMAN_OIAB_BUYER_APP"
    __besman_echo_yellow "Building buyer app"
    docker-compose up --build -d
    cd "$HOME" || return 1
}

function __besman_install_docker_compose() {
    __besman_echo_no_colour "Checking if Docker Compose is installed..."

    if command -v docker-compose >/dev/null 2>&1; then
        __besman_echo_yellow "Docker Compose is already installed"
        docker-compose --version
    else
        __besman_echo_white "Docker Compose not found. Installing latest version..."

        # Download the latest version of Docker Compose
        sudo curl -L "https://github.com/docker/compose/releases/latest/$BESMAN_DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

        # Apply executable permissions
        sudo chmod +x /usr/local/bin/docker-compose

        __besman_echo_yellow "Docker Compose installed successfully!"
        docker-compose --version
    fi
}

function __besman_install_beckn_onix() {

    local install_file="$BESMAN_BECKN_ONIX_DIR/install/beckn-onix.sh"

    if [[ -d $BESMAN_BECKN_ONIX_DIR ]]; then
        __besman_echo_white "Beckn Onix code found"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_BECKN_ONIX_SOURCE/$BESMAN_BECKN_ONIX_SOURCE_REPO"
        __besman_repo_clone "$BESMAN_BECKN_ONIX_SOURCE" "$BESMAN_BECKN_ONIX_SOURCE_REPO" "$BESMAN_BECKN_ONIX_DIR" || return 1
        cd "$BESMAN_BECKN_ONIX_DIR" || return 1
        if [[ "$BESMAN_BECKN_ONIX_SOURCE_BRANCH" != "main" ]]; then
            git checkout "$BESMAN_BECKN_ONIX_SOURCE_BRANCH"
            __besman_echo_white "Switched to branch: $BESMAN_BECKN_ONIX_SOURCE_BRANCH"
        fi
    fi

}  

function __besman_install_ossverse_network() {
    # Running the third option in beckn-onix.sh(install file) which will install the entire network in your current machine.
    local install_file="$BESMAN_BECKN_ONIX_DIR/install/beckn-onix.sh"
    cd "$BESMAN_BECKN_ONIX_DIR/install" || return 1
    echo "3" | ./beckn-onix.sh

    if [[ "$?" != "0" ]]; then
        __besman_echo_red "Failed to install using Beckn Onix"
        return 1
    else
        __besman_echo_green "Successfully installed the entire network using Beckn Onix"
        return 0
    fi
}

function __besman_copy_layer2_config() {

    local layer2_config_dir="$BESMAN_BECKN_ONIX_DIR/layer2/samples"
    local layer2_file="Software Assurance_1.0.0.yaml"
    local source_path="$layer2_config_dir/$layer2_file"
    local destination_path="/usr/src/app/schemas"
    __besman_echo_white "Copying layer2 config files"
    
    if [[ -f $source_path ]];
    then
        __besman_echo_yellow "Found layer2 $source_path"
    else
        cp "$layer2_config_dir/retail_1.1.0.yaml" "$source_path" || {
            __besman_echo_red "Failed to copy retail yaml file"
            return 1
        }
    fi

    __besman_echo_yellow "Using volume, copying layer2 folder"

    docker run --rm \
    -v bap_client_schemas_volume:$destination_path \
    -v "$(dirname "$source_path"):/source" \
    busybox cp "/source/$(basename "$source_path")" "$destination_path" || {
        __besman_echo_red "Failed to copy layer2 file into the container"
        return 1

    # docker cp "$source_path" "bap-client:$destination_path" || {
    #     __besman_echo_red "Failed to copy config to bap-client"
    #     return 1
    # }
    
    # docker cp "$source_path" "bap-network:$destination_path" || {
    #     __besman_echo_red "Failed to copy config to bap-network"
    #     return 1
    # }
    
    # docker cp "$source_path" "bpp-network:$destination_path" || {
    #     __besman_echo_red "Failed to copy config to bpp-network"
    #     return 1
    # }
    
    # docker cp "$source_path" "bpp-client:$destination_path" || {
    #     __besman_echo_red "Failed to copy config to bpp-client"
    #     return 1
    }
    __besman_echo_white "Sleep for 10"
    sleep 10
    __besman_echo_white "Restarting containers"
    docker restart bap-client bap-network bpp-network bpp-client || {
        __besman_echo_red "Failed to restart containers"
        return 1
    }
    
    __besman_echo_green "Copied layer2 config files"
    return 0
}
function __besman_update_cors_and_config() {
    
    __besman_echo_white "Updating CORS and config"

    local seller_cors_file="$BESMAN_SELLER_APP_DIR/seller/app/config/environments/base/env.cors.js"
    local seller_env_file="$BESMAN_SELLER_APP_DIR/seller/.env"
    local seller_api_config="$BESMAN_SELLER_APP_DIR/seller-app-api/lib/config/production_env_config.json"


    if [[ -f $seller_env_file ]] 
    then
        sed -i "s|OPENFORT_SELLER_APP=.*|OPENFORT_SELLER_APP=$BESMAN_IP_ADDRESS:3008|g" "$seller_env_file"

    else
        __besman_echo_red "Seller env file not found"
        return 1
    fi

    [[ -f $seller_cors_file ]] && rm "$seller_cors_file"
    touch "$seller_cors_file"

    cat <<EOF >"$seller_cors_file"
module.exports = {
    'cors': {
        'whitelistUrls': [
            '*',
            '$BESMAN_IP_ADDRESS'
        ]
    }
};
EOF

    [[ -f $seller_api_config ]] && rm "$seller_api_config"
    touch "$seller_api_config"
    cat <<EOF >"$seller_api_config"
{
  "express": {
    "protocol": "http://",
    "useFqdnForApis": false,
    "ipAddress": "strapi",
    "fqdn": "",
    "port": 3001,
    "apiUrl": ""
  },
  "auth": {
    "token": {
      "access": {
        "exp": 8640000,
        "secret": "wftd3hg5$g67h*fd5h6fbvcy6rtg5wftd3hg5$g67h*fd5xxx"
      },
      "resetPasswordLink": {
        "exp": 86400,
        "secret": "de$rfdf5$g67*jhu*sdfbvcy3frd6r4e"
      }
    }
  },
  "database": {
    "username": "strapi",
    "password": "strapi",
    "name": "sellerapp",
    "host": "postgres",
    "port": "5432",
    "dialect": "postgres",
    "pool": {
      "max": 60,
      "min": 0,
      "acquire": 1000000,
      "idle": 10000,
      "evict": 10000
    }
  },
  "email": {
    "transport": {
      "SMTP": {
        "host": "",
        "port": 587,
        "secure": false,
        "auth": {
          "user": "",
          "pass": ""
        }
      },
      "local": {
        "sendmail": true,
        "newline": "unix",
        "path": "/usr/sbin/sendmail"
      }
    },
    "sender": "",
    "supportEmail": "",
    "webClientUri": "http://34.123.120.224",
    "shareUrl": "https://www.google.com"
  },
  "cors": {
    "whitelistUrls": [
      "http://strapi:3001",
      "$BESMAN_IP_ADDRESS"
    ]
  },
  "directory": {
    "profilePictures": "PROFILE_PICTURES"
  },
  "cookieOptions": {
    "httpOnly": true,
    "secure": false,
    "sameSite": false
  },
  "general": {
    "exceptionEmailRecipientList": []
  },
  "seller": {
    "serverUrl": "http://seller:3008"
  },
  "firebase": {
    "account": ""
  },
  "sellerConfig": {
    "BPP_ID": "sellerapp-staging.datasyndicate.in",
    "BPP_URI": "$BESMAN_IP_ADDRESS:6001",
    "BAP_ID": "sellerapp-staging.datasyndicate.in",
    "BAP_URI": "https://7e3b-2401-4900-1c5d-2b13-814b-de08-9df3-b44e.ngrok-free.app",
    "storeOpenSchedule": {
      "time": {
        "days": "1,2,3,4,5,6,7",
        "schedule": {
          "holidays": [
            "2022-08-15",
            "2022-08-19"
          ],
          "frequency": "PT4H",
          "times": [
            "1100",
            "1900"
          ]
        },
        "range": {
          "start": "1100",
          "end": "2100"
        }
      }
    },
    "sellerPickupLocation": {
      "person": {
        "name": "Ramu"
      },
      "location": {
        "gps": "12.938382, 77.651775",
        "address": {
          "area_code": "560087",
          "name": "Fritoburger",
          "building": "12 Restaurant Tower",
          "locality": "JP Nagar 24th Main",
          "city": "Bengaluru",
          "state": "Karnataka",
          "country": "India"
        }
      },
      "contact": {
        "phone": "98860 98860",
        "email": "abcd.efgh@gmail.com"
      }
    }
  },
  "settlement_details": [
    {
      "settlement_counterparty": "buyer-app",
      "settlement_type": "upi",
      "upi_address": "gft@oksbi",
      "settlement_bank_account_no": "XXXXXXXXXX",
      "settlement_ifsc_code": "XXXXXXXXX"
    }
  ]
}
EOF

    # If any of the above files are not present, return an error
    if [[ ! -f $seller_cors_file ]] || [[ ! -f $seller_api_config ]]; then
        __besman_echo_red "Failed to update CORS and config"
        return 1
    fi

}

function __besman_install_seller_app() {

    __besman_echo_yellow "Installing seller app"
    if [[ -d $BESMAN_SELLER_APP_DIR ]] 
    then
        __besman_echo_no_colour "Found seller app source code"

    else
        __besman_echo_white "Cloning seller app source code"
        __besman_repo_clone "$BESMAN_ORG" "$BESMAN_SELLER_APP_SOURCE_REPO" "$BESMAN_SELLER_APP_DIR" || return 1
    fi

    cd "$BESMAN_SELLER_APP_DIR" || return 1

    __besman_update_cors_and_config || return 1

    __besman_echo_white "Building seller app"
    docker-compose up --build -d

}

# function __besman_install_ossverse_network() {
  # TODO
# }

function __besman_install {
    # Checks if git/GitHub CLI is present or not.
    __besman_check_vcs_exist || return 1
    # # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    # __besman_check_github_id || return 1
    __besman_install_docker
    __besman_install_docker_compose
    __besman_install_buyer_ui || return 1
    __besman_install_buyer_app || return 1
    __besman_install_beckn_onix || return 1
    __besman_install_ossverse_network || return 1
    # __besman_copy_layer2_config || return 1
    __besman_install_seller_app || return 1
    # __besman_install_seller_ui || return 1 # TODO
}

function __besman_uninstall {
    __besman_echo_white "Stopping and removing Docker containers..."

    docker stop $(docker ps -a -q)
    docker container rm $(docker ps -a -q)

    __besman_echo_white "Removing Docker images and volumes..."
    docker image rm $(docker image ls -q)
    docker volume rm $(docker volume ls -q)

    __besman_echo_white "Cleaning up directories..."
    if [[ -d $BESMAN_OIAB_BUYER_UI_DIR ]]; then
        rm -rf "$BESMAN_OIAB_BUYER_UI_DIR"
        __besman_echo_yellow "Removed buyer UI directory"
    fi

    if [[ -d $BESMAN_OIAB_BUYER_APP_DIR ]]; then
        rm -rf "$BESMAN_OIAB_BUYER_APP_DIR"
        __besman_echo_yellow "Removed buyer app directory"
    fi

    # remove beckn-onix dir
    if [[ -d $BESMAN_BECKN_ONIX_DIR ]]; then
        rm -rf "$BESMAN_BECKN_ONIX_DIR"
        __besman_echo_yellow "Removed beckn-onix directory"
    fi

    # remove oasp-seller-app dir
    if [[ -d $BESMAN_OASP_SELLER_DIR ]]; then
        rm -rf "$BESMAN_OASP_SELLER_DIR"
        __besman_echo_yellow "Removed oasp-seller-app directory"
    fi
}

# function __besman_update
# {
#     # TODO: Implement update logic
# }

# function __besman_validate
# {
#     # TODO: Implement validate logic
# }

# function __besman_reset
# {
#     # TODO: Implement reset logic
# }
