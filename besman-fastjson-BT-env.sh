#!/bin/bash

function __besman_install_fastjson-BT-env
{
    local playbook repo namespace clone_path
    __besman_check_for_ansible || return 1
    __besman_check_for_gh || return 1
    namespace=Be-Secure
    __besman_gh_auth "$BESMAN_USER_NAMESPACE"
    playbook=$HOME/besman-trigger-fastjson-BT-roles.yml
    export BESMAN_ANSIBLE_ROLE_PATH=$HOME/tmp
    export BESMAN_ANSIBLE_GALAXY_ROLES=asa1997/ansible-role-oah-java:asa1997/ansible-role-oah-maven:asa1997/ansible-role-oah-eclipse
    __besman_update_requirements_file
    __besman_ansible_galaxy_install_roles_from_requirements
    __besman_check_for_trigger_playbook "$playbook"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook "$playbook" "$BESMAN_ANSIBLE_GALAXY_ROLES"
    __besman_run_ansible_playbook_extra_vars "$playbook" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLE_PATH" || return 1
    repo=fastjson
    clone_path=$HOME/fastjson
    [[ ! -d $clone_path ]] && __besman_gh_clone "$namespace" "$repo" "$clone_path"
    unset playbook repo namespace clone_path
}

function __besman_uninstall_fastjson-BT-env
{
    local playbook 
    playbook=$HOME/besman-trigger-fastjson-BT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$playbook" "bes_command=remove role_path=$HOME/tmp" || return 1
    [[ -f $HOME/fastjson ]] && rm -rf $HOME/fastjson
}

function __besman_update_fastjson-BT-env
{
    local playbook
    playbook=$HOME/besman-trigger-fastjson-BT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$playbook" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLE_PATH" || return 1
    unset playbook
}

function __besman_validate_fastjson-BT-env
{
    local playbook
    playbook=$HOME/besman-trigger-fastjson-BT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$playbook" "bes_command=validate role_path=$HOME/tmp" || return 1
    unset playbook
}

function __besman_reset_fastjson-BT-env
{
    local playbook
    playbook=$HOME/besman-trigger-fastjson-BT-roles.yml
    __besman_run_ansible_playbook_extra_vars "$playbook" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLE_PATH" || return 1
    unset playbook
}
