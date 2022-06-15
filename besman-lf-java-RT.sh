#!/bin/bash

function __besman_install_lf-java-RT
{

    cat <<EOF >> $HOME/tmp/requirements.yml
---
- src: https://github.com/asa1997/ansible-role-oah-threatdragon
- src: https://github.com/asa1997/ansible-role-oah-java
- src: https://github.com/asa1997/ansible-role-oah-maven
EOF

    __besman_ansible_galaxy_install_from_requirements "$HOME/tmp" "$HOME/tmp"
    __besman_ansible_playbook_extra_vars "besman-install-lf-java-roles.yml" "oah_command=install role_path=$HOME/tmp"

}