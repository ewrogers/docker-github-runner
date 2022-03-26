ARG FROM=debian:bullseye-slim
FROM ${FROM}

LABEL org.opencontainers.image.authors="ewrogers@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive
ARG DOCKER_REPOSITORY=stable
ARG DOCKER_COMPOSE_VERSION="1.29.2"
ARG GITHUB_RUNNER_VERSION

ENV HOME /home/runner

# Default environment variables for Github Runnner
ENV RUNNER_NAME=""
ENV RUNNER_WORK_DIRECTORY="_work"
ENV RUNNER_TOKEN=""
ENV RUNNER_REPOSITORY_URL=""
ENV RUNNER_ORGANIZATION_URL=""
ENV RUNNER_LABELS=""
ENV RUNNER_ALLOW_RUNASROOT=true
ENV GITHUB_ACCESS_TOKEN=""

# Install dependencies for Docker & GitHub
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        apt-transport-https \
        ca-certificates \
        curl \
        git \
        git-lfs \
        gnupg \
        jq \
        lsb-release && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add stable repository for Docker
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) ${DOCKER_REPOSITORY}" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker CLI
RUN apt-get update -y && \
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        containerd.io && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

# Install Docker Compose
RUN curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Make runner home directory
RUN mkdir -p ${HOME}
WORKDIR ${HOME}

# Install GitHub runner package
RUN GH_RUNNER_VERSION=${GH_RUNNER_VERSION:-$(curl --silent "https://api.github.com/repos/actions/runner/releases/latest" | grep tag_name | sed -E 's/.*"v([^"]+)".*/\1/')} \
    && curl -L -O https://github.com/actions/runner/releases/download/v${GH_RUNNER_VERSION}/actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && tar -zxf actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && rm -f actions-runner-linux-x64-${GH_RUNNER_VERSION}.tar.gz \
    && ./bin/installdependencies.sh \
    && chown -R root: ${HOME} \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy entrypoint script and make executable
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

USER docker

ENTRYPOINT ["/bin/bash"]
CMD ["entrypoint.sh"]
