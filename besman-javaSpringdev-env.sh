#!/bin/bash

export BESMAN_JAVASPRINGDEV_WORKDIR="/tmp/javaSpringdev"
export BESMAN_JAVASPRINGDEV_SERVICE="https://raw.githubusercontent.com/"
export BESMAN_JAVASPRINGDEV_NAMESPACE="sriksdev"
export BESMAN_JAVASPRINGDEV_REPO="bes-tool-scripts"


function __besman_install_javaSpringdev-env
{
    echo "Installing javaSpringdev-env.."
    echo "Preparing Temp Directory..."

    mkdir -p $BESMAN_JAVASPRINGDEV_WORKDIR
    chmod -R 755 $BESMAN_JAVASPRINGDEV_WORKDIR
    rm -rf ${BESMAN_JAVASPRINGDEV_WORKDIR}/*

    echo "Looking for curl..."
    if [ -z $(which curl) ]; then
        echo "Not found."
        echo ""
        echo "======================================================================================================"
        echo " so installing curl on your system "
        sudo apt install -y curl
    fi
    
    echo "Downloading and Installing Required Tools ..."
    
    for i in vscode maven artifact Selenium ; do
      echo $i
      curl -S "${BESMAN_JAVASPRINGDEV_SERVICE}${BESMAN_JAVASPRINGDEV_NAMESPACE}/${BESMAN_JAVASPRINGDEV_REPO}/main/${i}.sh" -o "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"

     chmod +x "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"
     
     sudo sh "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"
    done 



    echo "Environment javaSpringdev-env installed successfully."
    
}

function __besman_uninstall_javaSpringdev-env
{
    echo "Uninstalling javaSpringdev-env.."

echo "Preparing Temp Directory..."

    mkdir -p $BESMAN_JAVASPRINGDEV_WORKDIR
    chmod -R 755 $BESMAN_JAVASPRINGDEV_WORKDIR
    rm -rf ${BESMAN_JAVASPRINGDEV_WORKDIR}/*

    echo "Looking for curl..."
    if [ -z $(which curl) ]; then
        echo "Not found."
        echo ""
        echo "======================================================================================================"
        echo " so installing curl on your system "
        sudo apt install -y curl
    fi
    
    echo "Removing Installed Tools ..."
    
    for i in vscode maven artifact Selenium ; do
      echo $i
      curl -S "${BESMAN_JAVASPRINGDEV_SERVICE}${BESMAN_JAVASPRINGDEV_NAMESPACE}/${BESMAN_JAVASPRINGDEV_REPO}/main/${i}.sh" -o "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"

     chmod +x "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh"
     
     sudo sh "${BESMAN_JAVASPRINGDEV_WORKDIR}/${i}.sh" --uninstall
    done 


    echo "Environment javaSpringdev-env uninstalled successfully."

}
