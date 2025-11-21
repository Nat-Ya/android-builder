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
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null \
    && apt-get update \
    && apt-get install -y docker-ce-cli \
    && rm -rf /var/lib/apt/lists/*

# Install Java 17
ARG JAVA_VERSION=17
RUN apt-get update && apt-get install -y openjdk-${JAVA_VERSION}-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}

# Install Node.js 20
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
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
RUN yes | sdkmanager --licenses || true \
    && sdkmanager 'platform-tools' "platforms;android-${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}"

# Set default Gradle JVM options (configurable via environment variables)
ENV GRADLE_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=1024m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"
ENV JAVA_OPTS="-Xmx4096m -XX:MaxMetaspaceSize=1024m"

# Create non-root user for security
RUN useradd -m -s /bin/bash android-builder
USER android-builder
WORKDIR /home/android-builder

# Default command
CMD ["/bin/bash"]

