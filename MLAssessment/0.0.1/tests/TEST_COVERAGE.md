---

# ML Assessment Runtime Environment Validation Suite

This document outlines the purpose and test coverage for the ML Assessment Runtime Environment's automated validation suite.

## 1. Purpose

This suite ensures the **integrity, functionality, and security readiness** of the ML Assessment Environment. It verifies that:

- All prerequisites are met.
- Configuration is accurate.
- Essential tools and dependencies (Python, virtual environment, ART, Jupyter, etc.) are correctly installed and functional.

**Why this matters (Cybersecurity Perspective):** A well-validated environment is foundational for reliable and secure machine learning assessments. It confirms we're building on a solid, predictable base.

## 2. Test Suite Overview

Our validation is split into three phases, each with its own BATS test file:

- **`01_test_prerequisites.bats`**: Checks if the core `bes` CLI is installed and ready.
- **`02_test_config_file.bats`**: Validates the environment's configuration settings (`besman-MLAssessment-RT-env-config.yaml`).
- **`03_test_install.bats`**: Confirms the environment's installation script runs successfully and all components are properly deployed and functional.

## 3. What We Test: Use Cases & Coverage

Here's a direct mapping of what we're testing and which test cases cover it.

### 3.1. **BeSman CLI Readiness**

_Ensures the core BeSman command-line tool is installed and working._

- `bes CLI is installed and accessible`
- `bes CLI responds to 'bes help' with correct output`
- `No environment is installed (bes status)` _(Checks for a clean slate before install)_
- `MLAssessment-RT-env is listed in bes list -env` _(Confirms environment is discoverable)_

### 3.2. **Configuration Integrity**

_Verifies that all environment settings in `besman-MLAssessment-RT-env-config.yaml` are correctly defined and populated._

- `All environment variables in config should not be empty`
- `Required environment variables have correct values` _(Checks specific values for paths, URLs, names, etc.)_

### 3.3. **Environment Installation & Functional Check**

_Confirms the environment installs correctly and all key components (Python, ART, Jupyter, etc.) are functional._

- `__besman_install function exists in env script`
- `__besman_install completes without errors`
- `Artifact directory is created after install`
- `BESMAN_ENV_DIR exists after install`
- `BESMAN_TOOLS_DIR exists after install`
- `ART repo is cloned inside BESMAN_TOOLS_DIR`
- `ART repository contains a .git directory`
- `ART repo inside BESMAN_TOOLS_DIR is a valid git repository`
- `Python virtual environment is created in expected path`
- `python3 exists on PATH after install` _(within the virtual environment)_
- `pip exists inside virtual environment`
- `pytest is installed in virtual environment`
- `adversarial-robustness-toolbox is installed in virtual environment`
- `Assessment datastore repo is cloned at expected path`
- `Python can execute inside virtual environment after install`
- `Jupyter Notebook is importable in virtual environment`
- `Jupyter kernel is registered with ipykernel name` _(Ensures Jupyter can use our environment)_

---
