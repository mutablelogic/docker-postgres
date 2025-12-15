#!/bin/bash
# Script runs on a replica node to backup from the primary and set up replication
# The primary instance should be running before starting the replica
set -e

# Script should only run on a replica node
if [ -z "${POSTGRES_REPLICATION_PRIMARY}" ]; then
    echo "Skipping replica initialisation on a primary."
    exit 0
fi

# Validate required environment variables
if [ -z "${POSTGRES_REPLICATION_PASSWORD}" ]; then
    echo "POSTGRES_REPLICATION_PASSWORD needs to be set."
    exit 1
fi

if [ -z "${POSTGRES_REPLICATION_USER}" ]; then
    echo "POSTGRES_REPLICATION_USER needs to be set."
    exit 1
fi

if [ -z "${POSTGRES_REPLICATION_SLOT}" ]; then
    echo "POSTGRES_REPLICATION_SLOT needs to be set."
    exit 1
fi

# Make the data directory
install -d "${PGDATA}" -o postgres -g postgres -m 700

# Set password for replication user (idempotent)
PGPASS_FILE="/var/lib/postgresql/.pgpass"
PGPASS_ENTRY="*:*:*:${POSTGRES_REPLICATION_USER}:${POSTGRES_REPLICATION_PASSWORD}"
if [ ! -f "${PGPASS_FILE}" ] || ! grep -qF "${PGPASS_ENTRY}" "${PGPASS_FILE}"; then
    echo "${PGPASS_ENTRY}" >> "${PGPASS_FILE}"
    chmod 600 "${PGPASS_FILE}"
fi

# Stop the server if running
pg_ctl -D "${PGDATA}" stop -m fast 2>/dev/null || true

# Perform the backup
rm -fr ${PGDATA}/*
pg_basebackup -v --pgdata="${PGDATA}" \
  --write-recovery-conf \
  --slot="${POSTGRES_REPLICATION_SLOT}" -X stream \
  --dbname="${POSTGRES_REPLICATION_PRIMARY}" --username="${POSTGRES_REPLICATION_USER}" --no-password

# Set configuration for replication
# Note: pg_basebackup --write-recovery-conf already sets primary_conninfo and primary_slot_name
CONF="${PGDATA}/postgresql.conf"
sed -i -e"s/^#*max_wal_senders.*$/max_wal_senders = 10/" ${CONF}
sed -i -e"s/^#*max_replication_slots.*$/max_replication_slots = 10/" ${CONF}
sed -i -e"s/^#*hot_standby.*$/hot_standby = on/" ${CONF}
sed -i -e"s/^#*hot_standby_feedback.*$/hot_standby_feedback = on/" ${CONF}

# Start the server
pg_ctl -D "${PGDATA}" start
