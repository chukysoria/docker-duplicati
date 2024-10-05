# syntax=docker/dockerfile:1
ARG BUILD_FROM=ghcr.io/chukysoria/baseimage-ubuntu:v0.2.37-jammy

FROM ${BUILD_FROM} 

# set version label
ARG BUILD_DATE
ARG BUILD_VERSION
ARG BUILD_EXT_RELEASE="v2.0.8.1-2.0.8.1_beta_2024-05-07"
LABEL build_version="Chukyserver.io version:- ${BUILD_VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="chukysoria"

# environment settings
ENV HOME="/config"
ENV DEBIAN_FRONTEND="noninteractive"

RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  echo "**** install duplicati ****" && \
  DUPLICATI_URL=$(curl -s https://api.github.com/repos/duplicati/duplicati/releases/tags/"${BUILD_EXT_RELEASE}" | jq -r '.assets[].browser_download_url' | grep '.deb$' | grep -v signatures) && \
  curl -o \
    /tmp/duplicati.deb -L \
    "${DUPLICATI_URL}" && \
  apt-get install /tmp/duplicati.deb -y && \
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
