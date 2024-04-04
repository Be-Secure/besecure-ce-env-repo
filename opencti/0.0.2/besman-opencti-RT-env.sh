#!/bin/bash

function __besman_install_opencti-RT-env
{
export BESMAN_LIGHT_MODE=True
cd /home/neeraj/CRS_Work/opencti-env-script

# Function to check URL accessibility
check_url() {
    # Perform curl request
    if curl --silent --fail localhost:4000 > /dev/null; then
        return 0  # URL is accessible
    else
        return 1  # URL is not accessible
    fi
}

# Call first shell script in a new terminal
echo -e "\nsetting-up required dependency for opencti -
           \nredis, \nredis-insights, \nelasticsearch, \nkibana, \nminio, \njaegertracing"
gnome-terminal -- ./opencti-dev-env.sh
echo -e "\nall required dependencies are up"


# Call second shell script in a new terminal
echo -e "\nsetting-up graphql API"
gnome-terminal -- ./opencti-graphql-env.sh


# Check URL accessibility
echo -e "Graphql API is getting deployed, it will take couple of mins"
echo -e "Checking Graphql running status ..."
while ! check_url; do
    echo -n "---"
    sleep 5
done

echo -e "Graphql API is up and running now."

# Once URL is accessible, proceed to execute 3rd and 4th scripts
# Call third shell script in a new terminal
echo -e "\nsetting-up front-end module"
gnome-terminal -- ./opencti-front-end-env.sh
echo -e "Front-end is starting ..."

# Wait for the third script to finish
wait

# Call fourth shell script in a new terminal
echo -e "\nsetting-up worker"
gnome-terminal -- ./opencti-worker-env.sh
echo -e "Worker is starting ..."



}

function __besman_uninstall_opencti-RT-env
{
    
}

function __besman_update_opencti-RT-env
{
    
}

function __besman_validate_opencti-RT-env
{
    
}

function __besman_reset_opencti-RT-env
{
    
}
