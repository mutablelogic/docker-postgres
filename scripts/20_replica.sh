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

# If anything below fails, remove the partly-initialised database before
# exiting. Otherwise, on the next start the entrypoint finds a database in
# $PGDATA, skips initialisation, and runs it as a standalone server instead of
# a replica. With $PGDATA empty, the next start retries the whole setup.
on_error() {
    echo "Replica initialisation failed; removing ${PGDATA} contents so the next start retries." >&2
    pg_ctl -D "${PGDATA}" stop -m immediate >/dev/null 2>&1 || true
    rm -rf "${PGDATA:?}"/* "${PGDATA:?}"/.[!.]* 2>/dev/null || true
}
trap 'on_error' ERR

# Make the data directory
install -d "${PGDATA}" -o postgres -g postgres -m 700

# Set password for replication user (idempotent). The file is in the postgres
# home directory, which must be writable by postgres (see entrypoint.sh).
PGPASS_FILE="/var/lib/postgresql/.pgpass"
if ! touch "${PGPASS_FILE}" 2>/dev/null; then
    echo "Cannot write ${PGPASS_FILE}: /var/lib/postgresql must be writable by the postgres user." >&2
    false
fi
PGPASS_ENTRY="*:*:*:${POSTGRES_REPLICATION_USER}:${POSTGRES_REPLICATION_PASSWORD}"
if [ ! -f "${PGPASS_FILE}" ] || ! grep -qF "${PGPASS_ENTRY}" "${PGPASS_FILE}"; then
    echo "${PGPASS_ENTRY}" >> "${PGPASS_FILE}"
    chmod 600 "${PGPASS_FILE}"
fi

# Stop the server if running
pg_ctl -D "${PGDATA}" stop -m fast 2>/dev/null || true

# Perform the backup. The official entrypoint exports PGPASSWORD (set to
# POSTGRES_PASSWORD) while it runs init scripts, and libpq prefers it to
# .pgpass, so unset it to make pg_basebackup use the replication password.
rm -fr ${PGDATA}/*
env -u PGPASSWORD pg_basebackup -v --pgdata="${PGDATA}" \
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

# Start the server, again without PGPASSWORD so the WAL receiver uses .pgpass
env -u PGPASSWORD pg_ctl -D "${PGDATA}" start
