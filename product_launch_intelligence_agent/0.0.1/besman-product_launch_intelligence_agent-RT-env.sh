#!/usr/bin/env bash

# ================= INSTALL =================
function __besman_install() {
    __besman_echo_white "🚧 Installing environment for Awesome‑LLM‑Apps..."

    __besman_check_vcs_exist || {
        __besman_echo_white "GitHub CLI missing."
        return 1
    }
    __besman_check_github_id || {
        __besman_echo_white "BESMAN_USER_NAMESPACE not set."
        return 1
    }

    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "Repo already cloned."
    else
        __besman_echo_white "Cloning repo..."
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
    fi

    __besman_echo_white "Installing prerequisites: docker, go, node, python3, pip"
    sudo apt-get update
    sudo apt-get install -y docker.io python3 python3-pip curl unzip

    # Go & Node via snap / nodesource for dev
    command -v go &>/dev/null || sudo snap install go --classic
    command -v node &>/dev/null || {
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
        sudo apt-get install -y nodejs
    }

    # === Assessment Tools ===
    IFS=',' read -ra tools <<<"$BESMAN_ASSESSMENT_TOOLS"
    for tool in "${tools[@]}"; do
        name=${tool%%:*}
        case "$name" in
        scorecard)
            __besman_echo_white "Downloading scorecard from $BESMAN_SCORECARD_ASSET_URL"
            curl -L -o "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" "$BESMAN_SCORECARD_ASSET_URL"
            tar -xzf "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            chmod +x "$HOME/scorecard"
            sudo mv "$HOME/scorecard" /usr/local/bin/
            [[ -f "$HOME/scorecard_5.1.1_linux_amd64.tar.gz" ]] && rm "$HOME/scorecard_5.1.1_linux_amd64.tar.gz"
            [[ -z $(which scorecard) ]] && __besman_echo_error "Scorecard installation failed." && return 1
            ;;
        criticality_score)
            __besman_echo_white "Installing criticality_score..."
            go install github.com/ossf/criticality_score/v2/cmd/criticality_score@latest
            ;;
        sonarqube)
            __besman_echo_white "Deploying SonarQube..."
            docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name sonarqube-$BESMAN_ARTIFACT_NAME -p 9000:9000 sonarqube
            ;;
        fossology)
            __besman_echo_white "Deploying Fossology..."
            docker rm -f fossology-$BESMAN_ARTIFACT_NAME &>/dev/null
            docker run -d --name fossology-$BESMAN_ARTIFACT_NAME -p 9001:80 fossology/fossology
            ;;
        spdx-sbom-generator)
            __besman_echo_white "Installing SPDX SBOM generator..."
            mkdir -p "$BESMAN_TOOL_PATH"
            curl -L "$BESMAN_SPDX_SBOM_ASSET_URL" -o /tmp/spdx.tar.gz &&
                tar -xzf /tmp/spdx.tar.gz -C "$BESMAN_TOOL_PATH"
            ;;
        cyclonedx-sbom-generator)
            __besman_echo_white "Installing CycloneDX generator..."
            command -v cdxgen &>/dev/null || npm install -g @cyclonedx/cdxgen
            sudo cp "$(which cdxgen)" /opt/cyclonedx-sbom-generator
            ;;
        *)
            __besman_echo_white "Skipping unknown assessment tool: $name"
            ;;
        esac
    done

    __besman_echo_white "🏁 Install complete."
}

# ================ UNINSTALL ================
function __besman_uninstall() {
    __besman_echo_white "🚨 Uninstalling environment..."
    #rm -rf "$BESMAN_ARTIFACT_DIR" "$BESMAN_ASSESSMENT_DATASTORE_DIR"

    docker rm -f sonarqube-$BESMAN_ARTIFACT_NAME &>/dev/null
    docker rm -f fossology-$BESMAN_ARTIFACT_NAME &>/dev/null

    #  sudo rm -f /usr/local/bin/scorecard
    #  [ -n "$GOPATH" ] && rm -f "$GOPATH/bin/criticality_score"

    # rm -rf "$BESMAN_TOOL_PATH" /opt/cyclonedx-sbom-generator
    __besman_echo_white "🧹 Uninstall complete."
}

# ================ VALIDATE ================
function __besman_validate() {
    __besman_echo_white "🔍 Validating environment..."

    local avail=() miss=()
    for cmd in docker git node npm go curl python3 pip3; do
        command -v "$cmd" &>/dev/null && avail+=("$cmd") || miss+=("$cmd")
    done

    docker ps -a --format '{{.Names}}' | grep -q "^sonarqube-$BESMAN_ARTIFACT_NAME$" && avail+=("sonarqube") || miss+=("sonarqube")
    docker ps -a --format '{{.Names}}' | grep -q "^fossology-$BESMAN_ARTIFACT_NAME$" && avail+=("fossology") || miss+=("fossology")
    command -v scorecard &>/dev/null && avail+=("scorecard") || miss+=("scorecard")
    command -v criticality_score &>/dev/null && avail+=("criticality_score") || miss+=("criticality_score")
    command -v cdxgen &>/dev/null && avail+=("cdxgen") || miss+=("cdxgen")
    [[ -d "$BESMAN_TOOL_PATH" ]] && avail+=("spdx-sbom-generator") || miss+=("spdx-sbom-generator")

    __besman_echo_white "Available: ${avail[*]}"
    __besman_echo_white "Missing: ${miss[*]}"
    [ ${#miss[@]} -ne 0 ] && __besman_echo_white "⚠️ Some dependencies are missing." || __besman_echo_white "✅ All good!"
}

# ================ UPDATE ================
function __besman_update() {
    __besman_echo_white "🔄 Updating source and datastore..."
    [[ -d "$BESMAN_ARTIFACT_DIR" ]] && cd "$BESMAN_ARTIFACT_DIR" && git pull || __besman_echo_white "Repo missing."
}

# ================ RESET ================
function __besman_reset() {
    __besman_echo_white "🔁 Resetting environment..."
    __besman_uninstall
    __besman_install
}
