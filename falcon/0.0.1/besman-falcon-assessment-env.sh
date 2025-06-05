#!/bin/bash

function __besman_install {
    __besman_pre_checks || return 1
    __besman_setup_python_environment || return 1
    __besman_clone_assessment_datastore || return 1
    __besman_install_tools || return 1
    __besman_install_ollama_if_required || return 1
    __besman_display_env_instructions
}

function __besman_pre_checks {
    __besman_check_vcs_exist || return 1
    __besman_check_github_id || return 1
    return 0
}

function __besman_setup_python_environment {
    if [[ -z $(which python3) ]]; then
        __besman_echo_white "Python3 not found. Installing..."
        sudo apt-get update && sudo apt-get install python3 -y || {
            __besman_echo_red "Python3 installation failed"
            return 1
        }
    fi

    if [[ -z $(which pip) ]]; then
        __besman_echo_white "Installing pip..."
        sudo apt install python3-pip -y || {
            __besman_echo_red "pip installation failed"
            return 1
        }
    fi

    if ! echo $PATH | grep -q "$HOME/.local/bin"; then
        __besman_echo_white "Adding $HOME/.local/bin to PATH var"
        {
            echo 'export PATH=$PATH:$HOME/.local/bin'
            echo 'export BESMAN_DIR="$HOME/.besman"'
            echo '[[ -s "$HOME/.besman/bin/besman-init.sh" ]] && source "$HOME/.besman/bin/besman-init.sh"'
        } >>~/.bashrc
        source ~/.bashrc
    fi

    if [[ -z $(python3 -m venv --help 2>/dev/null) ]]; then
        __besman_echo_white "Installing python3-venv..."
        sudo apt install python3-venv -y || {
            __besman_echo_red "python3-venv installation failed"
            return 1
        }
    else
        __besman_echo_white "python3-venv already available"
    fi

    return 0
}

function __besman_clone_assessment_datastore {
    [[ ! -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]] && {
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-ml-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    }
    return 0
}

function __besman_install_tools {
    local OLD_IFS=$IFS
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case "$t" in
        cyberseceval) __besman_install_cyberseceval || return 1 ;;
        codeshield) __besman_install_codeshield || return 1 ;;
        modelbench) __besman_install_modelbench || return 1 ;;
        garak) __besman_install_garak || return 1 ;;
        *)
            __besman_echo_red "Invalid tool name: $t"
            return 1
            ;;
        esac
    done
    IFS=$OLD_IFS
    return 0
}
function __besman_install_cyberseceval {
    __besman_echo_white "Installing Cybersecurity Benchmarks..."
    if [[ ! -d "$BESMAN_TOOL_PATH/PurpleLlama" && "$BESMAN_VCS" == "git" ]]; then
        git clone "$BESMAN_PURPLELLAMA_URL" "$BESMAN_TOOL_PATH/PurpleLlama" || {
            __besman_echo_red "Failed to clone PurpleLlama"
            return 1
        }
    elif [[ ! -d "$BESMAN_TOOL_PATH/PurpleLlama" && "$BESMAN_VCS" == "gh" ]]; then
        __besman_echo_yellow "gh is not supported in this env. Please clone this url manually - $BESMAN_PURPLELLAMA_URL"
    fi

    python3 -m venv ~/.venvs/CybersecurityBenchmarks
    source ~/.venvs/CybersecurityBenchmarks/bin/activate
    cd "$BESMAN_TOOL_PATH/PurpleLlama" || {
        __besman_echo_red "Could not move to $BESMAN_TOOL_PATH"
        return 1
    }
    git checkout "$BESMAN_TOOL_BRANCH"
    pip3 install -r CybersecurityBenchmarks/requirements.txt
    python3 -m pip install torch boto3 transformers openai || return 1
    deactivate

    if [[ -n "$BESMAN_RESULTS_PATH" ]] && [[ ! -d "$BESMAN_RESULTS_PATH" ]]; then
        __besman_echo_white "Creating results directory at $BESMAN_RESULTS_PATH"
        mkdir -p "$BESMAN_RESULTS_PATH"

    else
        __besman_echo_white "Could not created Results directory. Check if path already exists."
    fi

    __besman_echo_green "CybersecurityBenchmarks installed successfully"
    return 0
}

function __besman_install_codeshield {
    __besman_echo_white "Installing Codeshield..."
    python3 -m venv ~/.venvs/codeshield_env
    source ~/.venvs/codeshield_env/bin/activate
    python3 -m pip install codeshield || {
        __besman_echo_red "Codeshield installation failed"
        return 1
    }
    deactivate
    cd "$HOME"
    __besman_echo_green "Codeshield installed successfully"
    return 0
}

function __besman_install_modelbench {
    __besman_echo_white "Installing Modelbench..."
    python3 -m venv ~/.venvs/modelbench_env
    __besman_echo_yellow "Installing pipx"
    sudo apt update
    sudo apt install pipx -y && pipx ensurepath
    pipx install poetry || return 1
    which poetry || { __besman_echo_red "Poetry installation failed" && return 1; }

    if [[ ! -d "$BESMAN_TOOL_PATH/modelbench" && "$BESMAN_VCS" == "git" ]]; then
        git clone "$BESMAN_MODELBENCH_URL" "$BESMAN_TOOL_PATH/modelbench"
        [[ $? -ne 0 ]] && __besman_echo_red "Failed to clone the repo" && return 1
    elif [[ ! -d "$BESMAN_TOOL_PATH/modelbench" && "$BESMAN_VCS" == "gh" ]]; then
        __besman_echo_yellow "gh is not supported in this env. Please clone this url manually - $BESMAN_MODELBENCH_URL"
    fi

    cd "$BESMAN_TOOL_PATH/modelbench" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/modelbench" && return 1; }
    source ~/.venvs/modelbench_env/bin/activate
    poetry lock && poetry install || return 1
    deactivate
    __besman_echo_green "Modelbench installed successfully"
    deactivate
    cd "$HOME"
    return 0
}

function __besman_install_garak {
    if [[ -z $(which conda) ]]; then
        __besman_echo_white "Installing Conda..."
        __besman_echo_no_colour "Install GPG keys"
        curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor >conda.gpg
        sudo install -o root -g root -m 644 conda.gpg /usr/share/keyrings/conda-archive-keyring.gpg
        __besman_echo_no_colour "Verify GPG keys"
        sudo gpg --keyring /usr/share/keyrings/conda-archive-keyring.gpg --no-default-keyring --fingerprint 34161F5BF5EB1D4BFBBB8F0A8AEB4F8B29D82806
        __besman_echo_no_colour "Add to repo"
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list
        __besman_echo_white "Installing conda"
        sudo apt update && sudo apt install conda -y || return 1
    else
        __besman_echo_white "Conda is already installed."
    fi

    source /opt/conda/etc/profile.d/conda.sh
    conda -V
    [[ $? -ne 0 ]] && __besman_echo_red "Conda installation failed" && return 1

    __besman_echo_white "Creating conda environment for garak"
    conda create --name garak "python>=3.10,<=3.12" -y || return 1
    conda activate garak

    if [[ ! -d "$BESMAN_TOOL_PATH/garak" && "$BESMAN_VCS" == "git" ]]; then
        git clone "$BESMAN_GARAK_URL" "$BESMAN_TOOL_PATH/garak"
        [[ $? -ne 0 ]] && __besman_echo_red "Failed to clone the repo" && return 1
    elif [[ ! -d "$BESMAN_TOOL_PATH/garak" && "$BESMAN_VCS" == "gh" ]]; then
        __besman_echo_yellow "gh is not supported in this env. Please clone this url manually - $BESMAN_GARAK_URL"
    fi

    cd "$BESMAN_TOOL_PATH/garak" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH" && return 1; }
    python3 -m pip install -e . || return 1
    garak --list_probes || return 1
    conda deactivate
    cd "$HOME"
    __besman_echo_green "Garak installed successfully"
    return 0
}

function __besman_install_ollama_if_required {
    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        if [[ -z $(which ollama) ]]; then
            __besman_echo_white "Installing Ollama..."
            curl -fsSL https://ollama.com/install.sh | sh || {
                __besman_echo_red "Ollama installation failed"
                return 1
            }
        else
            __besman_echo_white "ollama is already installed."
        fi
        __besman_echo_green "Ollama installed successfully"
    fi
    return 0
}

function __besman_display_env_instructions {
    __besman_echo_white "Note down the following virtual environments for each tool"
    __besman_echo_no_colour ""
    __besman_echo_yellow "Cyberseceval for LLM Security Benchmarking"
    __besman_echo_no_colour "----------------------------------------------"
    __besman_echo_white "source ~/.venvs/CybersecurityBenchmarks/bin/activate"
    __besman_echo_no_colour ""
    __besman_echo_yellow "Garak for LLM Vulnerability Analysis"
    __besman_echo_no_colour "----------------------------------------------"
    __besman_echo_white "source /opt/conda/etc/profile.d/conda.sh"
    __besman_echo_white "conda activate garak"
    __besman_echo_no_colour ""
    __besman_echo_yellow "Modelbench for LLM Safety Benchmarking"
    __besman_echo_no_colour "----------------------------------------------"
    __besman_echo_white "    source ~/.venvs/modelbench_env/bin/activate"
    __besman_echo_no_colour ""

    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        __besman_echo_white "Run the following command to pull and run Ollama model"
        __besman_echo_yellow "  ollama run $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION"
    fi
}

function __besman_uninstall {
    OLD_IFS=$IFS
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        cyberseceval)
            __besman_echo_white "Uninstalling CybersecurityBenchmarks..."
            source ~/.venvs/CybersecurityBenchmarks/bin/activate
            cd "$BESMAN_TOOL_PATH/PurpleLlama" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/PurpleLlama" && return 1; }
            python3 -m pip uninstall -y -r CybersecurityBenchmarks/requirements.txt
            [[ $? -ne 0 ]] && __besman_echo_red "Failed to uninstall CybersecurityBenchmarks" && return 1
            python3 -m pip uninstall torch boto3 transformers openai -y
            deactivate
            __besman_echo_no_colour ""
            __besman_echo_green "CybersecurityBenchmarks uninstalled successfully"
            __besman_echo_no_colour ""
            ;;
        codeshield)
            __besman_echo_white "Uninstalling codeshield"
            source ~/.venvs/codeshield_env/bin/activate
            python3 -m pip uninstall -y codeshield
            [[ $? -ne 0 ]] && __besman_echo_red "Failed to uninstall codeshield"
            deactivate
            __besman_echo_no_colour ""
            __besman_echo_green "codeshield uninstalled successfully"
            __besman_echo_no_colour ""
            ;;
        modelbench)
            __besman_echo_white "Uninstalling modelbench..."
            source ~/.venvs/modelbench_env/bin/activate
            cd "$BESMAN_TOOL_PATH/modelbench" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/modelbench" && return 1; }
            rm poetry.lock
            deactivate
            [[ -d ~/.venvs/modelbench_env ]] && rm -rf ~/.venvs/modelbench_env
            __besman_echo_green "modelbench uninstalled successfully"
            __besman_echo_no_colour ""
            ;;
        garak)
            __besman_echo_white "Uninstalling garak..."
            source /opt/conda/etc/profile.d/conda.sh
            conda activate garak
            cd "$BESMAN_TOOL_PATH/garak" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/garak" && return 1; }
            python3 -m pip uninstall -y garak
            conda deactivate
            conda env remove -n garak -y
            __besman_echo_green "garak uninstalled successfully"
            __besman_echo_no_colour ""
            ;;
        *)
            __besman_echo_red "Tool $t is not installed"
            ;;
        esac
    done
    IFS=$OLD_IFS
    # Uninstalling ollama
    if [[ $(which ollama) ]]; then
        __besman_echo_white "Uninstalling ollama..."
        # Placeholder for actual ollama uninstallation command.
        sudo rm -f "$(which ollama)"
        if [[ $? -ne 0 ]]; then
            __besman_echo_red "ollama uninstallation failed"
        fi
    fi
    __besman_echo_no_colour ""

    __besman_echo_green "Uninstallation completed successfully"
    [[ -d ~/.venvs/codeshield_env ]] && rm -rf ~/.venvs/codeshield_env
    [[ -d ~/.venvs/CybersecurityBenchmarks ]] && rm -rf ~/.venvs/CybersecurityBenchmarks

    [[ -d "$BESMAN_TOOL_PATH/modelbench" ]] && rm -rf "$BESMAN_TOOL_PATH/modelbench"
    [[ -d "$BESMAN_TOOL_PATH/PurpleLlama" ]] && rm -rf "$BESMAN_TOOL_PATH/PurpleLlama"
    [[ -d "$BESMAN_TOOL_PATH/garak" ]] && rm -rf "$BESMAN_TOOL_PATH/garak"
    cd "$HOME"
}

function __besman_update {
    OLD_IFS=$IFS
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        cyberseceval)
            __besman_echo_white "Updating CybersecurityBenchmarks..."
            cd "$BESMAN_TOOL_PATH/PurpleLlama" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/PurpleLlama" && return 1; }
            git checkout "$BESMAN_TOOL_BRANCH"
            if [[ "$BESMAN_VCS" == "git" ]]; then
                git checkout "$BESMAN_TOOL_BRANCH"
                git pull origin main
                [[ $? -ne 0 ]] && __besman_echo_red "Failed to update CybersecurityBenchmarks" && return 1
                source ~/.venvs/CybersecurityBenchmarks/bin/activate
                python3 -m pip install --upgrade -r CybersecurityBenchmarks/requirements.txt
                python3 -m pip install --upgrade torch boto3 transformers openai
                [[ $? -ne 0 ]] && __besman_echo_red "Failed to update CybersecurityBenchmarks" && return 1
                __besman_echo_no_colour ""
                __besman_echo_green "CybersecurityBenchmarks updated successfully"
                __besman_echo_no_colour ""
            elif [[ "$BESMAN_VCS" == "gh" ]]; then
                __besman_echo_yellow "gh is not supported. Skipping update"

            fi

            ;;
        codeshield)
            __besman_echo_white "Updating codeshield..."
            source ~/.venvs/codeshield_env/bin/activate
            python3 -m pip install --upgrade codeshield || { __besman_echo_red "Failed to update codeshield" && return 1; }
            deactivate
            __besman_echo_green "codeshield updated successfully"
            __besman_echo_no_colour ""
            ;;
        modelbench)
            cd "$HOME"
            __besman_echo_white "Updating modelbench..."
            cd "$BESMAN_TOOL_PATH/modelbench" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/modelbench" && return 1; }
            if [[ "$BESMAN_VCS" == "git" ]]; then
                git pull origin main
                [[ $? -ne 0 ]] && __besman_echo_error "Failed to update modelbench" && return 1
                source ~/.venvs/modelbench_env/bin/activate
                poetry update
                deactivate
                __besman_echo_green "modelbench updated successfully"
                __besman_echo_no_colour ""
            elif [[ "$BESMAN_VCS" == "gh" ]]; then
                __besman_echo_yellow "gh is not supported. Skipping update"
            fi

            ;;
        garak)
            if [[ "$BESMAN_VCS" == "git" ]]; then

                __besman_echo_white "Updating garak..."
                cd "$BESMAN_TOOL_PATH/garak" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/garak" && return 1; }
                git pull origin main
                [[ $? -ne 0 ]] && __besman_echo_red "Failed to update garak" && return 1
                source /opt/conda/etc/profile.d/conda.sh
                conda activate garak
                python3 -m pip install -e.
                conda deactivate
                __besman_echo_green "garak updated successfully"
                __besman_echo_no_colour ""
                cd $HOME
            elif [[ "$BESMAN_VCS" == "gh" ]]; then
                __besman_echo_yellow "gh is not supported. Skipping update"
            fi
            ;;
        *)
            __besman_echo_error "Tool $t is not installed"
            ;;
        esac
    done
    IFS=$OLD_IFS

    __besman_echo_white "Updating ollama..."
    # Placeholder for actual ollama update command.
    ollama update
    if [[ $? -ne 0 ]]; then
        __besman_echo_red "Failed to update ollama" && return 1
    fi
    __besman_echo_green "ollama updated successfully"

}

function __besman_validate {
    local flag="false"
    __besman_echo_white "Validating installations and folders..."
    # Validate Python3
    if [[ -z $(which python3) ]]; then
        __besman_echo_red "Python3 is not installed."
        flag="true"
    fi
    OLD_IFS=$IFS
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        cyberseceval)
            if [[ ! -d "$BESMAN_TOOL_PATH/PurpleLlama" ]]; then
                __besman_echo_red "$BESMAN_TOOL_PATH/PurpleLlama does not exist."
                flag="true"
            fi
            # Validate CybersecurityBenchmarks venv folder
            if [[ ! -d ~/.venvs/CybersecurityBenchmarks ]]; then
                __besman_echo_red "CybersecurityBenchmarks venv folder missing."
                flag="true"
            else
                source ~/.venvs/CybersecurityBenchmarks/bin/activate
                # Validate CybersecurityBenchmarks installation
                if ! python3 -m pip show torch >/dev/null 2>&1; then
                    __besman_echo_red "torch is not installed."
                    flag="true"
                fi

                if ! python3 -m pip show boto3 >/dev/null 2>&1; then
                    __besman_echo_red "boto3 is not installed."
                    flag="true"
                fi
                if [[ "$BESMAN_ARTIFACT_PROVIDER" == "HuggingFace" ]]; then
                    if ! python3 -m pip show transformers >/dev/null 2>&1; then
                        __besman_echo_red "transformers is not installed."
                        flag="true"
                    fi

                fi
                [[ "$flag" == "false" ]] && __besman_echo_green "cyberseceval installed"
                deactivate
            fi

            ;;
        codeshield)
            # Validate codeshield venv folder
            if [[ ! -d ~/.venvs/codeshield_env ]]; then
                __besman_echo_red "codeshield venv folder missing."
                flag="true"
            else
                source ~/.venvs/codeshield_env/bin/activate
                if [[ -z $(command -v codeshield) ]]; then
                    __besman_echo_error "codeshield not installed"
                    flag="true"
                else
                    __besman_echo_green "codeshield installed"
                fi
                deactivate
            fi
            ;;
        garak)
            if [[ ! -d "$BESMAN_TOOL_PATH/garak" ]]; then
                __besman_echo_red "$BESMAN_TOOL_PATH/garak does not exist."
                flag="true"
            fi
            source /opt/conda/etc/profile.d/conda.sh

            if ! conda env list | grep -q "garak"; then
                __besman_echo_red "garak conda environment missing."
                flag="true"
            else
                conda activate garak
                if [[ -z $(command -v garak) ]]; then
                    __besman_echo_error "Garak not installed" && flag="true"
                else
                    __besman_echo_green "Garak installed"
                    conda deactivate
                fi
            fi
            ;;
        modelbench)
            # Validate poetry installation
            if [[ -z $(which poetry) ]]; then
                __besman_echo_red "poetry is not installed."
                flag="true"
            fi
            if [[ ! -d "$BESMAN_TOOL_PATH/modelbench" ]]; then
                __besman_echo_red "$BESMAN_TOOL_PATH/modelbench does not exist."
                flag="true"
            fi
            if [[ ! -f ~/.venvs/modelbench_env/bin/activate ]]; then
                __besman_echo_error "Could not find modelbench venv"
                flag="true"
            else
                source ~/.venvs/modelbench_env/bin/activate
                if [[ -z $(command -v modelbench) ]]; then
                    __besman_echo_error "modelbench not installed"
                    flag="true"
                else
                    __besman_echo_green "modelbench installed"
                    deactivate
                fi
            fi
            ;;
        *)
            __besman_echo_error "Tool $t is not installed"
            flag="true"
            ;;
        esac
    done
    IFS=$OLD_IFS

    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        # Validate ollama installation
        if [[ -z $(which ollama) ]]; then
            __besman_echo_red "ollama is not installed."
            flag="true"
        fi
    fi

    if [[ "$flag" == "false" ]]; then
        __besman_echo_green "Validation successful. All tools and folders are present."
    else
        __besman_echo_red "Validation done with errors"
    fi
}

function __besman_reset {
    __besman_echo_white "Resetting everything back to default..."
    __besman_uninstall
    __besman_install
    __besman_echo_green "Reset to default completed successfully."
}
