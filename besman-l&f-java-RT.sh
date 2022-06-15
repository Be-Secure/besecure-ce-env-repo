#!/bin/bash

function __besman_install_lf-java-RT
{
    # local vm_repo requirements_yml vm_repo_dir environment version roles_dir

    # environment=$1
    # version=$2
    # vm_repo=oah-bes-vm
    # vm_repo_url=https://github.com/$BESMAN_NAMESPACE/$vm_repo
    # vm_repo_dir=$BESMAN/envs/besman-$environment/$version/$vm_repo

    # [[ -z $vm_repo_dir ]] && git clone $vm_repo_url $vm_repo_dir # Skips cloning if the folder oah-bes-vm is present

    # requirements_yml=$vm_repo_dir/provisioning/requirements.yml

    # roles_dir=$vm_repo_dir/data/roles

    # ansible-galaxy install -r $requirements_yml -p $roles_dir

    # ansible-playbook $vm_repo_dir/provisioning/oah-install.yml --tags "java"

    # local roles

    # roles=("threatdragon" "java" "maven")

    # for i in "$roles"
    # do
    #     __besman_gh_clone "$BESMAN_NAMESPACE" "ansible-role-oah-$i" "$HOME"
    # done

    cat <<EOF >> $HOME/requirements.yml
    ---
    - src: https://github.com/asa1997/threatdragon
    - src: https://github.com/asa1997/java
    - src: https://github.com/asa1997/maven

EOF

    __besman_ansible_galaxy_install_from_requirements "$HOME"
    __besman_ansible_playbook_extra_vars "besman-install-lf-java-roles.yml" "path=$HOME"

}