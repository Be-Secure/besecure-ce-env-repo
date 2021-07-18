#!/bin/bash

export BESMAN_JAVASPRINGSEC_WORKDIR="/tmp/javaSpringsec"
export BESMAN_JAVASPRINGSEC_SERVICE="https://raw.githubusercontent.com/"
export BESMAN_JAVASPRINGSEC_NAMESPACE="Be-Secure"
export BESMAN_JAVASPRINGSEC_REPO="bes-tool-scripts"


function __besman_install_javaSpringsec-env
{
    echo "Installing javaSpringsec-env.."
    echo "Preparing Temp Directory..."

    mkdir -p $BESMAN_JAVASPRINGSEC_WORKDIR
    chmod -R 755 $BESMAN_JAVASPRINGSEC_WORKDIR
    rm -rf ${BESMAN_JAVASPRINGSEC_WORKDIR}/*

    echo "Looking for curl..."
    if [ -z $(which curl) ]; then
        echo "Not found."
        echo ""
        echo "======================================================================================================"
        echo " so installing curl on your system "
        sudo apt install -y curl
    fi
    
    echo "Downloading and Installing Required Tools ..."
    
    for i in maven artifact Selenium sonarQube zap_tool ; do
      echo $i
      curl -S "${BESMAN_JAVASPRINGSEC_SERVICE}${BESMAN_JAVASPRINGSEC_NAMESPACE}/${BESMAN_JAVASPRINGSEC_REPO}/main/${i}.sh" -o "${BESMAN_JAVASPRINGSEC_WORKDIR}/${i}.sh"

     chmod +x "${BESMAN_JAVASPRINGSEC_WORKDIR}/${i}.sh"
     
     sudo sh "${BESMAN_JAVASPRINGSEC_WORKDIR}/${i}.sh"
    done 



    echo "Environment javaSpringsec-env installed successfully."
    
}

function __besman_uninstall_javaSpringsec-env
{
    echo "Uninstalling javaSpringsec-env.."

echo "Preparing Temp Directory..."

    mkdir -p $BESMAN_JAVASPRINGSEC_WORKDIR
    chmod -R 755 $BESMAN_JAVASPRINGSEC_WORKDIR
    rm -rf ${BESMAN_JAVASPRINGSEC_WORKDIR}/*

    echo "Looking for curl..."
    if [ -z $(which curl) ]; then
        echo "Not found."
        echo ""
        echo "======================================================================================================"
        echo " so installing curl on your system "
        sudo apt install -y curl
    fi
    
    echo "Removing Installed Tools ..."
    
    for i in maven artifact Selenium sonarQube zap_tool ; do
      echo $i
      curl -S "${BESMAN_JAVASPRINGSEC_SERVICE}${BESMAN_JAVASPRINGSEC_NAMESPACE}/${BESMAN_JAVASPRINGSEC_REPO}/main/${i}.sh" -o "${BESMAN_JAVASPRINGSEC_WORKDIR}/${i}.sh"

     chmod +x "${BESMAN_JAVASPRINGSEC_WORKDIR}/${i}.sh"
     
     sudo sh "${BESMAN_JAVASPRINGSEC_WORKDIR}/${i}.sh" --uninstall
    done 


    echo "Environment javaSpringsec-env uninstalled successfully."

}
