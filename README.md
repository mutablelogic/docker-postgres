# PostgreSQL Dockerfile with primary and replica support

PostgreSQL image with Primary &amp; Replica support, plus SSL support.
In order to build the image, run:

```bash
DOCKER_REPO=ghcr.io/mutablelogic/docker-postgres make docker
```

Replacing the `DOCKER_REPO` with the repository you want to push the image to.

## Environment variables

The image can be run as a primary or replica, depending on the environment variables passed on the
docker command line:

* `POSTGRES_REPLICATION_PRIMARY`: **Required for replica** The host and port that the replica will use
  to connect to the primary, in the form `host=<hostname> port=5432`. When not set,
  the instance role is a primary.
* `POSTGRES_REPLICATION_PASSWORD`: **Required**: The password for the `POSTGRES_REPLICATION_USER`.
* `POSTGRES_REPLICATION_USER`: **Default is `replicator`**: The user that the primary will use to connect
  to the replica.  
* `POSTGRES_REPLICATION_SLOT`: **Default is `replica1`** The replication slot for each replica.
  On the primary, this is a comma-separated list of replication slots. On a replica, this is the name
  of the replication slot used for syncronization.
* `POSTGRES_DATABASES`: **Optional**: A comma-separated list of databases (and associated owner role,
  which has the same name as the database), in addition to the main database.
* `POSTGRES_PASSWORD_<role>`: **Optional**: For any database which is created, you can enable
  login and set the password for the database owner role by setting this environment variable. Without
  this environment variable, the role will not be able to login.
* `POSTGRES_SSL_CERT`: **Optional**: The SSL certificate file location for the server, within the container.
* `POSTGRES_SSL_KEY`: **Optional**: The SSL private key file location for the server, within the container.
* `POSTGRES_SSL_CA`: **Optional**: The SSL authority certificate file location for the server, within the 
  container.

## Running a Primary server

Example of running a primary instance, with two replication slots.
You should change the password for the `POSTGRES_PASSWORD` and `POSTGRES_REPLICATION_PASSWORD`
environment variables in this example:

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

You can add additional replication slots later as needed.

## Running a Replica server

When you run a replica instance, the first time it runs it will backup from the primary instance and then start
replication. You should change the password for the `POSTGRES_PASSWORD` and `POSTGRES_REPLICATION_PASSWORD`
environment variables, and set the `POSTGRES_REPLICATION_PRIMARY` environment variable to the primary instance
in this example:

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

A second replica (and so forth) can be run in the same way, but with a different port and volume name.
You can run up to ten replicas by default. You should ensure the primary instance is running before starting
the replica.

## Extensions

The docker images also contain [PostGIS](https://postgis.net/) and
[pgvector](https://github.com/pgvector/pgvector) extensions.

## Bugs, feature requests and contributions

You can raise issues and feature requests using 
the [GitHub issue tracker](https://github.com/mutablelogic/docker-postgres/issues)
or send pull requests. The image is built from
the [Official Docker image](https://hub.docker.com/_/postgres).
