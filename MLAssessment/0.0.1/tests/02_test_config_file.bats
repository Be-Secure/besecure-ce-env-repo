#!/usr/bin/env bats

setup() {
  ENV_YAML="$(dirname "$BATS_TEST_FILENAME")/../besman-MLAssessment-RT-env-config.yaml"
}

#----------------------------------------
# Helper to ensure config file exists
#----------------------------------------
fail_if_config_missing() {
  if [ ! -f "$ENV_YAML" ]; then
    echo "Config file not found: $ENV_YAML"
    false
  fi
}

@test "All environment variables in config should not be empty" {
  fail_if_config_missing

  vars=$(grep -o '^[A-Z0-9_]\+:' "$ENV_YAML" | sed 's/://')
  empty_vars=()
  for var in $vars; do
    value=$(grep "^$var:" "$ENV_YAML" | sed 's/^[^:]*:[[:space:]]*//' | sed 's/#.*//' | xargs)
    if [ -z "$value" ]; then
      empty_vars+=("$var")
    fi
  done

  if [ "${#empty_vars[@]}" -ne 0 ]; then
    echo "The following variables are empty:"
    printf '%s\n' "${empty_vars[@]}"
    false
  fi
}

@test "Required environment variables have correct values" {
  fail_if_config_missing

  run grep "^BESMAN_ORG:" "$ENV_YAML"
  expected="BESMAN_ORG: Be-Secure #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_ARTIFACT_TYPE:" "$ENV_YAML"
  expected="BESMAN_ARTIFACT_TYPE: ml #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_ENV_NAME:" "$ENV_YAML"
  expected="BESMAN_ENV_NAME: MLAssessment-RT-env #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_ARTIFACT_DIR:" "$ENV_YAML"
  expected="BESMAN_ARTIFACT_DIR: \$HOME/ml-assessment-env #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_ENV_DIR:" "$ENV_YAML"
  expected="BESMAN_ENV_DIR: \$HOME/ml-assessment-env"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_VENV_NAME:" "$ENV_YAML"
  expected="BESMAN_VENV_NAME: ml-assessment-venv"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_ART_REPO:" "$ENV_YAML"
  expected="BESMAN_ART_REPO: https://github.com/NeerajK007/adversarial-robustness-toolbox.git"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_TOOLS_DIR:" "$ENV_YAML"
  expected="BESMAN_TOOLS_DIR: \$BESMAN_ENV_DIR/tools"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_TOOL_PATH:" "$ENV_YAML"
  expected="BESMAN_TOOL_PATH: /opt #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_LAB_TYPE:" "$ENV_YAML"
  expected="BESMAN_LAB_TYPE: Organization #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_LAB_NAME:" "$ENV_YAML"
  expected="BESMAN_LAB_NAME: Be-Secure #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_ASSESSMENT_DATASTORE_DIR:" "$ENV_YAML"
  expected="BESMAN_ASSESSMENT_DATASTORE_DIR: \$HOME/besecure-ml-assessment-datastore #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }

  run grep "^BESMAN_ASSESSMENT_DATASTORE_URL:" "$ENV_YAML"
  expected="BESMAN_ASSESSMENT_DATASTORE_URL: https://github.com/Be-Secure/besecure-ml-assessment-datastore #***"
  [ "$output" = "$expected" ] || {
    echo "Expected: $expected"
    echo "Found: $output"
    false
  }
}
