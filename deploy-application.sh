#!/bin/bash

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW="\033[0;33m"
WHITE='\033[0;37m'
RESET='\033[0m'

################################################################################
# Deploy                                                                       #
################################################################################
Deploy()
{
    env=$2

    echo "Deploying with $env environment"

    # build test environment
    if [ """$env""" == "test" ]; then
        echo "composing"
        docker-compose down
        docker-compose up
    fi
}

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "Deploys Omeka"
   echo "Target depends on environment variable"
   echo "Only dev supported atm which launches docker composer"
   echo
   echo "Syntax: build-environment.sh [-h|b] ENVIRONMENT"
   echo "options:"
   echo "h     Print this Help."
   echo "d     Deploys Omeka S to target"
   echo
}

while getopts 'hd' flag; do
  case "${flag}" in
    h) Help ;;
    d) Deploy "$@";;
    *) error "Unexpected option ${flag}" ;;
  esac
done