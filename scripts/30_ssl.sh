#!/bin/bash
# Script runs on any instance to set up SSL
# https://www.postgresql.org/docs/current/ssl-tcp.html#SSL-OPENSSL-CONFIG
set -e

# Skip if no SSL cert configured
if [ -z "${POSTGRES_SSL_CERT}" ]; then
    echo "No SSL certificate configured, skipping SSL setup."
    exit 0
fi

# Both cert and key are required
if [ -z "${POSTGRES_SSL_KEY}" ]; then
    echo "POSTGRES_SSL_KEY must be set when POSTGRES_SSL_CERT is set."
    exit 1
fi

if [ ! -f "${POSTGRES_SSL_CERT}" ]; then
    echo "POSTGRES_SSL_CERT file not found: ${POSTGRES_SSL_CERT}"
    exit 1
fi

if [ ! -f "${POSTGRES_SSL_KEY}" ]; then
    echo "POSTGRES_SSL_KEY file not found: ${POSTGRES_SSL_KEY}"
    exit 1
fi

# Set configuration for SSL
CONF="${PGDATA}/postgresql.conf"

sed -i -e"s|^#ssl = .*$|ssl = on|" ${CONF}
sed -i -e"s|^#ssl_cert_file.*$|ssl_cert_file = '${POSTGRES_SSL_CERT}'|" ${CONF}
sed -i -e"s|^#ssl_key_file.*$|ssl_key_file = '${POSTGRES_SSL_KEY}'|" ${CONF}

# Optional CA file for client certificate verification
if [ ! -z "${POSTGRES_SSL_CA}" ]; then
    if [ ! -f "${POSTGRES_SSL_CA}" ]; then
        echo "POSTGRES_SSL_CA file not found: ${POSTGRES_SSL_CA}"
        exit 1
    fi
    sed -i -e"s|^#ssl_ca_file.*$|ssl_ca_file = '${POSTGRES_SSL_CA}'|" ${CONF}
fi

echo "SSL configured successfully."
