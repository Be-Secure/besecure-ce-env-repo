#!/bin/bash

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
echo -e "\nExecuting dev script"
gnome-terminal -- ./opencti-dev-env.sh
echo -e "Dev script - end"


# Call second shell script in a new terminal
echo -e "\nExecuting graphql script"
gnome-terminal -- ./opencti-graphql-env.sh


# Check URL accessibility
echo -e "Checking Graphql URL accessibility..."
while ! check_url; do
    echo -e "\n Graphql server is not up and URL is not accessible. Waiting for 15 seconds before retrying..."
    sleep 15
done

echo -e "Graphql script - end"

# Once URL is accessible, proceed to execute 3rd and 4th scripts
# Call third shell script in a new terminal
echo -e "\nExecuting front-end script"
gnome-terminal -- ./opencti-front-end-env.sh
echo -e "Front-end script - end"

# Wait for the third script to finish
wait

# Call fourth shell script in a new terminal
echo -e "\nExecuting worker script"
gnome-terminal -- ./opencti-worker-env.sh
echo -e "Worker script - end"

