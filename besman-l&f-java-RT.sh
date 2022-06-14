#!/bin/bash

function __besman_install_l&f-java-RT
{
    local vm_repo requirements_yml vm_repo_dir environment version roles_dir

    environment=$1
    version=$2
    vm_repo=oah-bes-vm
    vm_repo_url=https://github.com/$BESMAN_NAMESPACE/$vm_repo
    vm_repo_dir=$BESMAN/envs/besman-$environment/$version/$vm_repo

    [[ -z $vm_repo_dir ]] && git clone $vm_repo_url $vm_repo_dir # Skips cloning if the folder oah-bes-vm is present

    requirements_yml=$vm_repo_dir/provisioning/requirements.yml

    roles_dir=$vm_repo_dir/data/roles

    ansible-galaxy install -r $requirements_yml -p $roles_dir

    ansible-playbook $vm_repo_dir/provisioning/oah-install.yml --tags "java"


}