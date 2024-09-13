#!/bin/bash
# Author:samir Ranjan Parhi (samirparhi@gmail.com)
# Last modified Datae: 9th Sept 2024
# Description: This shell script creates a BES environment for k8s 

function __besman_validate {
    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1
    __besman_detect_system|| return 1 ### BESMAN_SYSTEM
    __besman_check_package_manger || return 1
    __besman_install_tools yq "" "" "" "" || return 1
    export BESMAN_K8S_CONFIG_FILE_PATH="./$BESMAN_ARTIFACT_NAME/$BESMAN_ARTIFACT_VERSION/besman-kubernetes-RT-env-config.yaml"
}

function __besman_install {

    local tool_name
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

    for tool_name in $(yq eval '.required_tool_set | keys' "$BESMAN_K8S_CONFIG_FILE_PATH"); do
        local tool_version=$(yq eval '.required_tool_set."$tool_name".version' "$BESMAN_K8S_CONFIG_FILE_PATH")
        local tool_type= $(yq eval '.required_tool_set."$tool_name".type' "$BESMAN_K8S_CONFIG_FILE_PATH")
        local port=$(yq eval '.required_tool_set."$tool_name".port' "$BESMAN_K8S_CONFIG_FILE_PATH")
        local port_fwd=$(yq eval '.required_tool_set."$tool_name".port_fwd' "$BESMAN_K8S_CONFIG_FILE_PATH")
        __besman_check_tools_check  "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd" || return 1
    done
    __besman_echo_white  "\n All set-up for cilium !"
}

function __besman_uninstall {

    local tool_name
    
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi
    
        for tool_name in $(yq eval '.required_tool_set | keys' "$BESMAN_K8S_CONFIG_FILE_PATH"); do
            local tool_version=$(yq eval '.required_tool_set."$tool_name".version' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local tool_type= $(yq eval '.required_tool_set."$tool_name".type' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local port=$(yq eval '.required_tool_set."$tool_name".port' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local port_fwd=$(yq eval '.required_tool_set."$tool_name".port_fwd' "$BESMAN_K8S_CONFIG_FILE_PATH")
            if [ "$tool_type" != "container" ]; then
                __besman_uninstall_tool  "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd" || return 1
            else 
                __besman_uninstall_container_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd" || return 1
        done
    __besman_echo_white  "We have cleaned up $tool_name"

    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi
    __besman_echo_white  "We have cleaned up Your WorkSpace"

}

function __besman_update {

    local tool_name

    for tool_name in $(yq eval '.required_tool_set | keys' "$BESMAN_K8S_CONFIG_FILE_PATH"); do
        local tool_version=$(yq eval '.required_tool_set."$tool_name".version' "$BESMAN_K8S_CONFIG_FILE_PATH")
        local tool_type= $(yq eval '.required_tool_set."$tool_name".type' "$BESMAN_K8S_CONFIG_FILE_PATH")
        local port=$(yq eval '.required_tool_set."$tool_name".port' "$BESMAN_K8S_CONFIG_FILE_PATH")
        local port_fwd=$(yq eval '.required_tool_set."$tool_name".port_fwd' "$BESMAN_K8S_CONFIG_FILE_PATH")
        __besman_check_tools_check "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd" || return 1
    done
    __besman_echo_white  "\n your Environment is Updated for cilium !"

}

function __besman_reset {

    local tool_name
        for tool_name in $(yq eval '.current_system_state | keys' "$BESMAN_K8S_CONFIG_FILE_PATH"); do
            local tool_version=$(yq eval '.current_system_state."$tool_name".version' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local tool_type= $(yq eval '.current_system_state."$tool_name".type' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local port=$(yq eval '.current_system_state."$tool_name".port' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local port_fwd=$(yq eval '.current_system_state."$tool_name".port_fwd' "$BESMAN_K8S_CONFIG_FILE_PATH")
            if [ "$tool_type" != "container" ]; then
                __besman_uninstall_container_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd" || return 1
                __besman_uninstall_tool  "$tool_name" || return 1  
        done
    
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
        rm -rf "$BESMAN_ARTIFACT_DIR"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
    fi
    __besman_echo_white  "We have cleaned up Your WorkSpace"

}



__besman_detect_system(){

    export BESMAN_SYSTEM=""
    
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

__besman_check_package_manger(){

    case "$BESMAN_SYSTEM" in
        "Debian" | "Ubuntu")
            __besman_echo_white "\n Checking for Package manage"
            if command -v apt &> /dev/null; then
                __besman_echo_white "apt is installed."
            else
                __besman_echo_white "apt is not installed."
            fi
            ;;
        "CentOS" | "RHEL")
            __besman_echo_white "\n Checking for Package manage"
            if command -v dnf &> /dev/null; then
                __besman_echo_white "dnf is installed."
            elif command -v yum &> /dev/null; then
                __besman_echo_white "yum is installed."
            else
                __besman_echo_white "Neither dnf nor yum is installed."
            fi
            ;;
        "Arch")
            __besman_echo_white "\n Checking for Package manager"
            if command -v pacman &> /dev/null; then
                __besman_echo_white "pacman is installed."
            else
                __besman_echo_white "pacman is not installed."
            fi
            ;;
         "mac")
            __besman_echo_white "\n Checking for Package manager"
            if command -v brew  &> /dev/null; then
                __besman_echo_white "brew is installed."
            else
                __besman_echo_white "\n brew is not installed. Installing.."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                __besman_echo_white "\n brew is installed"

            fi
            ;;
        "windows")
            __besman_echo_white "\n Checking for Package manage"
            if command -v scoop &> /dev/null; then
                __besman_echo_white "scoop is installed."
            else
                __besman_echo_white "Scoop is not installed.Installing.."
            fi
            ;;
        *)
            __besman_echo_white  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
            exit 1
            ;;
    esac

}

__besman_check_tools_check() {
    local tool_name ="$1"
    local tool_version ="$2"
    local tool_type= "$3"
    local port="$4"
    local port_fwd="$5"
    
        case "$BESMAN_SYSTEM" in
            "Debian" | "Ubuntu")
                if ! ! apt list --installed 2>/dev/null | grep -q "^$tool_name/";then
                    __besman_install_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                fi
                ;;
            "CentOS" | "RHEL")
                if ! rpm -q "$tool" &> /dev/null; then
                    __besman_install_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                fi
                ;;
            "Arch")
                if ! pacman -Qi "$tool" &> /dev/null; then
                    __besman_install_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                fi
                ;;
            "mac")
                if ! brew list "$tool" &> /dev/null; then
                    __besman_install_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                fi
                ;;
            "windows")
                if ! scoop list "$tool" &> /dev/null; then
                    __besman_install_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                fi
                ;;
            *)
                __besman_echo_white  "\n Sorry ! Wecould not recognise your OS ! \n Dont worry, Let us know your operating sytem , we will improve it :-) operating system."
                return 1
                ;;
        esac
}


__besman_install_tool() {
    local tool_name="$1"
    local tool_version="$2"
    local tool_type="$3" 
    local port="$4" 
    local port_fwd="$5"
    if [ "$tool_type" != "container" ]; then
            case "$BESMAN_SYSTEM" in
                "Debian" | "Ubuntu")
                    if [ -n "$tool_version" ]; then
                        sudo apt update && sudo apt install -y "$tool_name=$tool_version"
                    else
                        sudo apt update && sudo apt install -y "$tool_name"
                    fi
                    if [ $? -eq 0 ]; then
                        __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                    else
                        __besman_echo_white "\n Installation of $tool_name failed."
                        return 1
                    fi
                    ;;
                "CentOS" | "RHEL")
                    if [ -n "$tool_version" ]; then
                        sudo yum install -y "$tool_name-$tool_version"
                    else
                        sudo yum install -y "$tool_name"
                    fi
                    if [ $? -eq 0 ]; then
                        __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                    else
                        __besman_echo_white "\n Installation of $tool_name failed."
                        return 1
                    fi
                    ;;
                "Arch")
                    if [ -n "$tool_version" ]; then
                        sudo pacman -S --noconfirm "$tool_name=$tool_version"
                    else
                        sudo pacman -S --noconfirm "$tool_name"
                    fi
                    if [ $? -eq 0 ]; then
                        __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                    else
                        __besman_echo_white "\n Installation of $tool_name failed."
                        return 1
                    fi
                    ;;
                "mac")
                    if [ -n "$tool_version" ]; then
                        brew install "$tool_name@$tool_version"
                    else
                        brew install "$tool_name"
                    fi
                    if [ $? -eq 0 ]; then
                        __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                    else
                        __besman_echo_white "\n Installation of $tool_name failed."
                        return 1
                    fi
                    ;;
                "windows")
                    if [ -n "$tool_version" ]; then
                        scoop install "$tool_name@$tool_version"
                    else
                        scoop install "$tool_name"
                    fi
                    if [ $? -eq 0 ]; then
                        __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                    else
                        __besman_echo_white "\n Installation of $tool_name failed."
                        return 1
                    fi
                    ;;
                *)
                    __besman_echo_white "\n Sorry! We could not recognize your OS! \n Let us know your operating system, and we will improve it :-)"
                    return 1
                    ;;
            esac
        else
            __besman_echo_white "\n Tool type is 'container'; Progressing with Container mode."
            __besman_install_container_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
        fi
}

__besman_install_container_tool() {
    local container_tool_name="$1"
    local tool_version="$2"
    local tool_type="$3"
    local port="$4"
    local port_fwd="$5"
    
    __besman_detect_container_runtime || return 1

    # Check the container status
    __besman_check_container_status "$container_tool_name"
    local status=$?

    if [ $status -eq 0 ]; then
        __besman_echo_white "\n Container $container_tool_name is already running. Skipping installation."
        return 0
    elif [ $status -eq 1 ]; then
        __besman_echo_white "\n Container $container_tool_name exists but is not running. Installing now."
    elif [ $status -eq 2 ]; then
        __besman_echo_white "\n Container $container_tool_name does not exist. Proceeding with installation."
    else
        __besman_echo_white "\n Unexpected status returned from __besman_check_container_status."
        return 1
    fi

    __besman_echo_white "\n Pulling $container_tool_name image..."
    $BESMAN_CONTAINER_RUNTIME pull $container_tool_name:$tool_version

    __besman_echo_white "\n Running $container_tool_name container..."
    $BESMAN_CONTAINER_RUNTIME run -d --name $container_tool_name -p $port:$port_fwd $container_tool_name:$tool_version

    if [ $? -eq 0 ]; then
        __besman_print_container_url
        __besman_generate_state "$container_tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
    else
        __besman_echo_white "\n Installation of $container_tool_name failed."
        return 1
    fi
}

__besman_uninstall_container_tool() {
    local container_tool_name="$1"
    local tool_version="$2"
    local tool_type="$3"
    local port="$4"
    local port_fwd="$5"
    
    __besman_detect_container_runtime || return 1

    # Check the container status
    __besman_check_container_status "$container_tool_name"
    local status=$?

    if [ $status -eq 2 ]; then
        __besman_echo_white "\n Container $container_tool_name does not exist. Skipping uninstallation."
        return 0
    elif [ $status -eq 1 ]; then
        __besman_echo_white "\n Container $container_tool_name is not running, proceeding with removal."
        $BESMAN_CONTAINER_RUNTIME rm $container_tool_name
        $BESMAN_CONTAINER_RUNTIME rmi $container_tool_name
        $BESMAN_CONTAINER_RUNTIME system prune -a
    elif [ $status -eq 0 ]; then
        __besman_echo_white "\n Stopping $container_tool_name container..."
        $BESMAN_CONTAINER_RUNTIME stop $container_tool_name

        if [ $? -ne 0 ]; then
            __besman_echo_white "\n Failed to stop $container_tool_name container."
            return 1
        fi
    else
        __besman_echo_white "\n Unexpected status returned from __besman_check_container_status."
        return 1
    fi

    __besman_echo_white "\n Removing $container_tool_name container..."
    $BESMAN_CONTAINER_RUNTIME rm $container_tool_name

    if [ $? -eq 0 ]; then
        __besman_echo_white "\n $container_tool_name container successfully removed."
        __besman_remove_state "$container_tool_name"
    else
        __besman_echo_white "\n Failed to remove $container_tool_name container."
        return 1
    fi

    __besman_echo_white "\n Removing $container_tool_name image..."
    $BESMAN_CONTAINER_RUNTIME rmi $container_tool_name:$tool_version

    if [ $? -eq 0 ]; then
        __besman_echo_white "\n $container_tool_name image successfully removed."
    else
        __besman_echo_white "\n Failed to remove $container_tool_name image."
        return 1
    fi
}


__besman_uninstall_tool() {
    local tool_name="$1"
    local tool_version="$2"
    local tool_type="$3"
    local port="$4"
    local port_fwd="$5"
    
    if [ "$tool_type" != "container" ]; then
        case "$BESMAN_SYSTEM" in
            "Debian" | "Ubuntu")
                if [ -n "$tool_version" ]; then
                    sudo apt remove -y "$tool_name=$tool_version"
                else
                    sudo apt remove -y "$tool_name"
                fi
                if [ $? -eq 0 ]; then
                    __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                else
                    __besman_echo_white "\n Uninstallation of $tool_name failed."
                    return 1
                fi
                ;;
            "CentOS" | "RHEL")
                if [ -n "$tool_version" ]; then
                    sudo yum remove -y "$tool_name-$tool_version"
                else
                    sudo yum remove -y "$tool_name"
                fi
                if [ $? -eq 0 ]; then
                    __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                else
                    __besman_echo_white "\n Uninstallation of $tool_name failed."
                    return 1
                fi
                ;;
            "Arch")
                if [ -n "$tool_version" ]; then
                    sudo pacman -R --noconfirm "$tool_name=$tool_version"
                else
                    sudo pacman -R --noconfirm "$tool_name"
                fi
                if [ $? -eq 0 ]; then
                    __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                else
                    __besman_echo_white "\n Uninstallation of $tool_name failed."
                    return 1
                fi
                ;;
            "mac")
                if [ -n "$tool_version" ]; then
                    brew uninstall "$tool_name@$tool_version"
                else
                    brew uninstall "$tool_name"
                fi
                if [ $? -eq 0 ]; then
                    __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                else
                    __besman_echo_white "\n Uninstallation of $tool_name failed."
                    return 1
                fi
                ;;
            "windows")
                if [ -n "$tool_version" ]; then
                    scoop uninstall "$tool_name@$tool_version"
                else
                    scoop uninstall "$tool_name"
                fi
                if [ $? -eq 0 ]; then
                    __besman_generate_state "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
                else
                    __besman_echo_white "\n Uninstallation of $tool_name failed."
                    return 1
                fi
                ;;
            *)
                __besman_echo_white "\n Sorry! We could not recognize your OS! \n Let us know your operating system, and we will improve it :-)"
                return 1
                ;;
        esac
    else
        __besman_echo_white "\n Tool type is 'container'; Progressing with Container mode."
        __besman_uninstall_container_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
    fi
}



__besman_detect_container_runtime() {

        # Check if Container Runtime is installed

        __besman_echo_white  "\n Looking for Container runtime.."

        export BESMAN_CONTAINER_RUNTIME=""

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
            export BESMAN_CONTAINER_RUNTIME="docker"
        else
            __besman_echo_white  "\n No Container Runtime detected ! Will be installed"
            local toolname = "$BESMAN_CONTAINER_RUNTIME"
            local tool_version=$(yq eval '.required_tool_set."$toolname".version' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local tool_type= $(yq eval '.required_tool_set."$toolname".type' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local port=$(yq eval '.required_tool_set."$toolname".port' "$BESMAN_K8S_CONFIG_FILE_PATH")
            local port_fwd=$(yq eval '.required_tool_set."$toolname".port_fwd' "$BESMAN_K8S_CONFIG_FILE_PATH")
            
            __besman_install_tool "$tool_name" "$tool_version" "$tool_type" "$port" "$port_fwd"
        fi
}

__besman_check_container_status() {

    local container_tool_name="$1"

    if $BESMAN_CONTAINER_RUNTIME inspect $container_tool_name &>/dev/null; then
        __besman_echo_white  "\n $container_tool_name container exists."

        container_status=$($BESMAN_CONTAINER_RUNTIME inspect --format='{{.State.Status}}' $container_tool_name)

        if [ "$container_status" == "running" ]; then
            __besman_echo_white  "\n $container_tool_name container is running."
            __besman_print_container_url "$container_tool_name"
            return 0
        else
            __besman_echo_white  "\n $container_tool_name container is not running. Current status: $container_status"
            return 1
        fi
    else
        __besman_echo_white  "\n $container_tool_name container does not exist. Installing now."
        return 2
    fi
}


__besman_print_container_url()  {   
    local container_tool_name="$1"    
    container_ip=$("$BESMAN_CONTAINER_RUNTIME" inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_tool_name")
    __besman_echo_white  "\n You $container_runtime server is running at http://$container_ip:$port_forwad_port"

}

__besman_generate_state() {
    # Check if BESMAN_SYSTEM_INITIAL_STATE exists, initialize if not
    local tool_name="$1"
    local tool_version="$2"
    local tool_type="$3"
    local port = "$4"
    local port_fwd="$5"

    if ! yq eval '.current_system_state' "$BESMAN_K8S_CONFIG_FILE_PATH" &> /dev/null; then
        yq eval -i '.current_system_state = {}' "$BESMAN_K8S_CONFIG_FILE_PATH"
    fi

    # Append or update the tool in BESMAN_SYSTEM_INITIAL_STATE
    yq eval -i ".current_system_state.$tool_name = {\"version\": \"$tool_version\", \"installation\": \"$tool_type\", \"port\": \"$port\", \"port_fwd\": \"$port_fwd\" }" "$BESMAN_K8S_CONFIG_FILE_PATH"

}

__besman_remove_state() {
    local tool_name="$1"

    if ! yq eval '.current_system_state' "$BESMAN_K8S_CONFIG_FILE_PATH" &> /dev/null; then
        __besman_echo_white "\nNo state found for removal in current_system_state."
        return 1
    fi

    if ! yq eval ".current_system_state.$tool_name" "$BESMAN_K8S_CONFIG_FILE_PATH" &> /dev/null; then
        __besman_echo_white "\nNo entry found for tool: $tool_name."
        return 1
    fi

    yq eval -i "del(.current_system_state.$tool_name)" "$BESMAN_K8S_CONFIG_FILE_PATH"

    # Verify the removal
    if yq eval ".current_system_state.$tool_name" "$BESMAN_K8S_CONFIG_FILE_PATH" &> /dev/null; then
        __besman_echo_white "\nFailed to remove tool: $tool_name from current_system_state."
        return 1
    else
        __besman_echo_white "\nSuccessfully removed tool: $tool_name from current_system_state."
        return 0
    fi
}
