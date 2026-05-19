FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       bash \
       ca-certificates \
       curl \
       dnsutils \
       git \
       iproute2 \
       ipset \
       iptables \
       jq \
       less \
       procps \
       sudo \
       unzip \
       vim \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update \
    && apt-get install -y docker.io docker-compose \
    && rm -rf /var/lib/apt/lists/*

USER vscode
WORKDIR /home/vscode
