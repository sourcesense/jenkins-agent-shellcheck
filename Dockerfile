FROM alpine as curl

WORKDIR /

RUN apk add curl

FROM curl as yq-downloader

ARG OS=${TARGETOS:-linux}
ARG ARCH=${TARGETARCH:-amd64}
ARG YQ_VERSION="v4.6.0"
ARG YQ_BINARY="yq_${OS}_$ARCH"
RUN wget "https://github.com/mikefarah/yq/releases/download/$YQ_VERSION/$YQ_BINARY" -O /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

FROM ubuntu:focal

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys CC86BB64

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    git \
    jq \
    shellcheck \
    xmlstarlet \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY dep-bootstrap.sh .
RUN chmod +x ./dep-bootstrap.sh

RUN useradd -u 1000 -s /bin/bash jenkins
RUN mkdir -p /home/jenkins
RUN chown 1000:1000 /home/jenkins
ENV JENKINS_USER=jenkins

COPY --from=yq-downloader --chown=1000:1000 /usr/local/bin/yq /usr/local/bin/yq

USER 1000

RUN ./dep-bootstrap.sh 0.4.1 install

