# Base image
FROM --platform=linux/amd64 docker.io/jenkins/jnlp-slave:latest-jdk11

# Avoid prompts during package installation
ARG DEBIAN_FRONTEND=noninteractive

# Set environment variables for asdf
ENV ASDF_DATA_DIR /usr/local/asdf
ENV ASDF_CONFIG_FILE /usr/local/asdf/.asdfrc
ENV ASDF_DEFAULT_TOOL_VERSIONS_FILENAME=/usr/local/asdf/.tool-versions
ENV PATH="/usr/local/asdf/bin:/usr/local/asdf/shims:$PATH"

# Switch to root temporarily to manage package installs
USER root

# Clone asdf and install necessary files into the image
RUN git clone https://github.com/asdf-vm/asdf.git /usr/local/asdf && \
    chmod 755 /usr/local/asdf && \
    mkdir -p /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh && \
    chown -R jenkins:jenkins /usr/local/asdf /home/jenkins

COPY ./docker/jenkins/asdfrc /usr/local/asdf/.asdfrc
COPY ./docker/jenkins/tool-versions /usr/local/asdf/.tool-versions

# Install required packages and tools
RUN apt-get update && \
    apt-get install -y \
        bash \
        apt-utils \
        autoconf \
        automake \
        bzip2 \
        g++ \
        git \
        gnupg2 \
        groff \
        keychain \
        libssl-dev \
        make \
        rsync \
        unzip \
        zlib1g-dev \
        build-essential \
        curl \
        libbz2-dev \
        libffi-dev \
        liblzma-dev \
        libncurses5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libxslt1-dev \
        libxcursor-dev \
        jq \
        netcat-openbsd \
        net-tools \
        procps \
        openssl \
        llvm \
        tar \
        tk-dev \
        wget \
        xz-utils \
        zip \
        openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create SSHD run directory and configure SSHD
RUN mkdir /var/run/sshd && \
    echo 'jenkins:jenkins' | chpasswd && \
    sed -i 's/^#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo "PasswordAuthentication no" >> /etc/ssh/sshd_config && \
    echo "ChallengeResponseAuthentication no" >> /etc/ssh/sshd_config && \
    echo "UsePAM yes" >> /etc/ssh/sshd_config && \
    echo "AllowTcpForwarding yes" >> /etc/ssh/sshd_config && \
    echo "Subsystem sftp /usr/lib/openssh/sftp-server" >> /etc/ssh/sshd_config

# Expose the SSH port
EXPOSE 22

# Configure Jenkins Home Directory
RUN mkdir -p /home/jenkins && \
    chown -R jenkins:jenkins /home/jenkins && \
    chmod 700 /home/jenkins

# Create SSH directory for Jenkins user
RUN mkdir -p /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh && \
    chown -R jenkins:jenkins /home/jenkins/.ssh

# Install AWS CLI v2
RUN curl https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/aws.zip && \
    unzip /tmp/aws.zip -d /tmp && \
    /tmp/aws/install && \
    rm -rf /tmp/aws.zip /tmp/aws && \
    /usr/local/bin/aws --version && \
    mkdir -p -m 777 /opt/stack

# Install Azure CLI
RUN curl -fsSL https://aka.ms/InstallAzureCLIDeb | bash && \
    az --version

# Install Google Cloud SDK
RUN mkdir -p /usr/share/keyrings && \
    curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
    apt-get update && \
    apt-get install -y google-cloud-cli && \
    gcloud --version && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Ant
RUN curl -fsSL -o /tmp/apache-ant-bin.tar.gz https://archive.apache.org/dist/ant/binaries/apache-ant-1.10.12-bin.tar.gz && \
    tar -xzf /tmp/apache-ant-bin.tar.gz -C /opt && \
    ln -sf /opt/apache-ant-1.10.12/bin/ant /usr/local/bin/ant && \
    ant -version && \
    rm -rf /tmp/apache-ant-bin.tar.gz

# Install Gradle
RUN curl -fsSL -o /tmp/gradle-bin.zip https://services.gradle.org/distributions/gradle-7.6-bin.zip && \
    unzip /tmp/gradle-bin.zip -d /opt && \
    ln -sf /opt/gradle-7.6/bin/gradle /usr/local/bin/gradle && \
    gradle --version && \
    rm -rf /tmp/gradle-bin.zip

# Install Maven
RUN curl -fsSL -o /tmp/maven-bin.zip https://archive.apache.org/dist/maven/maven-3/3.9.8/binaries/apache-maven-3.9.8-bin.zip && \
    unzip /tmp/maven-bin.zip -d /opt && \
    ln -sf /opt/apache-maven-3.9.8/bin/mvn /usr/local/bin/mvn && \
    mvn -version && \
    rm -rf /tmp/maven-bin.zip

# Install Node.js and npm using nvm
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash && \
    export NVM_DIR="$HOME/.nvm" && \
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && \
    nvm install 16 && \
    nvm alias default 16 && \
    nvm use default && \
    npm -v

# Install rbenv and ruby-build
RUN git clone https://github.com/rbenv/rbenv.git /root/.rbenv && \
    git clone https://github.com/rbenv/ruby-build.git /root/.rbenv/plugins/ruby-build

# Set up rbenv environment
RUN echo 'export RBENV_ROOT="/root/.rbenv"' >> /root/.bashrc && \
    echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /root/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> /root/.bashrc

# Install Ruby and Bundler
RUN export RBENV_ROOT="/root/.rbenv" && \
    export PATH="$RBENV_ROOT/bin:$PATH" && \
    eval "$(rbenv init -)" && \
    /root/.rbenv/bin/rbenv install 3.1.2 && \
    /root/.rbenv/bin/rbenv global 3.1.2 && \
    /root/.rbenv/shims/gem install bundler && \
    /root/.rbenv/shims/ruby -v && \
    /root/.rbenv/shims/bundler -v

# Install Terraform
RUN curl -fsSL https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/terraform && \
    terraform --version && \
    rm -rf /tmp/terraform.zip

# Install Helm
RUN curl -fsSL https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz -o /tmp/helm.tar.gz && \
    tar -xzf /tmp/helm.tar.gz -C /tmp && \
    mv /tmp/linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    helm version --short && \
    rm -rf /tmp/helm.tar.gz /tmp/linux-amd64

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/v1.27.5/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    kubectl version --client --short

# Clean up local data added to the container image
COPY ./docker/jenkins/requirements.txt /opt/stack/core/requirements.txt
COPY --chown=jenkins:jenkins . /opt/stack/core
RUN rm -rf /opt/stack/core/__pycache__ && \
    cd /opt/stack/core && \
    pip install -r requirements.txt && \
    rm -rf /opt/stack/core/__pycache__ /opt/stack/core/*.pyc

# Configure the Jenkins user to have a valid home directory and SSH keys
RUN chown -R jenkins:jenkins /home/jenkins/.ssh && \
    chmod 700 /home/jenkins/.ssh && \
    chmod 600 /home/jenkins/.ssh/authorized_keys

# Ensure that SSH runs in the foreground
CMD ["/usr/sbin/sshd", "-D"]

# Final version check for all installed tools
RUN echo 'checking tools versions' && \
    java -version && \
    mvn -version && \
    gradle --version && \
    ant -version && \
    terraform --version && \
    helm version --short && \
    kubectl version --client --short && \
    aws --version && \
    az --version && \
    gcloud --version && \
    python --version && \
    /root/.rbenv/shims/ruby -v && \
    /root/.rbenv/shims/bundler -v && \
    pip --version