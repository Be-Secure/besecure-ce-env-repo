#!/usr/bin/env bats

setup_file() {

  # clean already sourced lifecycle function __besman_install
  unset -f __besman_install || true

  local current_test_dir # Use local for variables within functions
  current_test_dir="$(dirname "$BATS_TEST_FILENAME")"

  # Path to the root of your project/repository
  ENV_DIR="$(cd "$current_test_dir/.." && pwd)"
  ENV_YAML="$ENV_DIR/besman-MLAssessment-RT-env-config.yaml"
  ENV_SCRIPT="$ENV_DIR/besman-MLAssessment-RT-env.sh"

  export ENV_SCRIPT="$ENV_DIR/besman-MLAssessment-RT-env.sh"

  echo "[DEBUG] ENV_SCRIPT=$ENV_SCRIPT" >&2
  if [[ ! -f "$ENV_SCRIPT" ]]; then
    echo "[ERROR] ENV_SCRIPT not found: $ENV_SCRIPT" >&2
    exit 1
  fi

  # Stub sudo to avoid running real apt installs during tests
  function sudo() {
    if [[ "$1" == "apt-get" ]]; then
      echo "[TEST] Skipping apt-get $*"
      return 0
    fi
    command sudo "$@"
  }

  ## Stub __besman_echo_white
  function __besman_echo_white() {
    echo "$@"
  }

  # stub __besman_check_vcs_exist
  function __besman_check_vcs_exist() {
    return 0
  }
  #stub __besman_check_github_id
  function __besman_check_github_id() {
    return 0
  }

  # Load variables from YAML
  while IFS=":" read -r key value; do
    key=$(__besman_echo_white "$key" | xargs)
    value=$(__besman_echo_white "$value" | sed 's/#.*//' | xargs)

    if [[ -n "$key" && -n "$value" ]]; then
      eval "export $key=\"$value\""
      echo "[DEBUG] Exported: $key=${!key}"
    fi
  done < <(grep -E '^[A-Z0-9_]+:' "$ENV_YAML")

  # Clean previous install (optional safety)
  # rm -rf "$BESMAN_ENV_DIR"

  # Run install once
  source "$ENV_SCRIPT"
  __besman_install

}

## Test-cases
#
@test "__besman_install function exists in env script" {
  run grep "__besman_install" "$ENV_SCRIPT"
  [ "$status" -eq 0 ]
}

@test "__besman_install completes without errors" {
  # install already done in setup_file
  [ -d "$BESMAN_ARTIFACT_DIR" ]
}

@test "Artifact directory is created after install" {
  [ -d "$BESMAN_ARTIFACT_DIR" ]
}

@test "BESMAN_ENV_DIR exists after install" {
  [ -d "$BESMAN_ENV_DIR" ]
}

@test "BESMAN_TOOLS_DIR exists after install" {
  [ -d "$BESMAN_TOOLS_DIR" ]
}

@test "ART repo is cloned inside BESMAN_TOOLS_DIR" {
  ART_REPO_PATH="$BESMAN_TOOLS_DIR/adversarial-robustness-toolbox"
  [ -d "$ART_REPO_PATH" ]
}

@test "ART repository contains a .git directory" {
  [ -d "$BESMAN_TOOLS_DIR/adversarial-robustness-toolbox/.git" ]
}

@test "ART repo inside BESMAN_TOOLS_DIR is a valid git repository" {
  ART_REPO_PATH="$BESMAN_TOOLS_DIR/adversarial-robustness-toolbox"
  cd "$ART_REPO_PATH"
  run git rev-parse --is-inside-work-tree
  [ "$status" -eq 0 ]
  [ "$output" = "true" ]
}

@test "Python virtual environment is created in expected path" {
  VENV_PATH="$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME"
  [ -d "$VENV_PATH" ]
}

@test "python3 exists on PATH after install" {
  source "$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME/bin/activate"
  run command -v python3
  [ "$status" -eq 0 ]
}

@test "pip exists inside virtual environment" {
  source "$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME/bin/activate"
  run pip --version
  [ "$status" -eq 0 ]
  deactivate
}

@test "pytest is installed in virtual environment" {
  source "$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME/bin/activate"
  run pip show pytest
  [ "$status" -eq 0 ]
  deactivate
}

@test "adversarial-robustness-toolbox is installed in virtual environment" {
  source "$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME/bin/activate"
  run pip show adversarial-robustness-toolbox
  [ "$status" -eq 0 ]
  deactivate
}

@test "Assessment datastore repo is cloned at expected path" {
  [ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR/.git" ]
}

@test "Python can execute inside virtual environment after install" {
  source "$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME/bin/activate"
  run python --version
  [ "$status" -eq 0 ]
  deactivate
}

@test "Jupyter Notebook is importable in virtual environment" {
  source "$BESMAN_ENV_DIR/$BESMAN_VENV_NAME/bin/activate"
  run python -c "import notebook"
  [ "$status" -eq 0 ]
  deactivate
}

@test "Jupyter kernel is registered with ipykernel name" {
  run jupyter kernelspec list
  echo "$output" | grep -q "$BESMAN_VENV_NAME"
}
