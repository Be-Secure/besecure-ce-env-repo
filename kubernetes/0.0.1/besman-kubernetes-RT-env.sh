#!/bin/bash
function __besman_install {

    __besman_check_vcs_exist || return 1   # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1   # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    __besman_create_roles_config_file      # Creates the role config file with the parameters from env config

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

    __besman_detect_container_runtime

    # Install Container Runtime 

    __besman_install_container_runtime

    # Python3 and PIP Installation :

    __besman_check_and_install_python_pip

    __besman_echo_white  "\n Setting Up Container Tools"

    __besman_container_tool_setup sonarqube 9000 9000

    __besman_container_tool_setup fosology 8081 80

    # Setup Go-lang 
    
    __besman_golang_setup()

    # go is required to install criticality_score


    # Setup snyk

    __besman_echo_white  "\n All set-up for Kubernetes, Enjoy Hacking K8s !"
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

    # # Uninstall Containers
    # stop_containers() {

    #     # to be added Do not Review this function
    
    # }
    # remove_containers(){

    #         # to be added Do not Review this function

    # }
    # purge_containers(){

    #         # to be added Do not Review this function

    # }


    # # Function to uninstall Docker

    # uninstall_container() {

    #         # to be added Do not Review this function

    # }

    __besman_echo_white  "We have cleaned up Your WorkSpace"

}

function __besman_update {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for update

    # update_tools (){
    #         # to be added Do not Review this function
    # }

}

function __besman_validate {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for validate

# validate_required_tools (){
#         # to be added Do not Review this function
#         }


}

function __besman_reset {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for reset

    # reset_required_tools (){
    #     # to be added Do not Review this function
    #     }

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
            __besman_echo_white  "\n No Container Runtime detected. Installing a Container Runtime !"
            install_container_runtime
        fi
}

__besman_install_container_runtime() {


    case "$(uname -s)" in
                Linux*)
                    __besman_install_podman_linux
                    ;;
                Darwin*)
                    if ! command -v brew &>/dev/null; then
                        __besman_echo_white  "\n Homebrew not found. Installing Homebrew..."
                        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                    fi
                    install_podman_mac
                    ;;
                MINGW*|MSYS*|CYGWIN*)
                    if ! command -v choco &>/dev/null; then
                        __besman_echo_white  "\n We Use Chocolatey to install Package On Windows. You may install Chocolatey from https://chocolatey.org/install"
                        exit 1
                    fi
                    __besman_install_podman_windows
                    ;;
                *)
                    __besman_echo_white  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
                    exit 1
                    ;;
            esac

            __besman_echo_white  "\n Podman installation complete !"

            # Installing PODMAN in Linux
            __besman_install_podman_linux() {
                

                . /etc/os-release
                case "$ID" in
                    ubuntu|debian)
                        sudo apt-get update
                        sudo apt-get -y install podman
                        ;;
                    fedora)
                        sudo dnf -y install podman
                        ;;
                    centos|rhel)
                        sudo yum -y install podman
                        ;;
                    *)
                        __besman_echo_white  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
                        exit 1
                        ;;
                esac
            }
            # Installing PODMAN in Mac
            __besman_install_podman_mac() {
                brew install podman
            }
            # Installing PODMAN in Windows:
            __besman_install_podman_windows() {
                choco install podman
            }

                

    }

__besman_check_and_install_python_pip() {
        if ! command -v python3 &>/dev/null || ! command -v pip3 &>/dev/null; then
            case "$(uname -s)" in
                Linux*)
                    __besman_install_python_pip_linux
                    ;;
                Darwin*)
                    __besman_install_python_pip_mac
                    ;;
                MINGW*|MSYS*|CYGWIN*)
                    __besman_install_python_pip_windows
                    ;;
                *)
                    __besman_echo_white  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
                    exit 1
                    ;;
            esac
        else
            __besman_echo_white  "\n Python 3 and pip are already installed."
        fi
        }

        __besman_install_python_pip_linux() {
            . /etc/os-release
            case "$ID" in
                ubuntu|debian)
                    sudo apt-get update
                    sudo apt-get -y install python3 python3-pip
                    ;;
                fedora)
                    sudo dnf -y install python3 python3-pip
                    ;;
                centos|rhel)
                    sudo yum -y install python3 python3-pip
                    ;;
                *)
                    __besman_echo_white  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
                    exit 1
                    ;;
            esac
        }

        __besman_install_python_pip_mac() {
            if ! command -v brew &>/dev/null; then
                __besman_echo_white  "Homebrew not found. Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install python
        }

        __besman_install_python_pip_windows() {
            if ! command -v choco &>/dev/null; then
                __besman_echo_white  "\n Chocolatey not found. Please install Chocolatey from https://chocolatey.org/install"
                exit 1
            fi
            choco install -y python
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
