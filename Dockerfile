FROM ubuntu:trusty
MAINTAINER Brandfolder, Inc. <developers@brandfolder.com>

# Install Curl
RUN DEBIAN_FRONTEND=noninteractive apt-get update -q
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy curl

# Install GCloud Tools
RUN DEBIAN_FRONTEND=noninteractive echo "deb http://packages.cloud.google.com/apt cloud-sdk-trusty main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list
RUN DEBIAN_FRONTEND=noninteractive curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
RUN DEBIAN_FRONTEND=noninteractive apt-get update -q
RUN DEBIAN_FRONTEND=noninteractive apt-get install google-cloud-sdk -y

# Install Flynn CLI
RUN L=/usr/local/bin/flynn && curl -sSL -A "`uname -sp`" https://dl.flynn.io/cli | zcat >$L && chmod +x $L

# Install git
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy git

# Install jq
RUN DEBIAN_FRONTEND=noninteractive apt-get install -qy jq

# Default env
ENV BACKUP_TIMES 00:00
ENV GOOGLE_CLOUD_STORAGE_BUCKET flynn-backups
ENV FLYNN_CERTIFICATE_PIN ""
ENV FLYNN_CLUSTER_DOMAIN ""
ENV FLYNN_CONTROLLER_TOKEN ""
ENV GOOGLE_CREDENTIALS_ENCODED ""

# Install script
RUN mkdir /app
WORKDIR /app
ADD run.sh run.sh
ENTRYPOINT ["/bin/bash", "/app/run.sh"]
