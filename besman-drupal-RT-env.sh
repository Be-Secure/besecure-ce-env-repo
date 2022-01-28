#!/bin/bash

function __besman_install_drupal-RT-env
{
    local environment=$(echo $1 | cut -f 1 -d "-")
    local version=$2
    local namespace=asa1997
    local repo="oah-$environment-vm"
    local vm_name="oah-$environment-vm"
    local oah_env_path=$OAH_DIR/data/.envs/$vm_name
    local vm_config_path=$oah_env_path/oah-config.yml
    __besman_echo_white "Performing sanity checks"
    __besman_check_oah_exists || return 1
    __besman_echo_white "Cloning $repo"
    __besman_gh_clone $namespace $repo $oah_env_path
    __besman_echo_white "Opening $vm_config_path"
    __besman_open_vm_config $vm_config_path
    __besman_echo_white "Turning off cloning"
    __besman_set_oah_env_clone "false"
    __besman_echo_white "Initialising oah"
    __besman_source_init 
    __besman_oah_install_on_host $vm_name
    unset environment version namespace repo vm_config_path vm_name oah_env_path
}

