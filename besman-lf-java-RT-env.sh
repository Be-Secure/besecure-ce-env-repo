#!/bin/bash

function __besman_install_lf-java-RT-env
{
    local bes_command role_path playbook roles

    # playbook=$BESMAN_DIR/playbook/besman-install-lf-java-roles.yml
    
    bes_command=install

    playbook=besman-install-lf-java-RT-roles.yml

    __besman_check_if_ansible_env_vars_exists || return 1

    __besman_update_requirements_file 

    __besman_ansible_galaxy_install_roles_from_requirements 

    __besman_run_ansible_playbook_extra_vars "$HOME/$playbook" "bes_command=$bes_command role_path=$BESMAN_ANSIBLE_ROLE_PATH"

    unset bes_command role_path playbook roles


}



function __besman_uninstall_lf-java-RT-env
{
    
    local bes_command playbook 
    bes_command=remove
    playbook=besman-install-lf-java-RT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$HOME/$playbook" "bes_command=$bes_command role_path=$BESMAN_ANSIBLE_ROLE_PATH"

    [[ -f $BESMAN_ANSIBLE_ROLE_PATH/requirements.yml ]] && rm $BESMAN_ANSIBLE_ROLE_PATH/requirements.yml    

    unset bes_command playbook 

}

function __besman_update_lf-java-RT-env
{

    local roles bes_command
    bes_command=update
    playbook=besman-install-lf-java-RT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$BESMAN_DIR/playbook/$playbook" "bes_command=$bes_command role_path=$BESMAN_ANSIBLE_ROLE_PATH"

    unset roles bes_command

}

function __besman_validate_lf-java-RT-env
{

    local roles bes_command
    bes_command=validate

    playbook=besman-install-lf-java-RT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$BESMAN_DIR/playbook/$playbook" "bes_command=$bes_command role_path=$BESMAN_ANSIBLE_ROLE_PATH"
    unset roles bes_command


}

# TODO

# function __besman_reset_lf-java-RT-env
# {



# }