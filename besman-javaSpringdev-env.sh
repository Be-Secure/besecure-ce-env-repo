#!/bin/bash

if [ -z "$BESMAN_SERVICE" ]; then
    export BESMAN_SERVICE="https://raw.githubusercontent.com/"
fi;

if [ -z "$BESMAN_NAMESPACE" ]; then
    export BESMAN_NAMESPACE="sriksdev"
fi;


if [ -z "$BESMAN_ENV_REPO" ]; then
    export BESMAN_ENV_REPO="BeSman-env-repo"
fi;

if [ -z "$BESMAN_TOOLS_REPO" ]; then
    export BESMAN_TOOLS_REPO="bes-tool-scripts"
fi;


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

    export BESMAN_JAVASPRINGDEV_ENV_SW=`cat "${BESMAN_ENV_CACHEDIR}/${BESMAN_ENV}.config"|grep -v "^#"|grep -v "^\s*$"|xargs`

    echo $BESMAN_JAVASPRINGDEV_ENV_SW
    


}

function __besman_install_javaSpringdev-env
{
    echo "Installing ${1}..."

    echo $0

    setup_config ${1} 

env


#    echo "Preparing Temp Directory..."

#    mkdir -p $BESMAN_JAVASPRINGDEV_WORKDIR
#    chmod -R 755 $BESMAN_JAVASPRINGDEV_WORKDIR
#    rm -rf ${BESMAN_JAVASPRINGDEV_WORKDIR}/*


    
#    echo "Downloading and Installing Required Tools ..."
    
#    for i in vscode maven artifact Selenium ; do
#      echo $i
#      curl -S "${BESMAN_JAVASPRINGDEV_SERVICE}${BESMAN_JAVASPRINGDEV_NAMESPACE}/${BESMAN_JAVASPRINGDEV_REPO}/main/${i}.sh" -o "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"

#     chmod +x "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"
     
#     sudo sh "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"
#    done 


    echo "Environment ${1} installed successfully."
    
}

function __besman_uninstall_javaSpringdev-env
{
    echo "Uninstalling ${1}.."

    setup_config ${1} 

#echo "Preparing Temp Directory..."

#    mkdir -p $BESMAN_JAVASPRINGDEV_WORKDIR
#    chmod -R 755 $BESMAN_JAVASPRINGDEV_WORKDIR
#    rm -rf ${BESMAN_JAVASPRINGDEV_WORKDIR}/*

    
#    echo "Removing Installed Tools ..."
    
#    for i in vscode maven artifact Selenium ; do
#      echo $i
#      curl -S "${BESMAN_JAVASPRINGDEV_SERVICE}${BESMAN_JAVASPRINGDEV_NAMESPACE}/${BESMAN_JAVASPRINGDEV_REPO}/main/${i}.sh" -o "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"

#     chmod +x "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"
     
#     sudo sh "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh" --uninstall
#    done 

    env


    echo "Environment ${1} uninstalled successfully."

}
