#!/bin/bash
# Script runs on a primary instance to set up replication slots
# The primary instance should be started before the replicas
set -e

# Script should only run on the primary node
if [ ! -z "${POSTGRES_REPLICATION_PRIMARY}" ]; then
    echo "Skipping primary initialisation on a replica."
    exit 0
fi

# If there is no replication password, then quit
if [ -z "${POSTGRES_REPLICATION_PASSWORD}" ]; then
    echo "POSTGRES_REPLICATION_PASSWORD needs to be set."
    exit 1
fi

# Make the data directory
install -d "${PGDATA}" -o postgres -g postgres -m 700

# Create the replication user
psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
    CREATE USER ${POSTGRES_REPLICATION_USER} WITH REPLICATION ENCRYPTED PASSWORD '${POSTGRES_REPLICATION_PASSWORD}';
EOSQL

# Create the replication slots
IFS=',' read -r -a array <<< "${POSTGRES_REPLICATION_SLOT}"
for SLOT in "${array[@]}"; do
    psql -v ON_ERROR_STOP=1 --username "${POSTGRES_USER}" --dbname "${POSTGRES_DB}" <<-EOSQL
        SELECT pg_create_physical_replication_slot('${SLOT}');
EOSQL
done

# Set configuration for replication
CONF="${PGDATA}/postgresql.conf"
sed -i -e"s/^#wal_level.*$/wal_level=replica/" ${CONF}
sed -i -e"s/^#max_wal_senders.*$/max_wal_senders=10/" ${CONF}
sed -i -e"s/^#max_replication_slots.*$/max_replication_slots=10/" ${CONF}

# Add a replication user to pg_hba.conf
echo "host replication ${POSTGRES_REPLICATION_USER} all scram-sha-256" >> "${PGDATA}/pg_hba.conf"
