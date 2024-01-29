#!/bin/bash

function __besman_install_newrelic-java-agent-RT-env
{
    
    __besman_check_for_gh || return 1
    __besman_check_github_id || return 1
    __besman_check_for_ansible || return 1
    __besman_update_requirements_file
    __besman_ansible_galaxy_install_roles_from_requirements
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    if [[ -d $BESMAN_OSSP_CLONE_PATH ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_OSSP"
    else
        __besman_gh_clone "$BESMAN_ORG" "$BESMAN_OSSP" "$BESMAN_OSSP_CLONE_PATH"
    fi
    # Please add the rest of the code here for installation
}

function __besman_uninstall_newrelic-java-agent-RT-env
{
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=remove role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    if [[ -d $BESMAN_OSSP_CLONE_PATH ]]; then
        __besman_echo_white "Removing $BESMAN_OSSP_CLONE_PATH..."
        rm -rf "$BESMAN_OSSP_CLONE_PATH"
    else
        __besman_echo_yellow "Could not find dir $BESMAN_OSSP_CLONE_PATH"
    fi
    # Please add the rest of the code here for uninstallation

}

function __besman_update_newrelic-java-agent-RT-env
{
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for update

}

function __besman_validate_newrelic-java-agent-RT-env
{
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for validate

}

function __besman_reset_newrelic-java-agent-RT-env
{
    __besman_check_for_trigger_playbook "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_OSS_TRIGGER_PLAYBOOK_PATH/$BESMAN_OSS_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for reset

}
