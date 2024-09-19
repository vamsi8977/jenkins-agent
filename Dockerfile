# Base image
FROM --platform=linux/amd64 docker.io/jenkins/jnlp-slave:latest-jdk11

# Avoid prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Set environment variables for asdf
#ENV ASDF_DATA_DIR /usr/local/asdf
#ENV ASDF_CONFIG_FILE /usr/local/asdf/.asdfrc
#ENV ASDF_DEFAULT_TOOL_VERSIONS_FILENAME=/usr/local/asdf/.tool-versions
#ENV PATH="/usr/local/asdf/bin:/usr/local/asdf/shims:$PATH"

# Switch to root temporarily to manage package installs
USER root

# Clone asdf
RUN git clone https://github.com/asdf-vm/asdf.git /usr/local/asdf
