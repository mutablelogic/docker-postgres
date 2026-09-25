#!/bin/bash
# Entrypoint wrapper, run before the official postgres entrypoint.
#
# The postgres user's home directory (/var/lib/postgresql) is often a
# bind-mounted volume, which may be owned by root. The replica initialisation
# script keeps its .pgpass file there, but the official entrypoint only fixes
# the ownership of $PGDATA, so make the home directory itself (not recursively)
# owned by postgres too.
set -e

if [ "$(id -u)" = "0" ]; then
    install -d -o postgres -g postgres /var/lib/postgresql
    chown postgres:postgres /var/lib/postgresql
fi

exec docker-entrypoint.sh "$@"
