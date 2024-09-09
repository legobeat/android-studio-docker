FROM ubuntu:22.04

LABEL Simon Egli <docker_android_studio_860dd6@egli.online>

ARG USER=android
ARG UID=1000
ARG GID=$UID

#RUN dpkg --add-architecture i386
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential git wget unzip sudo \
        libc6 libncurses5 libncurses6 libstdc++6 lib32z1 libbz2-1.0 \
        libxrender1 libxtst6 libxi6 libfreetype6 libxft2 xz-utils \
        libvirt-daemon-system \
        qemu qemu-kvm bridge-utils libnotify4 libglu1 libqt5widgets5 \
        openjdk-8-jdk openjdk-11-jdk openjdk-17-jdk openjdk-8-jre-headless openjdk-11-jre-headless openjdk-17-jre-headless \
        xvfb \
        xdg-user-dirs ssh-client libgtk2.0-bin libglib2.0-data \
        # qemu-utils qemu-block-extra libgdk-pixbuf2.0-bin libc-devtools librsvg2-common \
        && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -g $GID -r $USER
RUN useradd -u $UID -g $GID --create-home -r $USER
RUN adduser $USER libvirt
RUN adduser $USER kvm
#Change password
RUN echo "$UID:$GID" | chpasswd
#Make sudo passwordless
RUN echo "${USER} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-$USER
RUN usermod -aG sudo $USER
RUN usermod -aG plugdev $USER
RUN mkdir -p /androidstudio-data
VOLUME /androidstudio-data
RUN chown $UID:$GID /androidstudio-data

RUN mkdir -p /studio-data/Android/Sdk && \
    chown -R $UID:$GID /studio-data/Android


RUN mkdir -p /studio-data/profile/android && \
    chown -R $UID:$GID /studio-data/profile

COPY provisioning/docker_entrypoint.sh /usr/local/bin/docker_entrypoint.sh
COPY provisioning/ndkTests.sh /usr/local/bin/ndkTests.sh
RUN chmod +x /usr/local/bin/*
COPY provisioning/51-android.rules /etc/udev/rules.d/51-android.rules

USER $USER

WORKDIR /home/$USER

#Install Flutter
ARG FLUTTER_URL=https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.16.8-stable.tar.xz
ARG FLUTTER_VERSION=3.16.8

RUN wget "$FLUTTER_URL" -O flutter.tar.xz
RUN tar -xvf flutter.tar.xz
RUN rm flutter.tar.xz

#Android Studio
ARG ANDROID_STUDIO_VERSION=2024.1.2.12
ARG ANDROID_STUDIO_URL=https://dl.google.com/dl/android/studio/ide-zips/${ANDROID_STUDIO_VERSION}/android-studio-${ANDROID_STUDIO_VERSION}-linux.tar.gz
#ARG ANDROID_STUDIO_URL=https://redirector.gvt1.com/edgedl/android/studio/ide-zips/2023.1.1.27/android-studio-2023.1.1.27-linux.tar.gz

RUN wget "$ANDROID_STUDIO_URL" -O android-studio.tar.gz
RUN tar xzvf android-studio.tar.gz
RUN rm android-studio.tar.gz

RUN ln -s /studio-data/profile/AndroidStudio$ANDROID_STUDIO_VERSION .AndroidStudio$ANDROID_STUDIO_VERSION
RUN ln -s /studio-data/Android Android
RUN ln -s /studio-data/profile/android .android
RUN ln -s /studio-data/profile/java .java
RUN ln -s /studio-data/profile/gradle .gradle
ENV ANDROID_EMULATOR_USE_SYSTEM_LIBS=1

WORKDIR /home/$USER

ENTRYPOINT [ "/usr/local/bin/docker_entrypoint.sh" ]
