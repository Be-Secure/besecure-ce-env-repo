setup() {
  export PATH="$HOME/.besman/bin:$PATH"
  if [ -f "$HOME/.besman/bin/besman-init.sh" ]; then
    source "$HOME/.besman/bin/besman-init.sh"
  else
    echo "[ERROR] BeSman not initialized!"
    return 1 # Ensure setup itself fails if besman-init.sh is missing
  fi

  export BESMAN_ARTIFACT_DIR="$HOME/ml-assessment-env"
  export BESMAN_VENV_NAME="ml-assessment-venv"
  export BESMAN_ASSESSMENT_DATASTORE_DIR="$HOME/besecure-ml-assessment-datastore"
}

check_env_not_installed() {
  if [[ "$1" == *"-env"* ]]; then
    echo "Error: Installed environments found:"
    echo "$1" | grep -- "-env"
    false
  else
    [[ "$1" == *"Please install an environment first"* ]]
  fi
}

@test "bes CLI is installed and accessible" {
  run command -v bes
  [ "$status" -eq 0 ]
  [[ "$output" != "" ]]
}

@test "No environment is pre-installed (bes status)" {
  run bes status
  [ "$status" -eq 0 ]
  check_env_not_installed "$output"
}

@test "MLAssessment-RT-env is listed in bes list -env" {
  run bes list -env
  [ "$status" -eq 0 ]
  [[ "$output" == *"MLAssessment-RT-env"* ]]
}

@test "bes install -env MLAssessment-RT-env -V 0.0.1 initiates environment setup and completes" {

  run bash -c 'source $HOME/.besman/bin/besman-init.sh && printf "%s\n" "n" | bes install -env MLAssessment-RT-env -V 0.0.1'
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"Installation completed successfully"* ]]
  [[ "$output" == *"Successfully installed MLAssessment-RT-env"* ]]
}

@test "bes reload command works and sources config" {
  run bash -c 'source $HOME/.besman/bin/besman-init.sh && bes reload'
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Sourcing local config parameters from /home/neeraj/CRS_Work/projects/besecure-ce-env-repo/MLAssessment/0.0.1/besman-MLAssessment-RT-env-config.yaml" ]]
  [[ "$output" =~ "Done." ]]
}

@test "Python virtual environment is created in expected path" {
  VENV_PATH="$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME"
  [ -d "$VENV_PATH" ]
}

@test "python3 exists on PATH after install" {
  VENV_PATH="$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME"
  if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    run command -v python3
    [ "$status" -eq 0 ]
    deactivate
  else
    echo "[ERROR] Virtualenv not found at $VENV_PATH"
    false
  fi
}

@test "pip exists inside virtual environment" {
  VENV_PATH="$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME"
  if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    run pip --version
    [ "$status" -eq 0 ]
    deactivate
  else
    echo "[ERROR] Virtualenv not found at $VENV_PATH"
    false
  fi

}

@test "pytest is installed in virtual environment" {
  VENV_PATH="$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME"
  if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    run pip show pytest
    [ "$status" -eq 0 ]
    deactivate
  else
    echo "[ERROR] Virtualenv not found at $VENV_PATH"
    false
  fi

}

@test "adversarial-robustness-toolbox is installed in virtual environment" {
  VENV_PATH="$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME"
  if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    run pip show adversarial-robustness-toolbox
    [ "$status" -eq 0 ]
    deactivate
  else
    echo "[ERROR] Virtualenv not found at $VENV_PATH"
    false
  fi

}

@test "Jupyter Notebook is importable in virtual environment" {
  VENV_PATH="$BESMAN_ARTIFACT_DIR/$BESMAN_VENV_NAME"
  if [ -f "$VENV_PATH/bin/activate" ]; then
    source "$VENV_PATH/bin/activate"
    run python -c "import notebook"
    [ "$status" -eq 0 ]
    deactivate
  else
    echo "[ERROR] Virtualenv not found at $VENV_PATH"
    false
  fi

}

@test "Jupyter kernel is registered with ipykernel name" {
  run jupyter kernelspec list
  echo "$output" | grep -q "$BESMAN_VENV_NAME"
}

@test "Assessment datastore repo is cloned at expected path" {
  [ -d "$BESMAN_ASSESSMENT_DATASTORE_DIR/.git" ]
}
