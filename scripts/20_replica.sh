#!/bin/bash
set -e

# Script should only run on the primary node
if [ -z "${POSTGRES_REPLICATION_PRIMARY}" ]; then
    echo "Skipping replica initialisation on a primary."
    exit 0
fi

# If there is no replication password, then quit
if [ -z "${POSTGRES_REPLICATION_PASSWORD}" ]; then
    echo "POSTGRES_REPLICATION_PASSWORD needs to be set."
    exit 1
fi

# Make the data directory
install -d "${PGDATA}" -o postgres -g postgres -m 700

# Set password for replication user
echo "*:*:*:${POSTGRES_REPLICATION_USER}:${POSTGRES_REPLICATION_PASSWORD}" >> /var/lib/postgresql/.pgpass
chmod 600 /var/lib/postgresql/.pgpass

# Stop the server
pg_ctl -D "${PGDATA}" stop -m fast

# Perform the backup
rm -fr ${PGDATA}/*
pg_basebackup -v --pgdata="${PGDATA}" \
  --write-recovery-conf \
  --slot="${POSTGRES_REPLICATION_SLOT}" -X stream \
  --dbname="${POSTGRES_REPLICATION_PRIMARY}" --username="${POSTGRES_REPLICATION_USER}" --no-password

# Set configuration for replication
CONF="${PGDATA}/postgresql.conf"
sed -i -e"s/^#max_wal_senders.*$/max_wal_senders=10/" ${CONF}
sed -i -e"s/^#max_replication_slots.*$/max_replication_slots=10/" ${CONF}
sed -i -e"s/^#primary_conninfo.*$/primary_conninfo='user=${POSTGRES_REPLICATION_USER} ${POSTGRES_REPLICATION_PRIMARY}'/" ${CONF}
sed -i -e"s/^#primary_slot_name.*$/primary_slot_name='${POSTGRES_REPLICATION_SLOT}'/" ${CONF}
sed -i -e"s/^#hot_standby.*$/hot_standby=on/" ${CONF}
sed -i -e"s/^#hot_standby_feedback.*$/hot_standby_feedback=on/" ${CONF}

# Start the server
pg_ctl -D "${PGDATA}" start
