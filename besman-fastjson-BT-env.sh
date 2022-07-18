#!/bin/bash

function __besman_install_fastjson-BT-env
{
    local playbook 
    playbook=$HOME/besman-trigger-fastjson-BT-roles.yml
    __besman_check_for_ansible || return 1
    expoBT BESMAN_ANSIBLE_ROLE_PATH=$HOME/tmp
    expoBT BESMAN_ANSIBLE_GALAXY_ROLES=asa1997/ansible-role-bes-java:asa1997/ansible-role-bes-maven:asa1997/ansible-role-bes-eclipse
    __besman_update_requirements_file
    __besman_ansible_galaxy_install_roles_from_requirements
    __besman_create_ansible_playbook "$playbook" "$BESMAN_ANSIBLE_GALAXY_ROLES"

    __besman_run_ansible_playbook_extra_vars "$playbook" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLE_PATH" || return 1
    unset playbook
}

function __besman_uninstall_fastjson-BT-env
{
    local playbook
    playbook=$HOME/besman-trigger-fastjson-BT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$playbook" "bes_command=remove role_path=$BESMAN_ANSIBLE_ROLE_PATH" || return 1
    [[ -f $BESMAN_ANSIBLE_ROLE_PATH/requirements.yml ]] && rm $BESMAN_ANSIBLE_ROLE_PATH/requirements.yml
    rm -rf $BESMAN_ANSIBLE_ROLE_PATH/ansible-role-bes-*
    unset BESMAN_ANSIBLE_GALAXY_ROLES BESMAN_ANSIBLE_ROLE_PATH playbook 
}

# function __besman_update_fastjson-BT-env
# {
# # TODO
# }

# function __besman_validate_fastjson-BT-env
# {
    #TODO
# }

# function __besman_reset_fastjson-BT-env
# {
    
# }