#!/bin/bash

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
    # see https://raw.githubusercontent.com/digitalmethodsinitiative/dmi-tcat/master/helpers/tcat-install-linux.sh

    # Script run with root privileges (either as root or with sudo)

    if [ $(id -u) -ne 0 ]; then
        echo "Running script as $USER"
    else
        echo -e "${RED}Script run as root. Stopping.${RESET}"
        exit 64
    fi

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
# DATABASE.INI                                                                 #
################################################################################
CreateDatabaseIni()
{
    rm -f $relative_dir/db.ini

    cat > $relative_dir/db.ini <<EOL
[database]
username = "${MYSQL_USER}"
password = "${MYSQL_PASSWORD}"
dbname = "${MYSQL_DATABASE}"
host = "${MYSQL_HOST}"
prefix   = "${MYSQL_PREFIX}"
EOL

}


CreateConfig()
{
    if [ """$env""" == "test" ]; then

        cat > $relative_dir/application/config/config.ini <<EOL
[site]
locale.name = ""
debug.exceptions = false
debug.request = false
debug.profileDb = false
debug.email = ""
debug.emailLogPriority = Zend_Log::ERR
log.errors = false
log.priority = Zend_Log::WARN
log.sql = false
session.name = ""
theme.useInternalAssets = false
background.php.path = ""
mail.transport.type = "Sendmail"
EOL
    fi

## TODO: Add application.ini to this.

}


################################################################################
# .HTACCESS                                                                    #
################################################################################
CreateHtaccess()
{
    if [ """$env""" == "test" ]; then

        # write .htaccess file
        cat > $relative_dir/.htaccess <<EOL
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
RewriteRule ^(.*[^/])$ %{REQUEST_URI}/ [L,R=301]

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
################################################################################
# BUILD ENVIRONMENT                                                            #
################################################################################

Build()
{
    env=$2

    echo "Building $env environment"

    # build test environment
    if [ """$env""" == "test" ]; then

        # login variables
        DATABASE_USERNAME="test"
        DATABASE_PASSWORD="test"
        DATABASE_NAME="db1"
        DATABASE_HOST="db"

        # create test config
        echo -e "${GREEN}Creating db.ini${RESET}"
        CreateDatabaseIni


        # create .htaccess
        echo -e "${GREEN}Creating config.ini file${RESET}"
        CreateConfig "$@"

        # create .htaccess
        echo -e "${GREEN}Creating .htaccess file${RESET}"
        CreateHtaccess "$@"


        # do database tasks
        # scripts/build-database.sh -d "$env"
        # SetupDatabase

        # create config file
        # CreateConfig

    fi

}

################################################################################
# Help                                                                         #
################################################################################
Help()
{
   # Display Help
   echo "Create the environment specific settings."
   echo "Copies files over to the environment folder and"
   echo "creates configuration files if needed."
   echo "IMPORTANT: Add environment to end of call"
   echo "Accepted environments are:"
   echo "Dev"
   echo "Test"
   echo
   echo "Syntax: build-environment.sh [-h|b] ENVIRONMENT"
   echo "options:"
   echo "h     Print this Help."
   echo "b     Copy and create files to build environment."
   echo
}

while getopts 'hb' flag; do
  case "${flag}" in
    h) Help ;;
    b) Build "$@";;
    *) error "Unexpected option ${flag}" ;;
  esac
done