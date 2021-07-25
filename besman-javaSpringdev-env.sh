#!/bin/bash


export BESMAN_SERVICE="https://raw.githubusercontent.com/"
export BESMAN_NAMESPACE="sriksdev"
export BESMAN_ENV_REPO="BeSman-env-repo"
export BESMAN_TOOLS_REPO="bes-tool-scripts"



function setup_config
{

    BESMAN_ENV="$1"

    echo "Looking for curl..."
    if [ -z $(which curl) ]; then
        echo "Not found."
        echo ""
        echo "======================================================================================================"
        echo " so installing curl on your system "
        sudo apt install -y curl
    fi

    export BESMAN_ENV_CACHEDIR="`dirname ${BASH_SOURCE[0]}`/cache";
    echo "Preparing Temp Directory..."
    echo "Temp Directory: ${BESMAN_ENV_CACHEDIR}"

    mkdir -p $BESMAN_ENV_CACHEDIR
    chmod -R 755 $BESMAN_ENV_CACHEDIR
    rm -rf ${BESMAN_ENV_CACHEDIR}/*

    echo "Downloading Required Config ..."

    curl -S "${BESMAN_SERVICE}${BESMAN_NAMESPACE}/${BESMAN_ENV_REPO}/master/${BESMAN_ENV}.config" -o "${BESMAN_ENV_CACHEDIR}/${BESMAN_ENV}.config"

    if [ $? -ne 0 ]; then
        echo "\e[1;31m  Unable to Download Config.  Exiting!!... \e[0m"
        return 1;
    fi 

    chmod +r "${BESMAN_ENV_CACHEDIR}/${BESMAN_ENV}.config"


    echo "Downloading Required Tools ..."

    for i in `cat "${BESMAN_ENV_CACHEDIR}/${BESMAN_ENV}.config"|grep -v "^#"|grep -v "^\s*$"|xargs` ; do
        echo $i
        curl -S "${BESMAN_SERVICE}${BESMAN_NAMESPACE}/${BESMAN_TOOLS_REPO}/main/${i}.sh" -o "${BESMAN_ENV_CACHEDIR}/${i}.sh"

        chmod +x "${BESMAN_ENV_CACHEDIR}/${i}.sh"

    done 

}

function __besman_install_javaSpringdev-env
{
    echo "Installing ${1}..."

    setup_config ${1} 

    if [ $? -eq 0 ]; then
        echo "Installing Required Tools ..."

        for i in `cat "${BESMAN_ENV_CACHEDIR}/${BESMAN_ENV}.config"|grep -v "^#"|grep -v "^\s*$"|xargs` ; do
            echo $i
            sudo sh "${BESMAN_ENV_CACHEDIR}/${i}.sh"
        done 
    fi 

    unset BESMAN_ENV_CACHEDIR

    echo "Environment ${1} installed successfully."    
}

function __besman_uninstall_javaSpringdev-env
{
    echo "Uninstalling ${1}.."

    setup_config ${1} 

    if [ $? -eq 0 ]; then

        echo "Uninstalling Required Tools ..."

        for i in `cat "${BESMAN_ENV_CACHEDIR}/${BESMAN_ENV}.config"|grep -v "^#"|grep -v "^\s*$"|xargs` ; do
            echo $i

            sudo sh "${BESMAN_ENV_CACHEDIR}/${i}.sh" --uninstall

        done 

    fi 

    unset BESMAN_ENV_CACHEDIR

    echo "Environment ${1} uninstalled successfully."
}
