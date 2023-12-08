#!/bin/bash
#
# Runs composer install against a composer.json file and
# copies over modules.
#
#
# Run with -h for help and composer.json file is specified 
# with -c compose.json
#
# Supported distributions:
# - WSL2 Ubuntu 20.04.4 LTS
#
#----------------------------------------------------------------

# Color output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW="\033[0;33m"
WHITE='\033[0;37m'
RESET='\033[0m'

base_dir='/var/www/'
relative_dir='html'
env=$2

################################################################################
# Checks                                                                       #
################################################################################

Checks()
{

    # Expected OS version

    OS=`uname -s`
    if [ $OS != 'Linux' ]; then
        echo "$PROG: error: unsupported operating system: not Linux: $OS" >&2
        exit 1
    fi

    if ! which lsb_release >/dev/null 2>&1; then
        echo "$PROG: error: unsupported distribution: missing lsb_release" >&2
        exit 1
    fi
}

################################################################################
# CHECK REQUIREMENTS                                                           #
################################################################################
CheckRequirements()
{
    echo -e "${YELLOW}Checking for composer and unzip${RESET}"

    # check we have composer and unzip
    if command -v composer &> /dev/null
        then
            echo -e "${GREEN}Found composer :).${RESET}"
        else
            echo -e "${RED}Could not find composer :(${RESET}"
            
            # Build composer
            echo -e "${GREEN}Building composer${RESET}"
            scripts/build-composer.sh -b
    fi

    if command -v unzip &> /dev/null
        then
            echo -e "${GREEN}Found unzip :).${RESET}"
        else
            echo -e "${RED}Could not find unzip :(${RESET}"
    fi

}

Build()
{

    Checks
    CheckRequirements

    # Create composer.json from template
    echo -e "${GREEN}Creating composer.json${RESET}"
    cp scripts/composer.json.template composer.json

    php scripts/composer-merge.php

    # Use composer to build the application
    echo -e "${GREEN}Running composer${RESET}"

    if [ """$env""" == "test" ] || [ """$env""" == "dev" ];
        then
            composer install --dev --prefer-source
        else 
            # assumes prod or staging
            composer install --no-dev
    fi
    

}


################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "Uses composer to create omeka S filesystem from composer.json file"
   echo "Run this from a folder which container composer.json"
   echo
   echo "Syntax: build-omeka-from-composer.sh [-h|b]"
   echo "options:"
   echo "h     Print this Help."
   echo "b     Build filesystem from composer.json file."
   echo
}

while getopts 'hb' flag; do
  case "${flag}" in
    h) Help ;;
    b) Build ;;
    *) error "Unexpected option ${flag}" ;;
  esac
done
