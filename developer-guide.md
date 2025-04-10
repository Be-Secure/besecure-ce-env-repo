# Developer guide for BeSman Environment Repo

Thank you for taking your time to contribute environments to this repo. This document will help you get started on working on BeSman environment scripts or BeS env for short.

## Repo Structure

```code
. ------------------------------------------------------------- Root dir
├── README.md ------------------------------------------------- Readme file containing info regarding the repo.
├── checklist.md ---------------------------------------------- File containing certain checks and standards that we follow
├── list.txt -------------------------------------------------- File containing the list of environments available.
├── classic-model --------------------------------------------- Artifact dir which contains the environments.
│   └── 0.0.1 ------------------------------------------------- Version of the environment.
│       ├── besman-classic-model-RT-env-config.yaml ----------- Configuration of the classic RT environment.
│       └── besman-classic-model-RT-env.sh -------------------- RT env script for classic models. 
```

## Things you should know

Here are some things you should know before you start working on an environment script.

### Be-Secure

Be-Secure is an open-source project that is led by the Be-Secure Community. This community is transforming next generation Application security threat models and security assessment playbooks into global commons. Be-Secure is an ecosystem project for the open source security community. Among the tools included in the suite are open source security tools, sandbox environments for security assessments, as well as custom utilities written for the open source security community. Security assessment capabilities are provided by the platform through the aggregation of various open source security assessment services and utilities.

[Learn more](https://be-secure.github.io/Be-Secure/)

### BeSman

BeSman (pronounced as ‘B-e-S-man’) is a command-line utility designed for creating and provisioning customized security environments. It helps security professionals to reduce the turn around time for assessment of Open Source projects, AI Models, Model Datasets leaving them focus on the assessment task rather than setting up environment for it.

It also provides seamless support for creating and executing BeS playbooks, enabling users to automate complex workflows and tasks. With BeSman, users can efficiently manage and execute playbooks, streamlining their processes and enhancing productivity.

[Learn more](https://github.com/Be-Secure/BeSman)

### BeSman environments

A BeSman environment script is a script file that contains instructions for setting up and configuring the necessary tools, dependencies, and settings required for a specific software or project environment. It typically includes commands or directives to install/manage libraries, frameworks, databases, and other components needed to run the software or project successfully. Environment scripts automate the setup process, ensuring consistency and reproducibility across different environments or systems. They are commonly used in software development, testing, deployment, and other related tasks to streamline the environment setup and configuration

#### Types of environments

Here are the types of environments

- **Red Team environemnts(RT env)** - The env installs all the tools/utilities required for a security analyst to perform vulnerability assessment, create exploits etc.
- **Blue Team environment(BT env)** - The env would contain the instruction to install the tools required for a security professional to perform BT activities such as vulnerability remediation and patching.
- **Assessment environment** - The assessment environment is environment that is used to perform assessments only.

[Learn more](./README.md)

### BeSman playbooks

A playbook in Be-Secure ecosystem refers to a set of instructions for completing a routine task. Not to be confused with an Ansible playbook. There can be automated(.sh), interactive(.ipynb) & manual(*.md) playbooks. It helps the security analyst who works in a BeSLab instance to carry out routine tasks in a consistent way. These playbooks are automated and are executed using the BeSman utility.

[Learn more](https://github.com/Be-Secure/besecure-playbooks-store)


## Types of environment execution

There are two methods of execution which your environment script can follow

1. Using Ansible - All the tools are installed using ansible roles. This is the default environment.
2. Basic environment - You will have to provide all the steps to install and setup the tools.

[Learn more](./README.md#two-ways-of-execution)


## Branching Strategy

Learn about the branching strategy that we follow from [here](./CONTRIBUTING.md#branching-and-release-strategy).


## Developing your environment script.

**Pre-requisites**

1. BeSman.
2. Fork this repo and clone it to your local machine.

### Steps

1. Open terminal
2. Make sure you have installed BeSman by running the folowing command,

        bes

3. Run the below command to create the environment script. This would create the environment script file as well as the environment configuration file.

    1. For basic environment
        
            bes create -env <environment name> -V <version> basic

        Refer below example

            bes create -env fastjson-RT-env -V 0.0.1 basic
    
    2. For ansible based execution

            bes create -env <environment name> -V <version>

        Refer below example

            bes create -env fastjson-RT-env -V 0.0.1

The create command will ask for the local path to clone the env repo locally and would create a new env folder and environment template files to the newly cloned repo.

\[Note:\] : The "Environment Name" should not contain any underscore, hyphen or space. Any occurence of these character should be replaced with camel case format.

4. Update the code in enviroment template files as required.

5. Test the changes locally. Once changes are done push the changes to github repo forked in your namespace.

6. Raise a PR to get the repo merged to develop branch of Be-Secure environments repo.

## Explaining the environment script(ansible role based)

Each environment script has 5 lifecycle methods. [Refer here](./README.md#lifecycle-functions-of-besman-environment-scripts).

Lets take [this](https://github.com/Be-Secure/besecure-ce-env-repo/blob/develop/fastjson/0.0.1/besman-fastjson-RT-env.sh) environment script as an example.

We will split each function and explain separately.

### install()

The job of the `install` function is to install all the tools necessary for the environment. For example, if its an assessment environemnt, it should 
- install a lit of assessment tools for assessment.
- clone project source code(if required) for performing the assessments.
- clone the assessment datastore for storing all the assessment report.

```code
function __besman_install
{

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

```

All the lines that start with a `__besman__` is a function call and the function definition will be written inside [BeSman source code](https://github.com/Be-Secure/BeSman/blob/develop/src/main/bash/besman-env-helpers.sh). 

The above piece of code uses ansible roles to install all the tools required. You don't have to learn about ansible roles to develop your environment script. This is simply one of the approach that we follow. We will see how to add the tools to install shortly.

We wil explain the functions written in the above piece of code.

- `__besman_check_vcs_exist` - Checks if the user's machine has a version control system installed (vcs). The value of vcs is configurable. It can be `git` or `gh(GitHub cli)`. You can use the `set` command to see how to set the value - `bes help set`.
- `__besman_check_github_id` - Check if the user's GitHub or Gitlab id has been configured or not. The code will prompt you to enter it if its not present. This is to determine from which namespace your artifact source code and assessment datastore should be downloaded from.
- `__besman_check_for_ansible` - Checks if ansible is present in the machine or not.
- `__besman_create_roles_config_file` - Creates a configuration file for the tools. This is an ansible specific thing. The configuration parameters are taken from the environment configuration file. We will see it down below.
- `__besman_update_requirements_file` - Again a ansible specific file to store the list of roles to be downloaded. The list is taken from the environment configuration file.
- `__besman_ansible_galaxy_install_roles_from_requirements` - Function downloads the roles specified in the `requirements` file.
- `__besman_check_for_trigger_playbook "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK"` - This is an ansible specific task. Checks for a playbook file to trigger the tools installation.
- `[[ "$?" -eq 1 ]] && __besman_create_ansible_playbook` - Creates the trigger playbook if not already present.
- `__besman_run_ansible_playbook_extra_vars "$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH/$BESMAN_ARTIFACT_TRIGGER_PLAYBOOK" "bes_command=install role_path=$BESMAN_ANSIBLE_ROLES_PATH" || return 1` - This is the step where we install tools.
- Below code downloads the artifact source code repo.
    ```code
    if [[ -d $BESMAN_ARTIFACT_DIR ]]; then
        __besman_echo_white "The clone path already contains dir names $BESMAN_ARTIFACT_NAME"
    else
        __besman_echo_white "Cloning source code repo from $BESMAN_USER_NAMESPACE/$BESMAN_ARTIFACT_NAME"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "$BESMAN_ARTIFACT_NAME" "$BESMAN_ARTIFACT_DIR" || return 1
        cd "$BESMAN_ARTIFACT_DIR" && git checkout -b "$BESMAN_ARTIFACT_VERSION"_tavoss "$BESMAN_ARTIFACT_VERSION"
        cd "$HOME"
    fi
    ``` 
- Below code downloads the assessment datastore repo.
    ```code
    if [[ -d $BESMAN_ASSESSMENT_DATASTORE_DIR ]] 
    then
        __besman_echo_white "Assessment datastore found at $BESMAN_ASSESSMENT_DATASTORE_DIR"
    else
        __besman_echo_white "Cloning assessment datastore from $\BESMAN_USER_NAMESPACE/besecure-assessment-datastore"
        __besman_repo_clone "$BESMAN_USER_NAMESPACE" "besecure-assessment-datastore" "$BESMAN_ASSESSMENT_DATASTORE_DIR" || return 1
    fi
    ```

### uninstall(), update(), validate(), reset()

Similar to the above code you can read throug the rest of the functions.

### Environment configuration file

A key point to the environment file is that the tools that get installed in the environment script can be configured. We use an environment configuration file for this. This file is created along with your environment script when you ran the `create` command.

Taking the same [environment](https://github.com/Be-Secure/besecure-ce-env-repo/blob/develop/fastjson/0.0.1/besman-fastjson-RT-env.sh) as above. Lets take a look at its [configuration file](https://github.com/Be-Secure/besecure-ce-env-repo/blob/develop/fastjson/0.0.1/besman-fastjson-RT-env-config.yaml).

```yaml
---
# If you wish to update the default configuration values, copy this file and place it under your home dir, under the same name.
# These variables are used to drive the installation of the environment script.
# The variables that start with BESMAN_ are converted to environment vars.
# If you wish to add any other vars that should be used globally, add the var using the below format.
# BESMAN_<var name>: <value>
# If you are not using any particular value, remove it or comment it(#).
#*** - These variables should not be removed, nor left empty.
# Used to mention where you should clone the repo from, default value is Be-Secure

#  project/ml model/training dataset.
BESMAN_ARTIFACT_TYPE: project 

# Name of the artifact under assessment.
BESMAN_ARTIFACT_NAME: fastjson

# Version of the artifact under assessment.
BESMAN_ARTIFACT_VERSION: 1.2.24
# Source code url of the artifact under assessment.
BESMAN_ARTIFACT_URL: https://github.com/Be-Secure/fastjson

# This variable stores the name of the environment file.
BESMAN_ENV_NAME: fastjson-RT-env

# The path where you wish to clone the source code of the artifact under assessment.
# If you wish to change the clone path, provide the complete path.
BESMAN_ARTIFACT_DIR: $HOME/$BESMAN_ARTIFACT_NAME

# The path where we download the assessment and other required tools during installation.
BESMAN_TOOL_PATH: /opt

# Organization/lab/individual.
BESMAN_LAB_TYPE: Organization

# Name of the owner of the lab. Default is Be-Secure.
BESMAN_LAB_NAME: Be-Secure

# This is the local dir where we store the assessment reports. Default is home.
BESMAN_ASSESSMENT_DATASTORE_DIR: $HOME/besecure-assessment-datastore

# The remote repo where we store the assessment reports.
BESMAN_ASSESSMENT_DATASTORE_URL: https://github.com/Be-Secure/besecure-assessment-datastore

# The path where we download the ansible role of the assessment tools and other utilities
BESMAN_ANSIBLE_ROLES_PATH: $BESMAN_DIR/tmp/$BESMAN_ARTIFACT_NAME/roles

# The list of tools you wish to install. The tools are installed using ansible roles.# To get the list of ansible roles run 
#   $ bes list --role
#add the roles here. format - <Github id>/<repo name>,<Github id>/<repo name>,<Github id>/<repo name>,...
BESMAN_ANSIBLE_ROLES: Be-Secure/ansible-role-bes-java,Be-Secure/ansible-role-oah-maven,Be-Secure/ansible-role-oah-eclipse,Be-Secure/ansible-role-oah-docker,Be-Secure/ansible-role-oah-sonarQube,Be-Secure/ansible-role-oah-sbomGenerator,Be-Secure/ansible-role-oah-fossology,Be-Secure/ansible-role-oah-criticality_score

# Sets the path of the playbook with which we run the ansible roles.
# Default path is ~/.besman/tmp/<artifact name dir>/
BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH: $BESMAN_DIR/tmp/$BESMAN_ARTIFACT_NAME

# Name of the trigger playbook which runs the ansible roles.
BESMAN_ARTIFACT_TRIGGER_PLAYBOOK: besman-$BESMAN_ARTIFACT_NAME-RT-trigger-playbook.yaml

# If the users likes to display all the skipped steps, set it to true.
# Default value is false
BESMAN_DISPLAY_SKIPPED_ANSIBLE_HOSTS: false


# The default values of the ansible roles will be present in their respective repos.
# You can go to https://github.com/Be-Secure/<repo of the ansible role>/blob/main/defaults/main.yml.
# If you wish to change the default values copy the variable from the https://github.com/Be-Secure/<repo of the ansible role>/blob/main/defaults/main.yml
# and paste it here and change the value.
# Format is <variable name>: <value> 
# Eg: openjdk_version: 11
openjdk_version: 8
```

#### BESMAN_ variables

All the variables that start with `BESMAN_` will be converted into environment variables and will be used in the environment execution as well as playbook execution. So if you want to add a variable that can be used in the environment installation, you can use this option.

#### Ansible role variable

The below contains the ansible role related variables that is used in the environment script to download and install ansible roles.

The variable `BESMAN_ANSIBLE_ROLES` contain the list of ansible tools that will be installed in the format `<namespace>/<repo name>`

To get the list of available tools as ansible roles, run the below command 

    bes list --role

```yaml
# The path where we download the ansible role of the assessment tools and other utilities
BESMAN_ANSIBLE_ROLES_PATH: $BESMAN_DIR/tmp/$BESMAN_ARTIFACT_NAME/roles

# The list of tools you wish to install. The tools are installed using ansible roles.# To get the list of ansible roles run 
#   $ bes list --role
#add the roles here. format - <Github id>/<repo name>,<Github id>/<repo name>,<Github id>/<repo name>,...
BESMAN_ANSIBLE_ROLES: Be-Secure/ansible-role-bes-java,Be-Secure/ansible-role-oah-maven,Be-Secure/ansible-role-oah-eclipse,Be-Secure/ansible-role-oah-docker,Be-Secure/ansible-role-oah-sonarQube,Be-Secure/ansible-role-oah-sbomGenerator,Be-Secure/ansible-role-oah-fossology,Be-Secure/ansible-role-oah-criticality_score

# Sets the path of the playbook with which we run the ansible roles.
# Default path is ~/.besman/tmp/<artifact name dir>/
BESMAN_ARTIFACT_TRIGGER_PLAYBOOK_PATH: $BESMAN_DIR/tmp/$BESMAN_ARTIFACT_NAME

# Name of the trigger playbook which runs the ansible roles.
BESMAN_ARTIFACT_TRIGGER_PLAYBOOK: besman-$BESMAN_ARTIFACT_NAME-RT-trigger-playbook.yaml

# If the users likes to display all the skipped steps, set it to true.
# Default value is false
BESMAN_DISPLAY_SKIPPED_ANSIBLE_HOSTS: false

```

#### Role configuration variables

The ansible roles has a configuration file of its own and which can be used to control the execution of roles.

For example, the role `Be-Secure/ansible-role-bes-java` is a role to install java in your machine and the below configuration is used to control the version of java installed.

```yaml
openjdk_version: 8
```

These variables names are something specific to each roles. Means that the above configuration variable `openjdk_version: 8` is something specific to ansible role `Be-Secure/ansible-role-bes-java`.

To know the list of variables of each role, go to `<role repo>/defaults/main.yml`.

## Explaining the environment script(basic)

If you do not wish to go with ansible roles and keep the environment script lightweight, you can go with a `basic` environment.

Lets take [this](https://github.com/Be-Secure/besecure-ce-env-repo/blob/develop/classic-model/0.0.1/besman-classic-model-RT-env.sh) example.

This is a common environment for assessing different classic models(not llms). The assessment tools installed are `counterfit` and `watchtower`.

Similar to this example, you should write all the steps to install, update, validate, update and reset the tools that your environment requires.

If we take the above `fastjson-RT-env` example and convert it to a basic environment, then it look something like this.

```code
function __besman_install(){
    sudo apt install openjdk-$BESMAN_JAVA_VERSION-jdk
    sudo apt install maven
    # Code to install eclipse, sonarqube, spdx-sbom-generator.
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
    
}

function __besman_uninstall(){
    sudo apt remove openjdk-$BESMAN_JAVA_VERSION-jdk
    sudo apt remove maven
    # Code to remove eclipse, sonarqube, spdx-sbom-generator.

    # code to remove the cloned repo
    ...
    ...
    ..

}

```

The configuration would look something like this

```yaml
---
# If you wish to update the default configuration values, copy this file and place it under your home dir, under the same name.
# These variables are used to drive the installation of the environment script.
# The variables that start with BESMAN_ are converted to environment vars.
# If you wish to add any other vars that should be used globally, add the var using the below format.
# BESMAN_<var name>: <value>
# If you are not using any particular value, remove it or comment it(#).
#*** - These variables should not be removed, nor left empty.
# Used to mention where you should clone the repo from, default value is Be-Secure
#  project/ml model/training dataset
BESMAN_ARTIFACT_TYPE: project 

# Name of the artifact under assessment.
BESMAN_ARTIFACT_NAME: fastjson

# Version of the artifact under assessment.
BESMAN_ARTIFACT_VERSION: 1.2.24
# Source code url of the artifact under assessment.
BESMAN_ARTIFACT_URL: https://github.com/Be-Secure/fastjson

# This variable stores the name of the environment file.
BESMAN_ENV_NAME: fastjson-RT-env

# The path where you wish to clone the source code of the artifact under assessment.
# If you wish to change the clone path, provide the complete path.
BESMAN_ARTIFACT_DIR: $HOME/$BESMAN_ARTIFACT_NAME

# The path where we download the assessment and other required tools during installation.
BESMAN_TOOL_PATH: /opt

# Organization/lab/individual.
BESMAN_LAB_TYPE: Organization

# Name of the owner of the lab. Default is Be-Secure.
BESMAN_LAB_NAME: Be-Secure

# This is the local dir where we store the assessment reports. Default is home.
BESMAN_ASSESSMENT_DATASTORE_DIR: $HOME/besecure-assessment-datastore

# The remote repo where we store the assessment reports.
BESMAN_ASSESSMENT_DATASTORE_URL: https://github.com/Be-Secure/besecure-assessment-datastore

# Openjdk version to be installed.
BESMAN_JAVA_VERSION: 8

```

## Testing the new environments

Once you run the `create` command, BeSman automatically changes the configuration so that it will install the environments from your local `besecure-ce-env-repo` dir.

**Steps**

1. Run the list to get the list of environments

        bes list -env

    From the output message, you can see that BeSman is now pointing to your local environment dir.

2. Run the install command to test the environment

        bes install -env <environment name> -V <version>

## End objective for environments

You read above that the environments are used to install and manage the tools required for your activity. This is done so that the a [Be-Secure playbook](https://github.com/Be-Secure/besecure-playbooks-store/tree/develop?tab=readme-ov-file#bes-playbooks) would have all the required tools to perform an assessment and generate an [OSAR](https://be-secure.github.io/bes-schema/assessment-report/).

Read more about this in the [besecure-playbooks-store](https://github.com/Be-Secure/besecure-playbooks-store/tree/develop).