# Android Build Container Image
# Optimized multi-stage Dockerfile for React Native/Expo Android builds
# Supports both Ubuntu and Debian base images with optional components

# ============================================================================
# Stage 1: Base system with essential build tools
# ============================================================================
ARG BASE_IMAGE=ubuntu:22.04
FROM ${BASE_IMAGE} AS base

# Build arguments for optional components (reduce image size by disabling unused tools)
ARG INSTALL_DOCKER_CLI=false
ARG INSTALL_GCLOUD_SDK=false
ARG INSTALL_CMAKE=false
ARG INSTALL_NDK=false

# Install core system dependencies with minimal footprint
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    unzip \
    curl \
    git \
    python3 \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ============================================================================
# Optional: Docker CLI (only needed for Docker-in-Docker scenarios)
# ============================================================================
RUN if [ "$INSTALL_DOCKER_CLI" = "true" ]; then \
        if [ -f /etc/os-release ]; then \
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
        && apt-get install -y --no-install-recommends docker-ce-cli \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean; \
    fi

# ============================================================================
# Install Java (OpenJDK JRE for smaller size, JDK if needed)
# ============================================================================
ARG JAVA_VERSION=17
ARG JAVA_PACKAGE=openjdk-17-jdk-headless
RUN apt-get update && apt-get install -y --no-install-recommends ${JAVA_PACKAGE} \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV PATH=${JAVA_HOME}/bin:${PATH}

# ============================================================================
# Install Node.js
# ============================================================================
ARG NODE_VERSION=20
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && npm cache clean --force

# ============================================================================
# Optional: Google Cloud SDK (only needed for GCP Secret Manager/GCS)
# ============================================================================
RUN if [ "$INSTALL_GCLOUD_SDK" = "true" ]; then \
        echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
        && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg \
        && apt-get update \
        && apt-get install -y --no-install-recommends google-cloud-sdk \
        && rm -rf /var/lib/apt/lists/* \
        && apt-get clean; \
    fi

ENV PATH=${PATH}:/usr/lib/google-cloud-sdk/bin

# ============================================================================
# Install Android SDK and build tools
# ============================================================================
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
RUN yes | sdkmanager --licenses || true \
    && sdkmanager 'platform-tools' "platforms;android-${ANDROID_PLATFORM}" "build-tools;${ANDROID_BUILD_TOOLS}" \
    && if [ "$INSTALL_CMAKE" = "true" ]; then \
        sdkmanager "cmake;${ANDROID_CMAKE_VERSION}"; \
    fi \
    && if [ "$INSTALL_NDK" = "true" ]; then \
        sdkmanager 'ndk;25.2.9519653'; \
    fi

# ============================================================================
# Performance optimizations: Gradle, Kotlin, and Android build settings
# ============================================================================

# Gradle JVM heap and metaspace (increase for large projects)
ENV GRADLE_OPTS="-Xmx6144m -XX:MaxMetaspaceSize=2048m -XX:+HeapDumpOnOutOfMemoryError -Dfile.encoding=UTF-8"
ENV JAVA_OPTS="-Xmx6144m -XX:MaxMetaspaceSize=2048m"

# Android build performance settings
# These can be overridden per-project via gradle.properties
ENV ORG_GRADLE_PARALLEL=true
ENV ORG_GRADLE_CACHING=true
ENV ORG_GRADLE_DAEMON=true
ENV ORG_GRADLE_CONFIGUREONDEMAND=true
ENV ORG_GRADLE_JVMARGS="-Xmx6144m -XX:MaxMetaspaceSize=2048m -XX:+HeapDumpOnOutOfMemoryError -XX:+UseParallelGC"

# Kotlin compiler daemon settings (faster Kotlin compilation)
ENV KOTLIN_DAEMON_JVMARGS="-Xmx2048m -XX:MaxMetaspaceSize=512m"
ENV KOTLIN_INCREMENTAL=true

# Android-specific build optimizations
ENV ANDROID_BUILDER_SDKLOADER_CACHEDIR=${ANDROID_SDK_ROOT}/.android-sdk-cache

# Dex compilation in-process (faster but uses more memory)
ENV ANDROID_USE_LEGACY_MULTIDEX_LIBRARY=false

# R8/ProGuard optimization settings
ENV ANDROID_R8_MAX_WORKERS=4

# Build cache directory
ENV GRADLE_USER_HOME=/root/.gradle

# ============================================================================
# Gradle optimization: Pre-create cache directory structure
# ============================================================================
RUN mkdir -p ${GRADLE_USER_HOME}/caches \
    && mkdir -p ${GRADLE_USER_HOME}/wrapper

# ============================================================================
# Install helper scripts
# ============================================================================
RUN mkdir -p /usr/local/bin
COPY scripts/helpers/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh && \
    echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/profile

# ============================================================================
# Set working directory and final setup
# ============================================================================
WORKDIR /workspace

# Default command
CMD ["/bin/bash"]

