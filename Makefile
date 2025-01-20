# Executables
DOCKER ?= $(shell which docker 2>/dev/null)

# Set OS and Architecture
ARCH ?= $(shell arch | tr A-Z a-z | sed 's/x86_64/amd64/' | sed 's/i386/amd64/' | sed 's/armv7l/arm/' | sed 's/aarch64/arm64/')
OS ?= $(shell uname | tr A-Z a-z)
VERSION ?= 17-bookworm

# Docker repository
DOCKER_REPO ?= ghcr.io/mutablelogic/docker-postgres
BUILD_TAG = ${DOCKER_REPO}-${OS}-${ARCH}:${VERSION}

# Build the docker image
.PHONY: docker
docker: docker-dep
	@echo build docker image: ${BUILD_TAG} for ${OS}/${ARCH}
	@${DOCKER} build \
		--tag ${BUILD_TAG} \
		--build-arg ARCH=${ARCH} \
		--build-arg OS=${OS} \
		--build-arg VERSION=${VERSION} \
		-f Dockerfile .

# Push the docker image
.PHONY: docker-push
docker-push: docker
	@echo push docker image: ${BUILD_TAG}
	@${DOCKER} push ${BUILD_TAG}

###############################################################################
# DEPENDENCIES

.PHONY: docker-dep
docker-dep:
	@test -f "${DOCKER}" && test -x "${DOCKER}"  || (echo "Missing docker binary" && exit 1)
