ARG ALPINE_VER=latest
ARG DEBIAN_VER=9
ARG REGISTRY=docker.io
ARG REPOSITORY=sunnybear/base
ARG RELEASE_IMAGE=alpine-base

## ALPINE BASE IMAGE VERSION
FROM ${REGISTRY}/library/alpine:${ALPINE_VER} as alpine-base

## INCLUDE apk-install
COPY bin.alpine/ /usr/bin/

RUN apk-install \
      ca-certificates \
      curl \
      rsync \
      shadow

## INSTALL wait-for-it.sh
RUN curl -sSL https://github.com/vishnubob/wait-for-it/raw/master/wait-for-it.sh >/usr/bin/wait-for-it.sh \
 && chmod 755 /usr/bin/wait-for-it.sh

## INSTALL tini
RUN apk-install \
      tini

## INSTALL gosu
ARG GOSU_VER=1.10
ARG GOSU_ARCH=amd64
RUN curl -sSL "https://github.com/tianon/gosu/releases/download/${GOSU_VER}/gosu-${GOSU_ARCH}" >/usr/bin/gosu \
 && chmod 755 /usr/bin/gosu \
 && gosu nobody true

## INCLUDE VARIOUS SCRIPTS (entrypointd.sh, healthcheckd.sh, fix-perms)
COPY bin/ /usr/bin/

COPY healthcheck.d/ /etc/healthcheck.d/
HEALTHCHECK CMD /usr/bin/healthcheckd.sh

COPY entrypoint.d/ /etc/entrypoint.d/
ENTRYPOINT ["/usr/bin/entrypointd.sh"]

CMD ["/bin/sh"]

ARG IMAGE_VER=1.0.0
ARG REGISTRY=docker.io
ARG REPOSITORY=sunnybear/base
LABEL \
    org.label-schema.docker.cmd="docker run -it --rm ${REGISTRY}/${REPOSITORY}:alpine" \
    org.label-schema.description="Base image for alpine" \
    org.label-schema.name="${REGISTRY}/${REPOSITORY}:alpine" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/sun-bear/docker-base" \
    org.label-schema.vendor="Sun Bear" \
    org.label-schema.version="${IMAGE_VER}"


## DEBIAN BASE IMAGE VERSION
FROM ${REGISTRY}/library/debian:${DEBIAN_VER} as debian-base

## INCLUDE apt-install
COPY bin.debian/ /usr/bin/

RUN apt-install \
      ca-certificates \
      curl \
      rsync

## INSTALL wait-for-it.sh
RUN curl -sSL https://github.com/vishnubob/wait-for-it/raw/master/wait-for-it.sh >/usr/bin/wait-for-it.sh \
 && chmod 755 /usr/bin/wait-for-it.sh

## INSTALL tini
ARG TINI_VERSION=v0.16.1
RUN curl -sSL https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini >/usr/bin/tini \
 && chmod 755 /usr/bin/tini

## INSTALL gosu
ARG GOSU_VERSION=1.10
RUN dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" \
 && curl -sSL "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-${dpkgArch}" >/usr/bin/gosu \
 && chmod 755 /usr/bin/gosu \
 && gosu nobody true

## INCLUDE VARIOUS SCRIPTS (entrypointd.sh, healthcheckd.sh, fix-perms)
COPY bin/ /usr/bin/
COPY healthcheck.d/ /etc/healthcheck.d/
COPY entrypoint.d/ /etc/entrypoint.d/

HEALTHCHECK CMD /usr/bin/healthcheckd.sh
ENTRYPOINT ["/usr/bin/entrypointd.sh"]

CMD ["/bin/bash"]

ARG IMAGE_VERSION=1.0.0
ARG REGISTRY=docker.io
ARG REPOSITORY=sunnybear/base
LABEL \
    org.label-schema.docker.cmd="docker run -it --rm ${REGISTRY}/${REPOSITORY}:debian" \
    org.label-schema.description="Base image for debian" \
    org.label-schema.name="${REGISTRY}/${REPOSITORY}:debian" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/sun-bear/docker-base" \
    org.label-schema.vendor="Sun Bear" \
    org.label-schema.version="${IMAGE_VER}"


## SCRATCH BASE IMAGE VERSION
FROM scratch as scratch-base

## INCLUDE DOWNLOADED UTILITIES
COPY --from=debian-base \
     /usr/bin/wait-for-it.sh \
     /usr/bin/tini \
     /usr/bin/gosu \
     /usr/bin/

## INCLUDE SCRIPTS AND UTILITIES
COPY bin/ /usr/bin/
COPY healthcheck.d/ /etc/healthcheck.d/
COPY entrypoint.d/ /etc/entrypoint.d/

ARG IMAGE_VERSION=1.0.0
ARG REGISTRY=docker.io
ARG REPOSITORY=sunnybear/base
LABEL \
    org.label-schema.description="Base image for scratch" \
    org.label-schema.name="${REGISTRY}/${REPOSITORY}:scratch" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.url="https://github.com/sun-bear/docker-base" \
    org.label-schema.vendor="Sun Bear" \
    org.label-schema.version="${IMAGE_VER}"


## BUILD A SPECIFIC IMAGE WHEN TARGET IS NOT SPECIFIED
FROM ${RELEASE_IMAGE} as release

