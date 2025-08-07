#!/bin/bash

function __besman_install {

    # Checks if GitHub CLI is present or not.
    __besman_check_vcs_exist || return 1

    # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE
    __besman_check_github_id || return 1

    # check if python3 is installed if not install it.
    if [[ -z $(which python3) ]]; then
        __besman_echo_white "Python3 is not installed. Installing python3..."
        sudo apt-get update
        sudo apt-get install python3 -y
        [[ -z $(which python3) ]] && __besman_echo_red "Python3 installation failed" && return 1
    fi

    if [[ -z $(which pip) ]]; then
        __besman_echo_white "Installing pip"
        sudo apt install python3-pip -y
        [[ -z $(which pip) ]] && __besman_echo_red "Python3 installation failed" && return 1

    fi

    if ! echo $PATH | grep -q "$HOME/.local/bin"; then
        __besman_echo_no_colour "Adding $HOME/.local/bin to PATH var"
        echo 'export PATH=$PATH:$HOME/.local/bin' >>~/.bashrc
        echo 'export BESMAN_DIR="$HOME/.besman"' >>~/.bashrc
        echo '[[ -s "$HOME/.besman/bin/besman-init.sh" ]] && source "$HOME/.besman/bin/besman-init.sh"' >>~/.bashrc
        source ~/.bashrc

    fi

    if [[ -z $(which venv) ]]; then
        __besman_echo_white "Installing python3-venv"
        sudo apt install python3-venv -y
    else
        __besman_echo_white "python3-venv found"
    fi

    [[ ! -d "$BESMAN_ASSESSMENT_DATASTORE_DIR" ]] && { __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-ml-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1; }
    OLD_IFS=$IFS
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        cyberseceval)
            if [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" && "$BESMAN_VCS" == "git" ]]; then
                git clone "$BESMAN_PURPLELLAMA_URL" "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH"
                [[ $? -ne 0 ]] && __besman_echo_red "Failed to clone the repo" && return 1
            elif [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" && "$BESMAN_VCS" == "gh" ]]; then
                __besman_echo_yellow "gh is not supported in this env. Please clone this url manually - $BESMAN_PURPLELLAMA_URL"
            fi
            __besman_echo_white "Installing Cybersecurity Benchmarks..."
            python3 -m venv ~/.venvs/CybersecurityBenchmarks
            source ~/.venvs/CybersecurityBenchmarks/bin/activate
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH" && return 1; }
            git checkout "$BESMAN_TOOL_BRANCH"
            pip3 install -r CybersecurityBenchmarks/requirements.txt
            python3 -m pip install torch boto3 transformers openai
            [[ $? -ne 0 ]] && __besman_echo_red "Failed to install CybersecurityBenchmarks" && return 1
            deactivate

            if [[ -n "$BESMAN_RESULTS_PATH" ]] && [[ ! -d "$BESMAN_RESULTS_PATH" ]]; then
                __besman_echo_white "Creating results directory at $BESMAN_RESULTS_PATH"
                mkdir -p "$BESMAN_RESULTS_PATH"

            else
                __besman_echo_white "Could not created Results directory. Check if path already exists."
            fi

            __besman_echo_no_colour ""
            __besman_echo_green "CybersecurityBenchmarks installed successfully"
            __besman_echo_no_colour ""
            ;;
        codeshield)
            #============Codeshield installation========================
            __besman_echo_white "Installing codeshield"
            python3 -m venv ~/.venvs/codeshield_env
            source ~/.venvs/codeshield_env/bin/activate
            python3 -m pip install codeshield
            [[ $? -ne 0 ]] && __besman_echo_red "Failed to install codeshield" && return 1
            __besman_echo_no_colour ""
            __besman_echo_green "codeshield installed successfully"
            deactivate
            cd "$HOME"
            ;;
        modelbench)
            #============Modelbench installation========================
            __besman_echo_no_colour ""
            __besman_echo_white "Installing modelbench"
            # source ~/.venvs/modelbench_env/bin/activate
            python3 -m venv ~/.venvs/modelbench_env
            __besman_echo_yellow "Installing pipx"
            sudo apt update
            sudo apt install pipx -y
            pipx ensurepath
            pipx install poetry
            which poetry || { __besman_echo_red "Poetry installation failed" && return 1; }
            if [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" && "$BESMAN_VCS" == "git" ]]; then
                git clone "$BESMAN_MODELBENCH_URL" "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH"
                [[ $? -ne 0 ]] && __besman_echo_red "Failed to clone the repo" && return 1
            elif [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" && "$BESMAN_VCS" == "gh" ]]; then
                __besman_echo_yellow "gh is not supported in this env. Please clone this url manually - $BESMAN_MODELBENCH_URL"
            fi
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" && return 1; }
            source ~/.venvs/modelbench_env/bin/activate
            poetry lock
            poetry install
            [[ $? -ne 0 ]] && __besman_echo_red "Failed to install modelbench" && return 1
            __besman_echo_no_colour ""
            __besman_echo_green "modelbench installed successfully"
            deactivate
            cd "$HOME"
            ;;
        garak)
            # ============Garak installation========================
            if [[ -z $(which conda) ]]; then
                __besman_echo_white "Installing conda"
                __besman_echo_no_colour "Install GPG keys"
                curl https://repo.anaconda.com/pkgs/misc/gpgkeys/anaconda.asc | gpg --dearmor >conda.gpg
                sudo install -o root -g root -m 644 conda.gpg /usr/share/keyrings/conda-archive-keyring.gpg
                __besman_echo_no_colour "Verify GPG keys"
                sudo gpg --keyring /usr/share/keyrings/conda-archive-keyring.gpg --no-default-keyring --fingerprint 34161F5BF5EB1D4BFBBB8F0A8AEB4F8B29D82806
                __besman_echo_no_colour "Add to repo"
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/conda-archive-keyring.gpg] https://repo.anaconda.com/pkgs/misc/debrepo/conda stable main" | sudo tee /etc/apt/sources.list.d/conda.list
                __besman_echo_white "Installing conda"
                sudo apt update && sudo apt install conda -y

            else
                __besman_echo_white "Conda is already installed."
            fi
            source /opt/conda/etc/profile.d/conda.sh
            conda -V
            [[ $? -ne 0 ]] && __besman_echo_red "Conda installation failed" && return 1

            __besman_echo_white "Creating conda environment for garak"
            conda create --name garak "python>=3.10,<=3.12" -y
            conda activate garak
            if [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" && "$BESMAN_VCS" == "git" ]]; then
                git clone "$BESMAN_GARAK_URL" "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH"
                [[ $? -ne 0 ]] && __besman_echo_red "Failed to clone the repo" && return 1
            elif [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" && "$BESMAN_VCS" == "gh" ]]; then
                __besman_echo_yellow "gh is not supported in this env. Please clone this url manually - $BESMAN_GARAK_URL"
            fi
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH" && return 1; }
            python3 -m pip install -e .
            garak --list_probes
            [[ $? -ne 0 ]] && __besman_echo_red "Failed to install garak" && return 1
            __besman_echo_no_colour ""
            __besman_echo_green "Garak installed successfully"
            __besman_echo_no_colour ""
            conda deactivate
            cd "$HOME"
            ;;
        *)
            __besman_echo_red "Invalid tool name: $t"
            return 1
            ;;
        esac
    done
    IFS=$OLD_IFS
    #==============Ollama installation========================
    if [[ "$BESMAN_ARTIFACT_PROVIDER" == "Ollama" ]]; then
        # Installing ollama
        __besman_echo_white "Installing ollama..."
        if [[ -z $(which ollama) ]]; then
            # Placeholder for actual ollama installation command.
            curl -fsSL https://ollama.com/install.sh | sh
            if [[ $? -ne 0 ]]; then
                __besman_echo_red "ollama installation failed" && return 1
            fi
        else
            __besman_echo_white "ollama is already installed."
        fi
        __besman_echo_green "ollama installed successfully"
    fi

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
        __besman_echo_white "You can run the following command to pull down and run the model from Ollama"
        __besman_echo_no_colour ""
        __besman_echo_yellow "  ollama run $BESMAN_ARTIFACT_NAME:$BESMAN_ARTIFACT_VERSION"
        __besman_echo_no_colour ""

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
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" && return 1; }
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
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" && return 1; }
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
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" && return 1; }
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

    [[ -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" ]] && rm -rf "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH"
    [[ -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" ]] && rm -rf "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH"
    [[ -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" ]] && rm -rf "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH"
    cd "$HOME"
}

function __besman_update {
    OLD_IFS=$IFS
    IFS=',' read -r -a tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for t in "${tools[@]}"; do
        case $t in
        cyberseceval)
            __besman_echo_white "Updating CybersecurityBenchmarks..."
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" && return 1; }
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
            cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" && return 1; }
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
                cd "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" || { __besman_echo_red "Could not move to $BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" && return 1; }
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
            if [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH" ]]; then
                __besman_echo_red "$BESMAN_TOOL_PATH/$BESMAN_LLM_SEC_BENCH does not exist."
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
            if [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH" ]]; then
                __besman_echo_red "$BESMAN_TOOL_PATH/$BESMAN_LLM_VULN_BENCH does not exist."
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
            if [[ ! -d "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH" ]]; then
                __besman_echo_red "$BESMAN_TOOL_PATH/$BESMAN_LLM_SAFETY_BENCH does not exist."
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