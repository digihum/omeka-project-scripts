#!/bin/bash

# Color output
GREEN='\033[0;32m'
RESET='\033[0m'

################################################################################
# Deploy                                                                       #
################################################################################
BuildAndDeploy()
{
    env=$2

    # Make executable
    chmod +x scripts/build-application.sh
    chmod +x scripts/build-environment.sh
    chmod +x scripts/deploy-application.sh

    # Build application
    echo -e "${GREEN}Building application${RESET}"
    scripts/build-application.sh -b "$env"

    # Build environment
    echo -e "${GREEN}Building environment${RESET}"
    scripts/build-environment.sh -b "$env"

    # Deploy
    # echo -e "${GREEN}Deploying${RESET}"
    # scripts/deploy-application.sh -d "$env"

}

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "Runs build and deploy scripts"
   echo "Target depends on environment variable"
   echo
   echo "Syntax: build-and-deploy.sh [-h|b] ENVIRONMENT"
   echo "options:"
   echo "h     Print this Help."
   echo "b     Builds and deploys Omeka"
   echo
}

while getopts 'hb' flag; do
  case "${flag}" in
    h) Help ;;
    b) BuildAndDeploy "$@";;
    *) error "Unexpected option ${flag}" ;;
  esac
done