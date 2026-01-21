#!/bin/bash

echo "Welcome to the Healthchecks Installation Script"

echo "Please select one of the following options:"
echo "1. Install Healthchecks"
echo "2. Uninstall Healthchecks"
echo "3. Update Healthchecks"
echo "4. Reset Healthchecks"
echo "5. Validate Healthchecks Environment"
echo "6. Quit"

read -p "Enter your choice: " choice

__besman_install()
{
  echo "started"

  #installing Dependencies
  sudo apt update
  sudo apt install -y gcc python3-dev python3-venv libpq-dev libcurl4-openssl-dev libssl-dev

  mkdir webapps
  cd webapps

  python3 -m venv hc-venv
  source hc-venv/bin/activate
  pip3 install wheel # make sure wheel is installed in the venv
  git clone https://github.com/healthchecks/healthchecks.git
  pip install -r healthchecks/requirements.txt

#installing assessment tools
  pip install criticality-score

  sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.1.0.47736.zip
  sudo apt install unzip -y
  sudo unzip sonarqube-9.1.0.47736.zip
  sudo mv sonarqube-9.1.0.47736 SonarQube
  
  # Update system
  sudo apt-get update && sudo apt-get upgrade -y
  # Install dependencies
  sudo apt-get install -y git apache2 postgresql perl

  #Install Perl modules
  cpan install DBI DBD::Pg JSON::XS File::Basename

  # Set up PostgreSQL
  sudo -u postgres psql -c "CREATE DATABASE fossology;"
  sudo -u postgres psql -c "CREATE USER fossuser WITH PASSWORD 'unossspassword';"
  sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE fossology TO fossuser;"

  # Clone Fossology
  git clone https://github.com/fossology/fossology.git && cd fossology

  # Compile and install
  ./configure
  make
  sudo make install

  #clone spdx-sbom
  git clone https://github.com/HariPrasathKamaraj/spdx-sbom-generator.git

  

}

__besman_uninstall()
{
    echo "Started"

    pip uninstall -r healthchecks/requirements.txt

    pip uninstall criticality-score

     # Check if Python is installed
    if [ -n "$(which python3)" ]; then
        echo "Python is installed. Uninstalling..."
        sudo apt purge -y python3
    else
        echo "Python is not installed."
    fi

    if [ -d "webapps" ]; then
        rm -rf webapps
    else
        echo "There is no such directory"
    fi


}

__besman_update()
{
  # Navigate to the healthchecks directory
  if [ -d "webapps/healthchecks" ]; then
    cd webapps
    git pull origin dev_env
    cd ../
  else
    git clone https://github.com/healthchecks/healthchecks.git

  fi

  pip install -r requirements.txt

}

__besman_reset()
{
    __besman_uninstall
    __besman_install
}

__besman_validate()
{
    # Check if Python is installed
    if [ -z "$(which python3)" ]; then
        echo "Python is not installed"
        return 1
    else
        echo "Python is installed"
    fi

    #Check if healthchecks is available
    if [ ".\webapps\healthchecks" ]; then
        echo "healthchecks directory exists"
    else
        echo "No such directory: healthchecks"
    fi

    #Check if SonarQube is available
    if [ ".\webapps\SonarQube" ]; then
        echo "SonarQube is installed"
    else
        echo "SonarQube is not installed"
    fi

    #Check if spdx-sbom-generator is available spdx-sbom-generator
    if [ ".\webapps\spdx-sbom-generator" ]; then
        echo "spdx-sbom-generator is installed"
    else
        echo "spdx-sbom-generator is not installed"
    fi

    #Check if criticality_score is available
    if [ ".\webapps\hc-venv\lib\python3.10\site-packages\criticality_score" ]; then
        echo "criticality_score is installed"
    else
        echo "criticality_score is not installed"
    fi

    #Check if django is available
    if [ ".\webapps\hc-venv\lib\python3.10\site-packages\django" ]; then
        echo "django is installed"
    else
        echo "django is not installed"
    fi

    #Check if pip is available
    if [ ".\webapps\hc-venv\lib\python3.10\site-packages\pip" ]; then
        echo "pip is installed"
    else
        echo "pip is not installed"
    fi
    
    # Check if the virtual environment is activated
    if [ -z "$hc-venv" ]; then
        echo "Virtual environment is not activated"
        return 1
    else
        echo "Virtual environment is activated"
    fi
}

case $choice in
  1)
    echo "Installing Healthchecks..."
    __besman_install
    ;;
  2)
    echo "Uninstalling Healthchecks..."
    __besman_uninstall
    echo "uninstall completed"
    ;;
  3)
    echo "Updating Healthchecks..."
    __besman_update
    ;;
  4)
    echo "Resetting Healthchecks..."
    __besman_reset
    ;;
  5)
    echo "Validating Healthchecks Environment..."
    __besman_validate
    echo "Validation completed"
    ;;
  6)
    echo "Goodbye!"
    exit 0
    ;;
  *)
    echo "Invalid choice. Please try again."
    ;;
esac
 