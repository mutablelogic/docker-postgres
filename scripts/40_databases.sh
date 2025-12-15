#!/bin/bash
# Script runs on a primary instance to create databases and roles
set -e

# Script should only run on the primary node
if [ ! -z "${POSTGRES_REPLICATION_PRIMARY}" ]; then
    echo "Skipping database initialisation on a replica."
    exit 0
fi

# Skip if no databases configured
if [ -z "${POSTGRES_DATABASES}" ]; then
    echo "No additional databases configured, skipping."
    exit 0
fi

# Create the databases
IFS=',' read -r -a array <<< "${POSTGRES_DATABASES}"
for NAME in "${array[@]}"; do
    # Build the password variable name and get its value
    PASSWORD_VAR="POSTGRES_PASSWORD_${NAME}"
    PASSWORD="${!PASSWORD_VAR}"

    echo "Creating database and role: ${NAME}"

    # Create role if it doesn't exist
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        DO \$\$
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${NAME}') THEN
                CREATE ROLE ${NAME};
            END IF;
        END
        \$\$;
EOSQL

    # Set password or NOLOGIN
    if [ ! -z "${PASSWORD}" ]; then
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            ALTER ROLE ${NAME} WITH LOGIN PASSWORD '${PASSWORD}';
EOSQL
    else
        psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
            ALTER ROLE ${NAME} WITH NOLOGIN;
EOSQL
    fi

    # Create database if it doesn't exist
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        SELECT 'CREATE DATABASE ${NAME} OWNER ${NAME}'
        WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '${NAME}')\gexec
EOSQL

    echo "Created database and role: ${NAME}"
done
