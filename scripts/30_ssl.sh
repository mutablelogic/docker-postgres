#!/bin/bash
# Script runs on any instance to set up SSL
# https://www.postgresql.org/docs/current/ssl-tcp.html#SSL-OPENSSL-CONFIG
set -e

# Set configuration for replication
CONF="${PGDATA}/postgresql.conf"

if [ ! -z "${POSTGRES_SSL_CERT}" ]; then
    if [ ! -f "${POSTGRES_SSL_CERT}" ]; then
        echo "POSTGRES_SSL_CERT file not found."
        exit 1
    fi
    sed -i -e"s/^#ssl_cert_file.*$/ssl_cert_file=${POSTGRES_SSL_CERT}/" ${CONF}
fi

if [ ! -z "${POSTGRES_SSL_KEY}" ]; then
    if [ ! -f "${POSTGRES_SSL_KEY}" ]; then
        echo "POSTGRES_SSL_KEY file not found."
        exit 1
    fi
    sed -i -e"s/^#ssl_key_file.*$/ssl_key_file=${POSTGRES_SSL_KEY}/" ${CONF}
fi

if [ ! -z "${POSTGRES_SSL_CA}" ]; then
    if [ ! -f "${POSTGRES_SSL_CA}" ]; then
        echo "POSTGRES_SSL_CA file not found."
        exit 1
    fi
    sed -i -e"s/^#ssl_ca_file.*$/ssl_ca_file=${POSTGRES_SSL_CA}/" ${CONF}
fi
