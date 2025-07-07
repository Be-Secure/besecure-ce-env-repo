#!/usr/bin/env bats

setup() {
  export PATH="$HOME/.besman/bin:$PATH"
  if [ -f "$HOME/.besman/bin/besman-init.sh" ]; then
    source "$HOME/.besman/bin/besman-init.sh"
  else
    echo "[ERROR] BeSman not initialized!"
    return 1
  fi
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

@test "bes CLI responds to 'bes help' with correct output" {
  run bes help
  echo "$output"
  [ "$status" -eq 0 ]
  [[ "$output" == *"bes - The cli for BeSman"* ]]
}

@test "No environment is installed (bes status)" {
  run bes status
  [ "$status" -eq 0 ]
  check_env_not_installed "$output"
}

@test "MLAssessment-RT-env is listed in bes list -env" {
  run bes list -env
  [ "$status" -eq 0 ]
  [[ "$output" == *"MLAssessment-RT-env"* ]]
}
