#!/bin/bash

#################################################################################
### INSTALL
#################################################################################

###### 
## Description: Installs the sonarqube and its dependencies.
## Parameters:  list of parameters and their description if any.
######
function install_sonarqube {

	# Write code  to install SBOM tool and its dependencies

	echo ""
	return 0
}

######
## Description: Installs the scorecard and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function install_scorecard {

	# Write code  to scorecard tool and its dependencies

        echo ""
        return 0

}

######
## Description: Installs the criticality_score and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function install_criticality_score {

        # Write code  to criticality_score tool and its dependencies

        echo ""
        return 0

}

######
## Description: Installs the spdx-sbom-generator and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function install_spdx-sbom-generator {

        # Write code  to spdx-sbom-generator tool and its dependencies

        echo ""
        return 0

}

######
## Description: Installs the env and its dependencies.
## Parameters:  list of parameters and their description if any.
######
function __besman_install
{
    # Checks if GitHub CLI is present or not.
    __besman_check_vcs_exist || return 1 
    # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    __besman_check_github_id || return 1 

    # Clone the source code repo of the project under assessment.
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    # Clone the source code repo of the project under assessment.
    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]
    then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi
   
   [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] && readarray -d ',' -t ASSESSMENT_TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"

   if [ ! -z $ASSESSMENT_TOOLS ];then
     for tool in ${ASSESSMENT_TOOLS[*]}
     do
        #write the functions to install the each tool mentioned in ASSESSMENT_STEP variable and call them here accordingly.
        # Write function names with format install_$tool, replace $tool with the list specified in ASSESSMENT_STEP varaible.

        #uncomment below function call
        #install_$tool
        
     done
   fi
  
   echo ""
   return 0   
}


#################################################################################
### UNINSTALL
#################################################################################

######
## Description: Uninstalls the env and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function uninstall_sonarqube {

        # Write code  to install SBOM tool and its dependencies

        echo ""
        return 0
}

######
## Description: Uninstalls the scorecard and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function uninstall_scorecard {

        # Write code to uninstall scorecard tool and its dependencies

        echo ""
        return 0

}

######
## Description: Uninstalls the criticality_score and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function uninstall_criticality_score {

        # Write code  to criticality_score tool and its dependencies

        echo ""
        return 0

}

######
## Description: Uninstalls the spdx-sbom-generator and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function uninstall_spdx-sbom-generator {

        # Write code  to spdx-sbom-generator tool and its dependencies

        echo ""
        return 0

}


function __besman_uninstall
{
     # Clone the source code repo of the project under assessment.
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        rm -rf  $BESMAN_ARTIFACT_DIR
    else
	 __besman_echo_root "$BESMAN_ARTIFACT_NAME not found"
    fi

    
   [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] && readarray -d ',' -t ASSESSMENT_TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"

   if [ ! -z $ASSESSMENT_TOOLS ];then
     for tool in ${ASSESSMENT_TOOLS[*]}
     do
       #write the functions to install the each tool mentioned in ASSESSMENT_STEP variable and call them here accordingly.
       # Write function names with format install_$tool, replace $tool with the list specified in ASSESSMENT_STEP varaible.^S

       #uncomment below function call
       #uninstall_$tool

     done
   fi

    echo ""
    return 0
}


#################################################################################
### UPDATE
#################################################################################

######
## Description: Updates the env to the newer version.
## Parameters:  list of parameters and their description if any.
######

function update_sonarqube {

        # Write code  to install SBOM tool and its dependencies

        echo ""
        return 0
}

######
## Description: Updates the scorecard and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function update_scorecard {

        # Write code to uninstall scorecard tool and its dependencies

        echo ""
        return 0

}

######
## Description: Update the criticality_score and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function update_criticality_score {

        # Write code  to criticality_score tool and its dependencies

        echo ""
        return 0

}

######
## Description: Update the spdx-sbom-generator and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function update_spdx-sbom-generator {

        # Write code  to spdx-sbom-generator tool and its dependencies

        echo ""
        return 0

}


function __besman_update
{
    
    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] &&  readarray -d ',' -t ASSESSMENT_TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"

    if [ ! -z $ASSESSMENT_TOOLS ];then
       
     for tool in ${ASSESSMENT_TOOLS[*]}
     do
       # Check if tool is already installed.
       # if [ installed ];then
       #    call the update function to update to latest version.
       #    uncoment beloe function to call update. Write a update function if not already present for the tool.
       #    update_$tool
       # else
       #    Call the install function for the tool
       #    uncomment the below call
       #    install_$tool
       # fi
     done

    fi
    echo ""
    return 0
}

#################################################################################
### VALIDATE
#################################################################################

######
## Description: validates the env to the newer version.
## Parameters:  list of parameters and their description if any.
######

function validate_sonarqube {

        # Write code  to install SBOM tool and its dependencies

        echo ""
        return 0
}

######
## Description: validates the scorecard and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function validate_scorecard {

        # Write code to uninstall scorecard tool and its dependencies

        echo ""
        return 0

}

######
## Description: Validate the criticality_score and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function validate_criticality_score {

        # Write code  to criticality_score tool and its dependencies

        echo ""
        return 0

}

######
## Description: validate the spdx-sbom-generator and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function validate_spdx-sbom-generator {

        # Write code  to spdx-sbom-generator tool and its dependencies

        echo ""
        return 0

}

function __besman_validate
{
    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] &&  readarray -d ',' -t ASSESSMENT_TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"

    if [ ! -z $ASSESSMENT_TOOLS ];then

     for tool in ${ASSESSMENT_TOOLS[*]}
     do
       # Check if tool is installed.
       # uncomment this function call
       # validate_$tool
     done

    fi
    echo ""
    return 0
}

#################################################################################
### RESET
#################################################################################

######
## Description: Reset the tools configurations.
## Parameters:  list of parameters and their description if any.
######

function reset_sonarqube {

        # Write code  to install SBOM tool and its dependencies

        echo ""
        return 0
}

######
## Description: Reset the scorecard and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function reset_scorecard {

        # Write code to uninstall scorecard tool and its dependencies

        echo ""
        return 0

}

######
## Description: Reset the criticality_score and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function reset_criticality_score {

        # Write code  to criticality_score tool and its dependencies

        echo ""
        return 0

}

######
## Description: Reset the spdx-sbom-generator and its dependencies.
## Parameters:  list of parameters and their description if any.
######

function reset_spdx-sbom-generator {

        # Write code  to spdx-sbom-generator tool and its dependencies

        echo ""
        return 0

}

function __besman_reset
{
    [[ ! -z $BESMAN_ASSESSMENT_TOOLS ]] &&  readarray -d ',' -t ASSESSMENT_TOOLS <<< "$BESMAN_ASSESSMENT_TOOLS"

    if [ ! -z $ASSESSMENT_TOOLS ];then

     for tool in ${ASSESSMENT_TOOLS[*]}
     do
       # Check if tool is installed.
       # uncomment this function call
       # reset_$tool
     done

    fi
    echo ""
    return 0
}
