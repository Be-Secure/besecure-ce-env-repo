#!/bin/bash

#!/usr/bin/env bash

# Lifecycle function: Install environment
__besman_install() {

    __besman_echo_white "Installing environment for DeepRobust ..."

    # ----------- Clone source and datastore repos -----------
    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1

    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi

    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]]; then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    fi

    # ----------- Environment Dependencies -----------
    __besman_echo_white "Installing environment dependencies..."

    local deps=(go python3 python3-venv docker curl git jq)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &>/dev/null; then
            __besman_echo_white "Installing missing dependency: $dep"
            case "$dep" in
            docker)
                sudo apt-get install -y ca-certificates curl gnupg lsb-release
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" |
                    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
                sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io
                sudo usermod -aG docker "$USER" && sudo systemctl restart docker
                ;;
            node)
                curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
                sudo apt-get install -y nodejs
                ;;
            *)
                sudo apt-get update && sudo apt-get install -y "$dep"
                ;;
            esac
        fi
    done

    # ----------- Python Environment Setup -----------
    local venv_dir="$HOME/.besman_venv_deeprobust"
    if [[ ! -d $venv_dir ]]; then
        __besman_echo_white "Setting up Python virtual environment..."
        python3 -m venv "$venv_dir"
        source "$venv_dir/bin/activate"
        pip install --upgrade pip
        if [[ -f "$BESMAN_ARTIFACT_DIR/requirements.txt" ]]; then
            pip install -r "$BESMAN_ARTIFACT_DIR/requirements.txt"
        fi
    fi

    # ----------- Assessment Tool Setup -----------
    IFS=',' read -ra tools <<<"$BESMAN_ASSESSMENT_TOOLS"

    for tool in "${tools[@]}"; do
        name=$(echo "$tool" | cut -d':' -f1)
        version=$(echo "$tool" | cut -d':' -f2)

        case "$name" in

        scorecard)
            __besman_echo_white "Installing scorecard..."
            mkdir -p /tmp/scorecard
            curl -L -o /tmp/scorecard/scorecard.tar.gz https://github.com/ossf/scorecard/releases/latest/download/scorecard-linux-amd64.tar.gz
            tar -xzf /tmp/scorecard/scorecard.tar.gz -C /tmp/scorecard
            chmod +x /tmp/scorecard/scorecard
            sudo mv /tmp/scorecard/scorecard /usr/local/bin/
            ;;

        criticality_score)
            __besman_echo_white "Installing criticality_score..."
            go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            ;;

        sonarqube)
            __besman_echo_white "Setting up SonarQube container..."
            docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name sonarqube-$BESMAN_ARTIFACT_NAME -p 9000:9000 sonarqube
            ;;

        fossology)
            __besman_echo_white "Setting up Fossology container..."
            docker rm -f fossology-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name fossology-$BESMAN_ARTIFACT_NAME -p 9001:80 fossology/fossology
            ;;

        spdx-sbom-generator)
            __besman_echo_white "Installing SPDX SBOM generator..."
            mkdir -p "$BESMAN_TOOL_PATH"
            curl -L "$BESMAN_SPDX_SBOM_ASSET_URL" -o /tmp/spdx.tar.gz
            tar -xzf /tmp/spdx.tar.gz -C "$BESMAN_TOOL_PATH"
            ;;

        cyclonedx-sbom-generator)
            __besman_echo_white "Installing CycloneDX SBOM generator..."
            if ! command -v cdxgen &>/dev/null; then
                npm install -g @cyclonedx/cdxgen
            fi
            sudo cp "$(which cdxgen)" /opt/cyclonedx-sbom-generator
            ;;

        *)
            __besman_echo_white "Unknown tool: $name"
            ;;
        esac
    done

    __besman_echo_white "✅ Environment setup complete for DeepRobust."
}

function __besman_uninstall {
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

}

function __besman_update {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for update

}

function __besman_validate {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for validate

}

function __besman_reset {
    __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
    [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
    __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
    # Please add the rest of the code here for reset

}
