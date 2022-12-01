FROM eclipse-temurin:11-jdk-jammy

CMD ["gradle"]

ENV PRJOECT_HOME /home/gradle/project
ENV GRADLE_HOME /opt/gradle
ENV ANDROID_HOME /opt/android-sdk
ENV ANDROID_VERSION 31
ENV ANDROID_BUILD_TOOLS_VERSION 33.0.1
ENV GOOGLE_APPLICATION_CREDENTIALS /home/gradle/project/private/serviceaccount.json

# Предлагается прицепить volumes: (не нужно, т.к. все хранится в prject/.gradle)
# 1. /host/gradle/.gradle
# 2. /host/gradle/.m2


RUN set -o errexit -o nounset \
    && echo "Adding gradle user and group" \
    && groupadd --system --gid 1000 gradle \
    && useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle \
    && mkdir /home/gradle/.gradle \
    && mkdir /home/gradle/.m2 \
    && mkdir /home/gradle/project \
    && mkdir /home/gradle/project/.gradle \
    && chown --recursive gradle:gradle /home/gradle \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln --symbolic /home/gradle/project/.gradle /root/.gradle

WORKDIR /home/gradle/project

RUN set -o errexit -o nounset \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        unzip \
        wget \
        \
        bzr \
        git \
        git-lfs \
        mercurial \
        openssh-client \
        subversion \
    && rm --recursive --force /var/lib/apt/lists/* \
    \
    && echo "Testing VCSes" \
    && which bzr \
    && which git \
    && which git-lfs \
    && which hg \
    && which svn

ENV GRADLE_VERSION 7.5.1
ARG GRADLE_DOWNLOAD_SHA256=f6b8596b10cce501591e92f229816aa4046424f3b24d771751b06779d58c8ec4
RUN set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    \
    && echo "Checking download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum -c - \
    \
    && echo "Installing Gradle" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && echo "Testing Gradle installation" \
    && gradle --version

ARG ANDROIDSDK_DOWNLOAD_SHA256=0bebf59339eaa534f4217f8aa0972d14dc49e7207be225511073c661ae01da0a
RUN set -o errexit -o nounset \
    && mkdir -p "$ANDROID_HOME/cmdline-tools" .android \
    && cd "$ANDROID_HOME/cmdline-tools" \
    && echo "Downloading Android-sdk" \
    && wget --no-verbose --output-document=android-sdk.zip "https://dl.google.com/android/repository/commandlinetools-linux-9123335_latest.zip" \
    \
    && echo "Checking download hash" \
    && echo "${ANDROIDSDK_DOWNLOAD_SHA256} *android-sdk.zip" | sha256sum --check - \
    \
    && echo "Installing Android-sdk" \
    && unzip android-sdk.zip \
    && rm android-sdk.zip \
    && mv cmdline-tools tools \
    && mkdir "$ANDROID_HOME/licenses" || true \
    && echo "24333f8a63b6825ea9c5514f83c2829b004d1fee" > "$ANDROID_HOME/licenses/android-sdk-license" \
    && echo "84831b9409646a918e30573bab4c9c91346d8abd" > "$ANDROID_HOME/licenses/android-sdk-preview-license"

ENV PATH ${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/cmdline-tools/tools/bin:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator
RUN yes | sdkmanager --licenses \
    && sdkmanager --update \
    && sdkmanager "build-tools;${ANDROID_BUILD_TOOLS_VERSION}" \
    "platforms;android-${ANDROID_VERSION}" \
    "platform-tools"

