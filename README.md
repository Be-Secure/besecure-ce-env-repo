# BeS Environment Scripts

A **BeS Envrionment** is a controlled testing and patching ground for security testing and patching of open source projects, tools and ML models. All the tools and utilities necesary to carry out a cybersecurity task on an OSS artifact is preinstalled in the BeS Environment. Ethical hackers, known as red teamers, utilitze these envrionment to attack a system to identify vulnerabilities and weaknesses. A blue teaming environment is a defensive environment designed to protect against and respond to simulated cyberattacks. 

A **BeS Environment Script** is file that contains instructions for setting up and configuring a BeS Environment. The necessary tools, dependencies, and settings required for a specific software or project environment are installed using the environment script. It typically includes commands or directives to install/manage libraries, frameworks, databases, and other components needed to run the software or project successfully. Environment scripts automate the setup process, ensuring consistency and reproducibility across different environments or systems. They are commonly used in software development, testing, deployment, and other related tasks to streamline the environment setup and configuration. This repository contains environment scripts for projects tracked by [Be-Secure](https://github.com/Be-Secure) community.

### Features

- **Customizable Environment Scripts:** BeSman supports the use of environment variables, enabling users to define dynamic values that can be easily modified or shared. This flexibility allows for greater adaptability and customization of the environment setup.
- **Recyclable Environment Scripts:** The environment scripts are recyclable thanks to its lifecycle functions.
- **Easier Environment Setup:**  The environment helps security professionals to reduce the turn around time for assessment of Open Source projects, AI Models, Model Datasets leaving them focus on the assessment task rather than setting up environment for it.
   
## Types of Environment

BeS Environments for open source projects & models are categorized as following.

1. **Red Teaming Environments(RT)**: Installs all the tools/utilities required for a security analyst to perform vulnerability assessment, create exploits etc.
2. **Blue Teaming Environments(BT)**: Installs all the tools required for a security professional to perform BT activities such as vulnerability remediation and patching.


## Lifecycle Functions of BeS Environment Scripts

A BeS environment script should implement the following lifecycle functions.

- **__besman_install:** Installs the required tools.
- **__besman_uninstall:** Removes the installed tools.
- **__besman_validate:** Checks whether all the tools are installed and required configurations are met.
- **__besman_update:** Update configurations of the tools.
- **__besman_reset:** Reset the environment to the default state.

## Two Ways of BeS Envrionment Implementation

A BeS environment can be implemented in two ways,

### 1. Basic Environment Script

In this type of environment script, the developer has to code all the required steps to install the tools. Its lightweight and no overhead of additional automation frameworks.

**Skeletal Code**

    #!/bin/bash

    function __besman_install {
    }

    function __besman_uninstall {
    }

    function __besman_update {
    }

    function __besman_validate {
    }

    function __besman_reset {
    }

### 2. Advanced Envrionment Scripts

The advanced implemention of BeS environment script uses ansible roles to install the required tools. The major advantage here is the tools can be programatically configured and the components are reusable.

**Skeletal Code**

    #!/bin/bash

    function __besman_install {
        __besman_check_vcs_exist || return 1 # Checks if GitHub CLI is present or not.
        __besman_check_github_id || return 1 # checks whether the user github id has been populated or not under BESMAN_USER_NAMESPACE 
        __besman_check_for_ansible || return 1 # Checks if ansible is installed or not.
        __besman_create_roles_config_file # Creates the role config file with the parameters from env config
        
        # Requirements file is used to list the required ansible roles. The data for requirements file comes from BESMAN_ANSIBLE_ROLES env var.
        # This function updates the requirements file from BESMAN_ANSIBLE_ROLES env var.
        __besman_update_requirements_file 
        __besman_ansible_galaxy_install_roles_from_requirements # Downloads the ansible roles mentioned in BESMAN_ANSIBLE_ROLES to BESMAN_ANSIBLE_ROLES_PATH
        # This function checks for the playbook BESMAN_ARTIFACT_TRIGGER_PLAYBOOK under BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH.
        # The trigger playbook is used to run the ansible roles.
        __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
        [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook # Creates the trigger playbook if not present.
        # Runs the trigger playbook. We are also passing these variables - bes_command=install; role_path=$BESMAN_ANSIBLE_ROLES_PATH
        __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
        # Clones the source code repo.
        if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
            __besman_echo_white "The clone path already contains dir names $BESMAN_ARTIFACT_NAME"
        else
            __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
            __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
            cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
            cd "$HOME"
        fi

        if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]] 
        then
            __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
        else
            __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
            __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1

        fi
        # Please add the rest of the code here for installation
    }

    function __besman_uninstall {
        __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
        [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
        __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=remove role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
        if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
            __besman_echo_white "Removing $BESMAN_ARTIFACT_DIR..."
            rm -rf "$BESMAN_ARTIFACT_DIR"
        else
            __besman_echo_yellow "Could not find dir $BESMAN_ARTIFACT_DIR"
        fi
        # Please add the rest of the code here for uninstallation
    }

    function __besman_update {
        __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
        [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
        __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=update role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
        # Please add the rest of the code here for update
    }

    function __besman_validate {
        __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
        [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
        __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=validate role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
        # Please add the rest of the code here for validate

    }

    function __besman_reset {
        __besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"
        [[ "$?" -eq 1 ]] && __besman_create_ansible_playbook
        __besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=reset role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1
        # Please add the rest of the code here for reset
    }

## Usage

### 1. Install BeSman

Install BeSman cli by referring this [link](https://github.com/Be-Secure/BeSman?tab=readme-ov-file#installation).

### 2. Set your GitHub/GitLab id

The environment will use the variable `BESMAN_USER_NAMESPACE` to clone the source code repo and assessment datastore repo from your namespace.

To set it, run..

    $ bes set BESMAN_USER_NAMESPACE <id>

`Note: It is assumed that the source code repo as well as the assessment datastore repo has been forked to your namespace before you install an environment. Make sure you have git configured in your system for a seamless experience.`

### 3. List environments

BeSman has a set of available environments. To get it, run the below command.

    $ bes list -env

### 4. Install an environment

#### 4.1 Edit environment configuration(optional)

Each environment has a configuration file with it. If you wish to edit some environment configuration then run,

`IMPORTANT: If you are using a common environment to assess multiple artifacts, you will have to do this step.`

1. Run the below command to download the environment configuration. The file will be downloaded to `$HOME` dir.

        bes config -env <environment name> -V <version>

2. Open the file in your editor. The file will be available in your `$HOME` dir under the name `besman-<environment name>-config.yaml`
3. Fill in the missing values.

#### 4.2 Install command

From the list of environments (from list command) choose the environment you wish to install.

    $ bes install -env <environment name> -V <version>

### 5. Uninstall an environment

To uninstall an environment run the below command,

    $ bes uninstall -env <environment name> -V <version>

### 6. Other commands

You can get the complete list of commands using 

    $ bes help

For more info regarding a command,

    $ bes help <command>


## Contribution Guide

Thank you for taking your time to contribute to Be-Secure Environment Repo. Please check the [developer-guide](./developer-guide.md) for instructions on how to develop your environment script.

This guide outlines the process for contributing to the BeSEnvironment Script, focusing on the adoption of a Test-Driven Methodology for evaluating tools and projects within the BeSecure framework. Contributors are expected to follow these guidelines to ensure consistency and quality in the development process.

### Getting Started
**Fork and Clone Repositories:** 
Begin by forking the env and test repositories. Clone them to your local development environment to start working on the BeSEnvironment.

**Set Up Development Environment:** Ensure your development environment meets the prerequisites for working with the BeSEnvironment Script. This may involve setting up virtual environments, Docker, or Ansible, depending on the project's needs.

### Development Workflow
**Test-Driven Development (TDD):**
Start by understanding the requirements for the tools and projects within the BeSecure framework.
Write skeleton test cases for the BeSEnvironment, covering the following actions:
- install: Installs the required tools.
- uninstall: Removes the installed tools.
- validate: Checks whether all tools are installed and required configurations are met.
- update: Updates configurations of the tools.
- reset: Resets the environment to the default state.

**Implement Features:**
Develop features and functionalities for the BeSEnvironment, ensuring each meets the criteria outlined in the test cases.
Regularly run the test cases to guide your development, aiming to pass all tests.

**Continuous Integration and Continuous Deployment (CI/CD):**
Integrate a CI/CD pipeline in both the env and test repositories.
Ensure the pipeline automatically runs the test cases against new commits to verify the integrity of the environment.

**Playbook Development:**
Develop a skeleton Ansible playbook or Docker compose file for the BeSEnvironment.
Write skeleton test cases for each playbook lifecycle method:
- __besman_init()
- __besman_execute()
- __besman_prepare()
- __besman_publish()
- __besman_cleanup()
- __besman_launch()

Implement the playbook methods, ensuring each passes its corresponding test case.

# Usage

## 1. Install BeSman

Install BeSman cli by referring this [link](https://github.com/Be-Secure/BeSman?tab=readme-ov-file#installation).

## 2. Set your GitHub/GitLab id

The environment will use the variable `BESMAN_USER_NAMESPACE` to clone the source code repo and assessment datastore repo from your namespace.

To set it run,

    $ bes set BESMAN_USER_NAMESPACE <id>

`Note: It is assumed that the source code repo as well as the assessment datastore repo has been forked to your namespace before you install an environment. Make sure you have git configured in your system for a seamless experience.`

## 3. List environments

BeSman has a set of available environments. To get it, run the below command.

    $ bes list -env

## 4. Install an environment

### 4.1 Edit environment configuration(optional)

Each environment has a configuration file with it. If you wish to edit some environment configuration then run,

`IMPORTANT: If you are using a common environment to assess multiple artifacts, you will have to do this step.`

1. Run the below command to download the environment configuration. The file will be downloaded to `$HOME` dir.

        bes config -env <environment name> -V <version>

2. Open the file in your editor. The file will be available in your `$HOME` dir under the name `besman-<environment name>-config.yaml`
3. Fill in the missing values.

### 4.2 Install command

From the list of environments (from list command) choose the environment you wish to install.

    $ bes install -env <environment name> -V <version>

## 5. Uninstall an environment

To uninstall an environment run the below command,

    $ bes uninstall -env <environment name> -V <version>

## 6. Other commands

You can get the complete list of commands using 

    $ bes help

For more info regarding a command,

    $ bes help <command>


# Developer Guide

Thank you for taking your time to contribute to Be-Secure Environment Repo. Please check the [developer-guide](./developer-guide.md) for instructions on how to develop your environment script.

<!-- # Available environments.

### Contribution Submission
**Code Review:**
Once development is complete, and all tests are passing, submit a pull request to the env and test repositories.
Engage with the BeSecure community during the code review process to refine your contribution.

1. [Fastjson](fastjson/0.0.1/besman-fastjson-RT-env.sh)
2. [jackson-databind](jackson-databind/0.0.1/besman-jackson-databind-RT-env.sh)
3. [opencti](opencti/0.0.1/besman-opencti-RT-env.sh)
4. [zaproxy](zaproxy/0.0.1/besman-zaproxy-RT-env.sh)
5. [ML Assessment](ML/0.0.1/besman-ML-RT-env.sh)
6. [dubbo](dubbo/0.0.1/besman-dubbo-RT-env.sh)
7. [struts](struts/0.0.1/besman-struts-RT-env.sh)

### Best Practices
**Code Quality:** Ensure your code is clean, well-documented, and follows the project's coding standards.

**Testing:** Adopt a test-driven development approach, writing tests before implementing features.

1. [Fastjson](fastjson/0.0.1/besman-fastjson-BT-env.sh)
2. [HWC-API](HWC-API/0.0.1/besman-HWC-API-BT-env.sh)
3. [jackson-core](jackson-core/0.0.1/besman-jackson-core-BT-env.sh)
4. [jackson-databind](jackson-databind/0.0.1/besman-jackson-databind-BT-env.sh)
5. [lettuce](lettuce/0.0.1/besman-lettuce-BT-env.sh)
6. [zaproxy](zaproxy/0.0.1/besman-zaproxy-BT-env.sh)
7. [druid](druid/0.0.1/besman-druid-BT-env.sh) -->

