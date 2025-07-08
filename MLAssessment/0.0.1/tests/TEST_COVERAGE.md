# MLAssessment RT Environment Bats Tests

This repository contains a suite of [Bats (Bash Automated Testing System)](https://bats-core.readthedocs.io/en/stable/) tests for validating the setup and functionality of the BeSman MLAssessment RT environment.

---

## Overview

These tests ensure that:

- The `bes` CLI is correctly installed and accessible.
- BeSman `MLAssessment-RT-env` environments can be listed from repo dir.
- The `MLAssessment-RT-env` environment installation process behaves as expected (including failure scenarios due to missing files, if applicable).
- Key components of a successfully installed Python-based environment (like virtual environment creation, `python3`, `pip`, and specific Python packages such as `pytest`, `adversarial-robustness-toolbox`, and `notebook`) are present and functional.
- Jupyter kernel registration and assessment datastore cloning are verified.

---

## Getting Started

### Prerequisites

- [Bats (Bash Automated Testing System)](https://bats-core.readthedocs.io/en/stable/installation.html) installed.
- BeSman installed.
- The BeSman environment definitions (especially `MLAssessment-RT-env`) are available in your BeSman repository.

### Running the Tests

1.  Navigate to the `/test` directory containing `testEnv-MLAssessment-installation.bats`.
2.  Run the tests using Bats:

    ```bash
    bats testEnv-MLAssessment-installation.bats
    ```

---

## Test Details

The `testBesManEnv.bats` file includes the following test cases:

- `bes CLI is installed and accessible`: Verifies the `bes` command is found in the PATH.
- `No environment is pre-installed (bes status)`: Checks if BeSman reports no environments installed initially.
- `MLAssessment-RT-env is listed in bes list -env`: Confirms the `MLAssessment-RT-env` definition exists in BeSman's available list.
- `bes install -env MLAssessment-RT-env -V 0.0.1 fails as expected due to missing files`: Asserts that the installation fails with specific error messages if required files are not found (this test expects a failure based on current BeSman setup).
- `Python virtual environment is created in expected path`: Checks for the existence of the virtual environment directory.
- `python3 exists on PATH after install`: Verifies `python3` is accessible within the activated virtual environment.
- `pip exists inside virtual environment`: Confirms `pip` is available within the virtual environment.
- `pytest is installed in virtual environment`: Checks for the `pytest` package.
- `adversarial-robustness-toolbox is installed in virtual environment`: Checks for the `adversarial-robustness-toolbox` package.
- `Jupyter Notebook is importable in virtual environment`: Verifies that the `notebook` package can be imported.
- `Jupyter kernel is registered with ipykernel name`: Ensures a Jupyter kernel corresponding to the environment is registered.
- `Assessment datastore repo is cloned at expected path`: Confirms the assessment datastore repository is cloned.
