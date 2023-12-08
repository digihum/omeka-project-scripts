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



################################################################################
# DATABASE.INI                                                                 #
################################################################################
CreateDatabaseIni()
{
    rm -f /var/www/html/db.ini

    cat > /var/www/html/db.ini <<EOL
[database]
username = "$MYSQL_USER"
password = "$MYSQL_PASSWORD"
dbname = "$MYSQL_DATABASE"
host = "$MYSQL_HOST"
prefix   = "$MYSQL_PREFIX"
EOL

}


################################################################################
# .HTACCESS                                                                    #
################################################################################
CreateHtaccess()
{
    if [ """$env""" == "test" ]; then

        # write .htaccess file
        cat > /var/www/html/.htaccess <<EOL
# Omeka .htaccess: Apache configuration file
# This file is required for Omeka to function correctly.

# --------------- #
# Error Reporting #
# --------------- #

# Uncomment the SetEnv line below to turn on detailed on-screen error
# reporting.
#
# Note: This should only be enabled for development or debugging. Keep this
# line commented for production sites.
# 
 SetEnv APPLICATION_ENV development

# ------------- #
# Rewrite Rules #
# ------------- #

RewriteEngine on
# do not rewrite server-status
RewriteRule ^server-status$ - [L]

# If you know mod_rewrite is enabled, but you are still getting mod_rewrite
# errors, uncomment the line below and replace "/" with your base directory.
#
# RewriteBase /

# Inserted to use trailing slashes on all URLs for wget 
# recommended by https://inkdroid.org/2018/07/08/omeka/
RewriteCond %{REQUEST_METHOD} GET [NC]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteRule ^(.*[^/])$ /$1/ [L,R=301]

# Allow direct access to files (except PHP files)
RewriteCond %{REQUEST_FILENAME} -f
RewriteRule !\.(php[0-9]?|phtml|phps)$ - [C]
RewriteRule .* - [L]

RewriteRule ^install/.*$ install/install.php [L]
RewriteRule ^admin/.*$ admin/index.php [L]
RewriteRule .* index.php

# -------------- #
# Access Control #
# -------------- #

# Block access to all .ini files.
<FilesMatch "\.ini$">
    <IfModule mod_authz_core.c>
        Require all denied
    </IfModule>
    <IfModule !mod_authz_core.c>
        Order Allow,Deny
        Deny from all
    </IfModule>
</FilesMatch>

# --------#
# Caching #
# --------#

# Uncomment the lines below in order to enable caching of some files
# (after a finished site has gone live)
#
# <IfModule mod_expires.c>
#    <FilesMatch "\.(js|ico|gif|jpg|png|css)$">
#        ExpiresActive on
#        ExpiresDefault "access plus 10 day"
#    </FilesMatch>
# </IfModule>

# ------------ #
# PHP Settings #
# ------------ #

<IfModule mod_php5.c>
    php_flag register_globals off
    php_flag magic_quotes_gpc off
</IfModule>
EOL
    fi
}


Build()
{
    env=$2

    echo "Building $env environment"

    # build test environment
    if [ """$env""" == "test" ]; then

        # create test config
        echo -e "${GREEN}Creating db.ini${RESET}"
        CreateDatabaseIni

        # create .htaccess
        echo -e "${GREEN}Creating .htaccess file${RESET}"
        CreateHtaccess "$@"
        # add test .htaccess file

        SetupDatabase

        CreateConfig

    fi


    Checks
    CheckRequirements

    # download files
    composer install -d /var/www/

    CreateHtaccess
    CreateDatabaseIni
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
