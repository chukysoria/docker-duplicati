# syntax=docker/dockerfile:1@sha256:e63addfe27b10e394a5f9f1e866961adc70d08573f1cb80f8d1a0999347b3553
ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:v0.3.47-noble@sha256:05fad7ee308b43c6d7f20a0482f15ab67d0a4abbf5d5bc258bd470e59986bf66
FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="v2.1.0.119_canary_2025-05-29"
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
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
  apt-get update && \
  apt-get install -y \
    libicu74 \
    ttf-mscorefonts-installer \
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
