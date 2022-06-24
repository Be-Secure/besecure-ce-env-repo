#!/bin/bash

function __besman_install_lf-java-RT
{
    # local oah_command role_path playbook

    # playbook=$BESMAN_DIR/playbook/besman-install-lf-java-roles.yml
    
    # oah_command=install

    # __besman_check_if_ansible_env_vars_exists || return 1

    # __besman_update_requirements_file 

    # __besman_ansible_galaxy_install_roles_from_requirements 

    # __besman_run_ansible_playbook_extra_vars "$playbook" "oah_command=$oah_command role_path=$BESMAN_ANSIBLE_ROLE_PATH"
    
    # unset oah_command role_path playbook

    export BESMAN_ENV=lf-java-RT
    oah install -s oah-bes-vm
}



# function __besman_uninstall_lf-java-RT
# {
    
# }