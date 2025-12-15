# PostgreSQL Dockerfile with primary and replica support

PostgreSQL image with Primary &amp; Replica support, plus SSL support.
In order to build the image, run:

```bash
DOCKER_REPO=ghcr.io/mutablelogic/docker-postgres make docker
```

Replacing the `DOCKER_REPO` with the repository you want to push the image to.

## Environment variables

The image can be run as a standalone instance, primary, or replica, depending on the environment variables passed on the
docker command line:

* `POSTGRES_REPLICATION_PRIMARY`: **Required for replica** The host and port that the replica will use
  to connect to the primary, in the form `host=<hostname> port=5432`. When not set,
  the instance role is a primary or standalone.
* `POSTGRES_REPLICATION_PASSWORD`: **Required for replication**: The password for the `POSTGRES_REPLICATION_USER`.
  If not set, replication is disabled and the instance runs as a standalone server.
* `POSTGRES_REPLICATION_USER`: **Default is `replicator`**: The user that the replica will use to connect to the primary.
* `POSTGRES_REPLICATION_SLOT`: **Default is `replica1`**: The replication slot for each replica.
  On the primary, this is a comma-separated list of replication slots. On a replica, this is the name
  of the replication slot used for synchronization.
* `POSTGRES_DATABASES`: **Optional**: A comma-separated list of databases (and associated owner role,
  which has the same name as the database), in addition to the main database.
* `POSTGRES_PASSWORD_<role>`: **Optional**: For any database which is created, you can enable
  login and set the password for the database owner role by setting this environment variable. Without
  this environment variable, the role will not be able to login.
* `POSTGRES_SSL_CERT`: **Optional**: The SSL certificate file location for the server, within the container.
  Requires `POSTGRES_SSL_KEY` to also be set.
* `POSTGRES_SSL_KEY`: **Optional**: The SSL private key file location for the server, within the container.
  Requires `POSTGRES_SSL_CERT` to also be set.
* `POSTGRES_SSL_CA`: **Optional**: The SSL CA certificate file location for client certificate verification.
  Only used when `POSTGRES_SSL_CERT` and `POSTGRES_SSL_KEY` are set.

## Volume mount path

**Important:** PostgreSQL 18+ uses a different data directory structure to support `pg_upgrade`.

| Version | Volume mount path |
|---------|-------------------|
| 17 and earlier | `-v myvolume:/var/lib/postgresql/data` |
| 18 and later | `-v myvolume:/var/lib/postgresql` |

See [docker-library/postgres#1259](https://github.com/docker-library/postgres/pull/1259) for details.

## Running a standalone server

Example of running a standalone PostgreSQL instance without replication:

**PostgreSQL 17:**

```bash
docker volume create postgres-data
docker run \
  --rm --name postgres \
  -e POSTGRES_PASSWORD="postgres" \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql/data \
  ghcr.io/mutablelogic/docker-postgres:17-bookworm
```

**PostgreSQL 18+:**

```bash
docker volume create postgres-data
docker run \
  --rm --name postgres \
  -e POSTGRES_PASSWORD="postgres" \
  -p 5432:5432 \
  -v postgres-data:/var/lib/postgresql \
  ghcr.io/mutablelogic/docker-postgres:18-trixie
```

This gives you PostgreSQL with `pg_stat_statements` pre-loaded, plus PostGIS and pgvector available.

## Running a Primary server

Example of running a primary instance, with two replication slots.
You should change the password for the `POSTGRES_PASSWORD` and `POSTGRES_REPLICATION_PASSWORD`
environment variables in this example:

**PostgreSQL 17:**

```bash
docker volume create postgres-primary
docker run \
  --rm --name postgres-primary \
  -e POSTGRES_REPLICATION_SLOT="replica1,replica2" \
  -e POSTGRES_REPLICATION_PASSWORD="postgres" \
  -e POSTGRES_PASSWORD="postgres" \
  -p 5432:5432 \
  -v postgres-primary:/var/lib/postgresql/data \
  ghcr.io/mutablelogic/docker-postgres:17-bookworm
```

**PostgreSQL 18+:**

```bash
docker volume create postgres-primary
docker run \
  --rm --name postgres-primary \
  -e POSTGRES_REPLICATION_SLOT="replica1,replica2" \
  -e POSTGRES_REPLICATION_PASSWORD="postgres" \
  -e POSTGRES_PASSWORD="postgres" \
  -p 5432:5432 \
  -v postgres-primary:/var/lib/postgresql \
  ghcr.io/mutablelogic/docker-postgres:18-trixie
```

You can add additional replication slots later as needed.

## Running a Replica server

When you run a replica instance, the first time it runs it will backup from the primary instance and then start
replication. You should change the password for the `POSTGRES_PASSWORD` and `POSTGRES_REPLICATION_PASSWORD`
environment variables, and set the `POSTGRES_REPLICATION_PRIMARY` environment variable to the primary instance
in this example:

**PostgreSQL 17:**

```bash
docker volume create postgres-replica1
docker run \
    --rm --name postgres-replica1 \
    -e POSTGRES_REPLICATION_PRIMARY="host=milou.lan port=5432" \
    -e POSTGRES_REPLICATION_SLOT="replica1" \
    -e POSTGRES_REPLICATION_PASSWORD="postgres" \
    -e POSTGRES_PASSWORD="postgres" \
    -p 5433:5432 \
    -v postgres-replica1:/var/lib/postgresql/data \
    ghcr.io/mutablelogic/docker-postgres:17-bookworm
```

**PostgreSQL 18+:**

```bash
docker volume create postgres-replica1
docker run \
    --rm --name postgres-replica1 \
    -e POSTGRES_REPLICATION_PRIMARY="host=milou.lan port=5432" \
    -e POSTGRES_REPLICATION_SLOT="replica1" \
    -e POSTGRES_REPLICATION_PASSWORD="postgres" \
    -e POSTGRES_PASSWORD="postgres" \
    -p 5433:5432 \
    -v postgres-replica1:/var/lib/postgresql \
    ghcr.io/mutablelogic/docker-postgres:18-trixie
```

A second replica (and so forth) can be run in the same way, but with a different port and volume name.
You can run up to ten replicas by default. You should ensure the primary instance is running before starting
the replica.

## Extensions

The docker images include the following extensions:

* [pg_stat_statements](https://www.postgresql.org/docs/current/pgstatstatements.html) - Pre-loaded for query
  performance monitoring. Create the extension with `CREATE EXTENSION pg_stat_statements;` to start collecting
  statistics.
* [PostGIS](https://postgis.net/) - Spatial database extender.
* [pgvector](https://github.com/pgvector/pgvector) - Vector similarity search.

## Bugs, feature requests and contributions

You can raise issues and feature requests using
the [GitHub issue tracker](https://github.com/mutablelogic/docker-postgres/issues)
or send pull requests. The image is built from
the [Official Docker image](https://hub.docker.com/_/postgres).
