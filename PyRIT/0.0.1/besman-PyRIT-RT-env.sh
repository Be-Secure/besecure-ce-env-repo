#!/bin/bash

function __besman_install
{
    __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present or not.
    __besman_check_github_id || return 1 # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE 
    __besman_check_for_ansible || return 1 # Checks if ansible is installed or not.
    __besman_create_roles_config_file # Creates the role config file with the parameters from env config
    
    # Requirements file is used to list the required ansible roles. The data for requirements file comes from BESMAN_ANSIBLE_ROLES env var.
    # This function updates the requirements file from BESMAN_ANSIBLE_ROLES env var.
    __besman_update_requirements_file 
    __besman_ansible_galaxy_install_roles_from_requirements # Downloads the ansible roles mentioned in BESMAN_ANSIBLE_ROLES to BESMAN_ANSIBLE_ROLES_PATH
    # This function checks for the playbook BESMAN_ARTIFACT_TRIGGER_PLAYBOOK under BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH.
    # The trigger playbook is used to run the ansible roles.
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook # Creates the trigger playbook if not present.
    # Runs the trigger playbook. We are also passing these variables - bes_command=install; role_path=$BESMAN_ANSIBLE_ROLES_PATH
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    __install_conda
    # Clones the source code repo.
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]] 
    then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

    fi
    # Please add the rest of the code here for installation
}

function __besman_uninstall
{
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
    __uninstall_conda
}

function __besman_update
{
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for update

}

function __besman_validate
{
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for validate

}

function __besman_reset
{
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for reset

}

function __install_conda {
    sudo apt-get install libgl1-mesa-glx libegl1-mesa libxrandr2 libxrandr2 libxss1 libxcursor1 libxcomposite1 libasound2 libxi6 libxtst6
    echo "Checking for Anaconda..."
    if command -v conda &> /dev/null; then
        echo "Anaconda is already installed."
    else
        echo "Installing Anaconda..."
        wget https://repo.anaconda.com/archive/Anaconda3-2023.03-Linux-x86_64.sh -O /tmp/anaconda.sh
        bash /tmp/anaconda.sh -b -p $HOME/anaconda3
        eval "$($HOME/anaconda3/bin/conda shell.bash hook)"
        conda init bash
        source ~/.bashrc
        rm /tmp/anaconda.sh
    fi
    eval "$(conda shell.bash hook)"
    conda config --set auto_activate_base false
}

function __uninstall_conda {
    echo "Removing Anaconda distribution..."
    conda deactivate 2>/dev/null
    conda init --reverse --all
    rm -rf $HOME/anaconda3
    sudo rm -rf /opt/anaconda3
    rm -rf $HOME/.conda
    rm -rf $HOME/.continuum
    rm -rf $HOME/.anaconda
    rm -rf $HOME/.condarc
    rm -rf $HOME/.conda_environments.txt
    rm -rf $HOME/.conda_build_config.yaml
    sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' $HOME/.bashrc
    sed -i '/# >>> conda initialize >>>/,/# <<< conda initialize <<</d' $HOME/.zshrc
    sed -i '/anaconda3/d' $HOME/.bashrc
    sed -i '/anaconda3/d' $HOME/.zshrc
    unset CONDA_EXE
    unset _CE_M
    unset _CE_CONDA
    unset CONDA_PYTHON_EXE
    unset CONDA_SHLVL
    unset CONDA_DEFAULT_ENV
    unset CONDA_PROMPT_MODIFIER
    source $HOME/.bashrc
    source $HOME/.zshrc
    hash -r
}