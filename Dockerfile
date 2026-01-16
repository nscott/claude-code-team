## This file is to build the *agent* that will

ARG WORKING_DIRECTORY=/opt/programmer

###################
# Base Stage
###################

FROM ubuntu:noble

ENV TZ="UTC"
RUN useradd -m coder
ARG CONTEXT7_API_KEY

# Runs as PID 1 to ensure that all signals get sent to node. See
# https://github.com/nodejs/docker-node/blob/master/docs/BestPractices.md#handling-kernel-signals
# > Node.js was not designed to run as PID 1 which leads to unexpected behaviour when running inside of Docker. For
# example, a Node.js process running as PID 1 will not respond to SIGINT (CTRL-C) and similar signals
ENV LANG=C.UTF-8

# Update the packages first
RUN apt-get -y clean
RUN apt-get update && apt-get install -y --no-install-recommends lsof net-tools curl wget ca-certificates sudo jq vim grep less git poppler-utils qpdf
RUN apt-get dist-upgrade -y

RUN bash -c "set -o pipefail && curl -fsSL https://deb.nodesource.com/setup_22.x | bash -"
RUN apt-get install -y nodejs
RUN apt-get upgrade -y

ARG WORKING_DIRECTORY
RUN mkdir $WORKING_DIRECTORY
RUN chown coder:coder $WORKING_DIRECTORY
WORKDIR $WORKING_DIRECTORY
ENV APP_PATH=$WORKING_DIRECTORY

RUN echo 'export PATH="$HOME/.local/bin:$PATH:/opt/programmer/scripts:/opt/programmer/claude-code-team/scripts"' >> /root/.bashrc
RUN npm install -g @fission-ai/openspec@latest
RUN curl -LsSf https://astral.sh/uv/install.sh | sh # uv is used for the Serena MCP
# Make the password 'docket' to use sudo
RUN echo "coder:docket" | chpasswd
RUN adduser coder sudo

USER coder
RUN curl -fsSL https://claude.ai/install.sh | bash

# Set PATH for the container environment (not just shell sessions)
ENV PATH="/home/coder/.local/bin:/opt/programmer/scripts:/opt/programmer/claude-code-team/scripts:${PATH}"
RUN echo 'alias claude="claude --dangerously-skip-permissions"' >> /home/coder/.bashrc

CMD ["bash", "scripts/entry-point.sh"]
