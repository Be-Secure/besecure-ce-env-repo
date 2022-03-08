#!/bin/bash

function __besman_install_DLTGeneric-env {
    local environment=$environment
    local version=$version
    
    if [[ -z $BESMAN_BLOCKCHAIN_ENV_ROOT ]]; then
        export BESMAN_BLOCKCHAIN_ENV_ROOT=$HOME/.besman_blockchain_env
    fi

    __besman_echo_yellow "[+] Checking Requirements ...."
	__besman_checkInstallation python3 python3-pip nodejs npm

	__besman_echo_yellow "[+] Checking solc installation ....."
	sudo add-apt-repository ppa:ethereum/ethereum
	sudo apt-get update
	__besman_checkInstallation solc
   
}


function __besman_checkInstallation {
    for package in "$@"
    do
        if [[ -z $(which "$package") ]]; then
            __besman_echo_red "[-] $package Not Found. Installing $package"
            sudo apt-get install "$package" || (__besman_echo_red "$package installation failed. Please install $package manually and try again."; exit 1)
        else
            __besman_echo_green "[+] $package already installed"
        fi
    done
}

function __besman_check_npmPackage_installation {
    for package in "$@"
    do
        if [[ -z $(which "$package") ]]; then
            __besman_echo_red "[-] $1 not found. Installing $1"
		    sudo apt-get update
		    npm install -g "$package" || (__besman_echo "$package installation failed. Please install $package manually and try again."; exit 1)
        else
            __besman_echo_green "[+] $package already installed"
        fi
    done
}






 # __besman_echo_yellow "
    # ================================================================================
    # Choose Type of Environment to Install : 
    # 1. dApp Security and Pentesting 
    # 2. Decentralized Exchange Security and Pentesting 
    # 3. Isolated Smart Contract Auditing Environment 
    # 4. Wallets/Storage/Database Security and Pentesting
    # ================================================================================"

    # read -p "Choose Option : " option

    # case ${option} in
    #     1) 
	# 	__besman_echo_green "dApp Security and Pentesting"
	# 	;;

    #     *)
	#        	__besman_echo_green "Something else"
	# 	;;
    # esac