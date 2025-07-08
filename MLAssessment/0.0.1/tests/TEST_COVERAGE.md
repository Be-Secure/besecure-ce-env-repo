# MLAssessment RT Environment Bats Test Coverage

This repository contains a suite of [Bats (Bash Automated Testing System)](https://bats-core.readthedocs.io/en/stable/) tests for validating the setup and functionality of the BeSman MLAssessment RT environment.

---

## Overview

These integration tests ensure that:

- The `bes` CLI is installed and accessible.
- No environment is pre-installed before testing.
- The `MLAssessment-RT-env` environment is listed as available.
- The installation process for `MLAssessment-RT-env` completes successfully.
- The `bes reload` command works and sources the correct configuration.
- The Python virtual environment is created at the expected path.
- `python3` and `pip` are available inside the virtual environment.
- Key Python packages (`pytest`, `adversarial-robustness-toolbox`, `notebook`) are installed in the virtual environment.
- Jupyter Notebook is importable and the Jupyter kernel is registered.
- The assessment datastore repository is cloned at the expected path.

---

## Getting Started

### Prerequisites

- [Bats (Bash Automated Testing System)](https://bats-core.readthedocs.io/en/stable/installation.html) installed.
- BeSman installed and initialized.
- The BeSman environment definitions (especially `MLAssessment-RT-env`) are available in your BeSman repository.

### Running the Tests

1. Navigate to the `tests` directory containing `testEnv-MLAssessment-installation.bats`.
2. Run the tests using Bats:

    ```bash
    bats testEnv-MLAssessment-installation.bats
    ```

---

## Notes

- Each test is isolated and validates a specific aspect of the environment setup or functionality.
- Ensure all required environment variables are set in the `setup()` function of the test file.
- Review test output for any failures and refer to the corresponding section in the test file for debugging.