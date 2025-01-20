ARG VERSION=17-bookworm

# Use the base image
FROM postgres:${VERSION}
ARG VERSION
LABEL org.opencontainers.image.description="PostgreSQL image with primary/replica support" \
      org.opencontainers.image.version="$VERSION"

# Install packages postgis and pgvector
ENV POSTGIS_MAJOR=3
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    ca-certificates \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR \
    postgresql-$PG_MAJOR-postgis-$POSTGIS_MAJOR-scripts \
    postgresql-$PG_MAJOR-pgvector \
  && rm -rf /var/lib/apt/lists/*    

# Copy scripts
RUN mkdir -p /docker-entrypoint-initdb.d
COPY --chmod=755 ./scripts/10_primary.sh /docker-entrypoint-initdb.d
COPY --chmod=755 ./scripts/20_replica.sh /docker-entrypoint-initdb.d

# Set the environment
ENV POSTGRES_REPLICATION_USER=replication \
    POSTGRES_REPLICATION_SLOT=replica1
