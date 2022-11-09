# External repo for BeSman utility.

The repository contains environment scripts for projects tracked by [Be-Secure](https://github.com/Be-Secure) community.

# Available environments.

1. [Fastjson RT/BT environments](https://github.com/Be-Secure/besecure-ce-env-repo/tree/master/fastjson/0.0.1)
2. [Java Spring RT/BT environments](https://github.com/Be-Secure/besecure-ce-env-repo/tree/master/javaSpring/0.0.1)
3. [Python Django RT/BT environments](https://github.com/Be-Secure/besecure-ce-env-repo/tree/master/pythonDjango/0.0.1)
4. [BeSman dev environment](BeSman/0.0.1/besman-BeSman-dev-env.sh)

# Usage

The environment scripts are executed using [BeSman](https://github.com/Be-Secure/BeSman.

1. Install BeSman utility by following the instructions [here](https://github.com/Be-Secure/BeSman#readme).
2. Run the below command to update the local list of environments.
   
   `$ bes update`
3. To view the updated list, run the below command.
   
   `$ bes list`
4. The environments can be installed now.
5. To install, run the below command.
   
   `$ bes install -env <namespace>/<repo name>/<environment> -V <version>`

# Create your environment repository.

## Setting up the repository

1. Create the repo.
2. Follow the folder structure from [Be-Secure's environment repository](https://github.com/Be-Secure/besecure-ce-env-repo) for your environment script.
3. Follow the standards specified in the [checklist](https://be-secure.github.io/Be-Secure/checklist/) for naming the environment.
4. Create a list.txt file and make and entry of the environment in the below format.
   
   `<namespace>/<repo name>/<environment name>,<version1>,<version2>..`
   `<namespace>/<repo name>/<environment name>,<version1>,<version2>..`

## Updating BeSman list

1. Install BeSman.
2. Open the file, `~/.besman/etc/user-config.cfg`.
3. Append the namespace and repo name against the environment variable `BESMAN_ENV_REPOS`.
   
   `BESMAN_ENV_REPOS=<namespace>/<repo name>,<namespace>/<repo name>`...
4. Run the command to update the list.
   
   `$ bes update`
5. To view the update environment list.
  
   `$ bes list`

6. You can follow besman commands to execute the environment script.


  
