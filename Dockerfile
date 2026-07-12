# check=skip=SecretsUsedInArgOrEnv
# syntax=docker/dockerfile:1@sha256:87999aa3d42bdc6bea60565083ee17e86d1f3339802f543c0d03998580f9cb89
ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:v1.0.0-resolute@sha256:8a46a913bb0b33024292a285702f307e9c96c4b9abe4e343ccb2b1a62ec842bf
FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="v2.3.0.3_stable_2026-06-10"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# environment settings
ARG DEBIAN_FRONTEND="noninteractive"
ENV HOME="/config" \
  TMPDIR=/run/duplicati-temp \
  DUPLICATI__REQUIRE_DB_ENCRYPTION_KEY=true \
  DUPLICATI__SERVER_DATAFOLDER=/config \
  DUPLICATI__WEBSERVICE_PORT=8200 \
  DUPLICATI__WEBSERVICE_INTERFACE=any \
  DUPLICATI__WEBSERVICE_ALLOWED_HOSTNAMES=*

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y \
    libicu78 \
    unzip \
    xz-utils && \
  echo "**** install duplicati ****" && \
  duplicati_url=$(curl -s "https://api.github.com/repos/duplicati/duplicati/releases/tags/${BUILD_EXT_RELEASE}" | jq -r '.assets[].browser_download_url' | grep 'linux-x64-gui.zip$') && \
  curl -o \
    /tmp/duplicati.zip -L \
    "${duplicati_url}" && \
  unzip -q /tmp/duplicati.zip -d /app && \
  mv /app/duplicati* /app/duplicati && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 8200

VOLUME /backups /config /source

HEALTHCHECK --interval=30s --timeout=30s --start-period=2m --start-interval=5s --retries=5 CMD ["nc", "-z", "localhost", "8200"]
