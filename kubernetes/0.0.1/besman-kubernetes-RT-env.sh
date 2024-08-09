#!/bin/bash
function __besman_validate {

    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1 
    __besman_detect_container_runtime || return 1
    __besman_generate_state
    __besman_check_python_installation || return 1
    __besman_generate_state
    __besman_check_go_installation || return 1
    __besman_generate_state
    __besman_check_tools || return 1
    __besman_generate_state
    __besman_check_container_tools || return 1


}

function __besman_install {

    __besman_detect_system

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

    snap install yq

    # Install Container Runtime 
    __besman_echo_white  "\n Installing Container Runtime"
    __besman_install_container_runtime || return 1
    __besman_echo_white  "\n Installing golang"
    __besman_check_Install_go || return 1
    __besman_echo_white  "\n Installing Python3 and PIP"
    __besman_install_python_pip_linux || return 1
    __besman_echo_white  "\n Setting Up Containerised Tools"
    __besman_container_tool_setup sonarqube 9000 9000 || return 1
    __besman_container_tool_setup fosology 8081 80 || return 1
    __besman_echo_white  "\n Installing Snyk"
    __besman_Install_snyk || return 1
    __besman_echo_white  "\n All set-up for Kubernetes, Enjoy Hacking K8s !"
}

function __besman_uninstall {
    
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi

    __besman_stop_containers || return 1
    __besman_remove_containers || return 1
    __besman_purge_containers || return 1
    __besman_uninstall_container_runtime || return 1
    __besman_uninstall_tools || return 1
    __besman_echo_white  "We have cleaned up Your WorkSpace"

}

function __besman_update {
    __besman_update_container_runtime  || return 1
    __besman_update_python_installation  || return 1
    __besman_update_go_installation || return 1
    __besman_update_tools || return 1
    __besman_update_container_tools  || return 1

}



function __besman_reset {

    __besman_reset_container_runtime  || return 1
    __besman_reset_python_installation  || return 1
    __besman_reset_go_installation || return 1
    __besman_reset_tools || return 1
    __besman_reset_container_tools  || return 1

}

__besman_detect_system(){

    BESMAN_SYSTEM=""

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        __besman_echo_white  "This is a Linux operating system: $NAME $VERSION_ID"
        export BESMAN_SYSTEM="$ID"

    elif [ "$(uname -o)" == "Darwin" ]; then
        __besman_echo_white "This is macOS: $(sw_vers -productName) $(sw_vers -productVersion)"
        export BESMAN_SYSTEM="mac"
    else
        case "$(uname -o)" in
            MINGW*|MSYS*|CYGWIN*)
                export BESMAN_SYSTEM="windows"
                ;;
            *)
                __besman_echo_white  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
                exit 1
                ;;
        esac
    fi
}

__besman_detect_container_runtime() {

        # Check if Container Runtime is installed

        __besman_echo_white  "\n Looking for Container runtime.."

        export container_runtime=""

        if command -v podman &>/dev/null; then
            __besman_echo_white  "\n PODMAN Detected. "
            export Container_runtime="podman"

            # Installing PODMAN in Linux

            if podman info 2>&1 | grep -q "Error: unable to connect to Podman"; then
                    __besman_echo_white  "\n PODMAN needs to be initialised. Initializing.."

                    podman machine start podman-machine-default
                    podman machine init
                    sleep 30

                    while true; do
                        if podman info 2>&1 | grep -q "Machine init complete"; then
                            __besman_echo_white  "\n Podman is Ready ! \n"
                            break
                        fi
                        sleep 1
                    done

            fi

        elif command -v docker &>/dev/null; then
            __besman_echo_white  "\n Docker is  Detected. "
            export Container_runtime="docker"
        else
            __besman_echo_white  "\n No Container Runtime detected ! Will be installed"
            install_container_runtime
        fi
}

__besman_check_python_installation(){

if ! command -v python3 &>/dev/null || ! command -v pip3 &>/dev/null; then
            __besman_echo_white "\n Python 3 and PiP are not Found. Will be Installed"
        else
            __besman_echo_white  "\n Python 3 and pip are already installed."
        fi
        
}

__besman_install_container_runtime() {

    if [$BESMAN_SYSTEM == "linux"]; then
        __besman_install_podman_linux
 
    else if $BESMAN_SYSTEM == "darwin"
            if ! command -v brew &>/dev/null; then
                __besman_echo_white  "\n Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
        __besman_install_podman_mac

    else if $BESMAN_SYSTEM == "windows"
            if ! command -v choco &>/dev/null; then
                __besman_echo_white  "\n We Use Chocolatey to install Package On Windows. You may install Chocolatey from https://chocolatey.org/install"
                exit 1
            fi
        __besman_install_podman_windows
    fi
            __besman_echo_white  "\n Podman installation complete !"
    }

        

    __besman_install_python_pip_linux() {

        case "$BESMAN_SYSTEM" in
            ubuntu|debian)
                sudo apt-get update
                sudo apt-get -y install python3 python3-pip
                __besman_echo_white "\n python3 and python3-pip Installed"
                ;;
            fedora)
                sudo dnf -y install python3 python3-pip
                __besman_echo_white "\n python3 and python3-pip Installed"
                ;;
            centos|rhel)
                sudo yum -y install python3 python3-pip
                __besman_echo_white "\n python3 and python3-pip Installed"
                ;;
            *)
                __besman_echo_white  "\n Sorry ! Could not recognise your Linux System ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
                exit 1
                ;;
        esac
    }

    __besman_install_python_pip_mac() {
        if ! command -v brew &>/dev/null; then
            __besman_echo_white  "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        brew install python3 pip3
        __besman_echo_white "\n python3 and python3-pip Installed"
    }

    __besman_install_python_pip_windows() {
        if ! command -v choco &>/dev/null; then
            __besman_echo_white  "\n Chocolatey not found. Please install Chocolatey from https://chocolatey.org/install"
            exit 1
        fi
        choco install -y python3 pip3
        __besman_echo_white "\n python3 and python3-pip Installed"
    }
        
__besman_container_tool_setup(){

        local container_toolname="$1"
        local container_port="$2"
        local port_forwad_port="$3"

        check_container_status() {

        # Check the status of SonarQube container

        if $container_runtime inspect $container_toolname &>/dev/null; then
            __besman_echo_white  "\n "$container_toolname" container exists."

            container_status=$($container_runtime inspect --format='{{.State.Status}}' $container_toolname)

            if [ "$container_status" == "running" ]; then

                __besman_echo_white  "\n $container_toolname container is running."

                __besman_print_container_url

            else
                __besman_echo_white  "\n $container_toolname container is not running. Current status: $container_status"
            fi
            
        else
            __besman_echo_white  "\n $container_toolname container does not exist. Installing Now."
            __besman_install_container
        fi

            }

        __besman_install_container(){

            __besman_echo_white  "\n Pulling $container_toolname image..."
            $container_runtime pull $container_toolname:latest

            __besman_echo_white  "\n Running $container_toolname container..."
            $container_runtime run -d --name $container_toolname -p $container_port:$port_forwad_port $container_toolname:latest
            __besman_print_container_url
        }

        __besman_print_container_url()  {       
        container_ip=$("$Container_runtime" inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_toolname")

        # Print the SonarQube server URL

        __besman_echo_white  "\n You $container_runtime server is running at http://$container_ip:$port_forwad_port"

        }
    }


__besman_install_podman_linux() {
    
    case "$BESMAN_SYSTEM" in
        ubuntu|debian)
            sudo apt-get update
            sudo apt-get -y install podman
            __besman_echo_white "\n PODMAN Installed"
            ;;
        fedora)
            sudo dnf -y install podman
            __besman_echo_white "\n PODMAN Installed"
            ;;
        centos|rhel)
            sudo yum -y install podman
            __besman_echo_white "\n PODMAN Installed"
            ;;
        *)
            __besman_echo_red  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
            exit 1
            ;;
    esac
}

# Installing PODMAN in Mac
__besman_install_podman_mac() {
    brew install podman
}


__besman_install_podman_windows() {
    choco install podman
}

__besman_generate_state() {

local file_path="besman-kubernetes-RT-env-config.yaml"

if [ -f "$file_path" ]; then
    # Check if BESMAN_ASSESSMENT_REQUIREMENTS: exists in the file
    if grep -q "BESMAN_SYSTEM_STATE:" "$file_path"; then
        # Append the scorecard content under BESMAN_ASSESSMENT_REQUIREMENTS with proper indentation
        awk '/BESMAN_SYSTEM_STATE:/ {print; print "  '$toolName:'"; print "    PORT: '$toolPort'"; print "    VERSION: '$toolVersion'"; print "    INSTALLATION: '$toolInstallation'"; next}1' "$file_path" >> "$file_path"

        echo "Successfully added Your current machine status to $file_path"
    else
        # Add BESMAN_ASSESSMENT_REQUIREMENTS section with scorecard content
        cat <<EOF >> "$file_path"
BESMAN_SYSTEM_STATE:
  $toolName:
    port: $toolPort
    version: $toolVersion
    installation: $toolInstallation
EOF
        __besman_echo_White "Successfully added BESMAN_SYSTEM_STATE section to $file_path"
    fi
else
    __besman_echo_red  "\n File $file_path does not exist."
fi
}