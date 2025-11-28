# Android Build Container Image
# Multi-stage Dockerfile for React Native/Expo Android builds
# Supports both Ubuntu and Debian base images

ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE} AS base

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    curl \
    git \
    python3 \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install Docker CLI (required for multi-stage builds)
# Handle both Ubuntu and Debian base images
RUN if [ -f /etc/os-release ]; then \
        . /etc/os-release; \
        if [ "$ID" = "debian" ]; then \
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
            DEB_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2 || echo "bullseye"); \
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $DEB_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null; \
        else \
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; \
            UBUNTU_CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2 || lsb_release -cs); \
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $UBUNTU_CODENAME stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null; \
        fi; \
    fi \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Java 17
ARG JAVA_VERSION=17
RUN apt-get update && apt-get install -y openjdk-${JAVA_VERSION}-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}
ENV PATH=${PATH}:/usr/lib/google-cloud-sdk/bin

# Install Node.js 20
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# Install Google Cloud SDK (gcloud and gsutil)
# Required for Secret Manager access and GCS operations in Cloud Build
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
    && apt-get update \
    && apt-get install -y google-cloud-sdk \
    && rm -rf /var/lib/apt/lists/*

# Install Android SDK
ARG ANDROID_SDK_ROOT=/opt/android-sdk
ENV ANDROID_SDK_ROOT=${ANDROID_SDK_ROOT}
ENV PATH=${PATH}:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools

RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools \
    && wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/cmdline-tools.zip \
    && unzip -q /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools \
    && mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest \
    && rm /tmp/cmdline-tools.zip

# Accept licenses and install Android components
ARG ANDROID_BUILD_TOOLS=34.0.0
ARG ANDROID_PLATFORM=34
ARG ANDROID_CMAKE_VERSION=3.22.1
ARG INSTALL_NDK=false
RUN yes | sdkmanager --licenses || true \
    && sdkmanager 'platform-tools' "platforms;android-${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" "cmake;${ANDROID_CMAKE_VERSION}" \
    && if [ "$INSTALL_NDK" = "true" ]; then \
        sdkmanager 'ndk;25.2.9519653'; \
    fi

# Set default Gradle JVM options (configurable via environment variables)
ENV GRADLE_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"
ENV JAVA_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=1024m"

# Create helper scripts directory and install helper scripts
# Install as root so scripts are accessible to all users
RUN mkdir -p /usr/local/bin
COPY scripts/helpers/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh && \
    # Ensure /usr/local/bin is in PATH (should be by default, but explicit is better)
    echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile

# Set working directory for builds
# Running as root for CI/CD compatibility (build containers are ephemeral and isolated)
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]

