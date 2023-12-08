################################################################################
# DATABASE CONFIGURATION                                                       #
################################################################################
SetupDatabase()
{
    if [ """$env""" == "test" ]; then

        echo -e "${GREEN}Copying Database dumps for import by image${RESET}"

        DB_folder="container_database/db_files"

        mkdir -p $DB_folder

        # join the text files into a single dump for image loading
        #cat db/clear_tables.sql db/build_tables.sql db/insert_base_data.sql db/enable_ldap_plugin.sql db/insert_idguser.sql> "$DB_folder/dump.sql"
        cp db/omeka.sql "$DB_folder/dump.sql"
    elif [ """$env""" == "dev" ]; then

        echo -e "${GREEN}Dev environment persists the database if exists ${RESET}"

        if [ -d "container_database/db_files" ]; then
            echo -e "${GREEN}Database files already exist, skipping${RESET}"
        else
            echo -e "${GREEN}Copying Database dumps for import by image${RESET}"

            DB_folder="container_database/db_files"

            mkdir -p $DB_folder

            # join the text files into a single dump for image loading
            #cat db/clear_tables.sql db/build_tables.sql db/insert_base_data.sql db/enable_ldap_plugin.sql db/insert_idguser.sql> "$DB_folder/dump.sql"
            cp db/omeka.sql "$DB_folder/dump.sql"
        fi

    fi
        


}
