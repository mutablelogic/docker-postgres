#!/bin/bash
# Script runs on a primary instance to create databases and roles
set -e

# Script should only run on the primary node
if [ ! -z "${POSTGRES_REPLICATION_PRIMARY}" ]; then
    echo "Skipping database initialisation on a replica."
    exit 0
fi

# Create the databases
IFS=',' read -r -a array <<< "${POSTGRES_DATABASES}"
for NAME in "${array[@]}"; do
    # if there is an environment variable called POSTGRES_PASSWORD_<NAME>, then use that password
    if [ ! -z "${!POSTGRES_PASSWORD_${NAME}}" ]; then
        ALTER_ROLE="ALTER ROLE ${NAME} WITH PASSWORD ${!POSTGRES_PASSWORD_${NAME}}"
    else
        ALTER_ROLE="ALTER ROLE ${NAME} WITH NOLOGIN"
    fi
    # Execute SQL to create the database and role
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        DO $$ BEGIN
            -- Create database
            CREATE EXTENSION IF NOT EXISTS dblink;
            IF NOT EXISTS (
                SELECT 1 FROM pg_database WHERE datname = '${NAME}'
            ) THEN
                PERFORM dblink_exec('dbname=${POSTGRES_DB}', 'CREATE DATABASE ${NAME}');
            END IF;

            -- Create role
            CREATE ROLE ${NAME};
            ${ALTER_ROLE};
            ALTER DATABASE ${NAME} OWNER TO ${NAME};
            EXCEPTION WHEN duplicate_object THEN RAISE NOTICE '%, skipping', SQLERRM USING ERRCODE = SQLSTATE;
        END $$;
EOSQL
done
