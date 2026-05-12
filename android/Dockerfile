FROM ubuntu:22.04

##############################
# Download dependencies
##############################

RUN dpkg --add-architecture i386 && \
    apt-get -y upgrade && \
    apt-get -y dist-upgrade && \
    apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get -y install \
    software-properties-common git curl bzip2 gcc g++ binutils make autoconf openssl \
    libssl-dev libc6-dev file ant libopus0 libpcre3 libpcre3-dev build-essential nasm libc6:i386 libstdc++6:i386 zlib1g:i386 \
    openjdk-17-jdk unzip python3 python3-distutils-extra

##############################
# Configuration
##############################

# ENV TARGET_ARCHS "armeabi armeabi-v7a x86 mips arm64-v8a x86_64 mips64"
ENV TARGET_ARCHS "armeabi-v7a x86 arm64-v8a x86_64"
# NDK r27b: minimum version that supports 16 KB page size ELF alignment (-Wl,-z,max-page-size=16384)
ENV ANDROID_NDK_DOWNLOAD_URL "https://dl.google.com/android/repository/android-ndk-r27b-linux.zip"
# ANDROID_TARGET_API raised to 29 to match app minSdkVersion
ENV ANDROID_TARGET_API 29

ENV PJSIP_DOWNLOAD_URL "https://github.com/pjsip/pjproject/archive/refs/tags/2.13.tar.gz"

ENV SWIG_DOWNLOAD_URL "http://prdownloads.sourceforge.net/swig/swig-4.1.1.tar.gz"

# OpenSSL 1.1.1w: last 1.1.x LTS — required because PJSIP 2.13 does not yet support OpenSSL 3.x
ENV OPENSSL_DOWNLOAD_URL "https://www.openssl.org/source/openssl-1.1.1w.tar.gz"

ENV OPUS_DOWNLOAD_URL "http://downloads.xiph.org/releases/opus/opus-1.2.1.tar.gz"
# trac.pjsip.org is permanently offline; the Android.mk is bundled in assets/
COPY assets/opus-Android.mk /usr/local/share/opus-Android.mk

ENV PATH /sources/android_ndk:$PATH

##############################
# Download sources
##############################

RUN mkdir -p /sources/android_ndk && \
    mkdir -p /sources/pjsip && \
    mkdir -p /sources/swig && \
    mkdir -p /sources/openssl && \
    mkdir -p /sources/opus

# Download Android NDK r27b (supports 16 KB ELF page alignment)
RUN cd /sources/android_ndk && \
    curl -L -# -o ndk.zip "$ANDROID_NDK_DOWNLOAD_URL" && \
    unzip ndk.zip && \
    rm -rf ndk.zip && \
    mv android-ndk-*/* ./

ENV ANDROID_NDK_ROOT /sources/android_ndk
# OpenSSL 1.1.x uses ANDROID_NDK_HOME; NDK r27 uses ANDROID_NDK_ROOT — export both
ENV ANDROID_NDK_HOME /sources/android_ndk
ENV MACHINE linux-x86_64
ENV TOOLCHAIN $ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/$MACHINE

# Download Pjsip
RUN cd /sources/pjsip && \
    curl -L -# -o pjsip.tar.gz "$PJSIP_DOWNLOAD_URL" && \
    tar xzf pjsip.tar.gz && \
    rm -rf pjsip.tar.gz && \
    mv pjproject-*/* ./

# Download Swig
RUN cd /sources/swig && \
    curl -L -# -o swig.tar.gz "$SWIG_DOWNLOAD_URL" && \
    tar xzf swig.tar.gz && \
    rm -rf swig.tar.gz && \
    mv swig-*/* ./

# Download OpenSSL
RUN cd /sources/openssl && \
    curl -L -# -o openssl.tar.gz "$OPENSSL_DOWNLOAD_URL" && \
    tar xzf openssl.tar.gz && \
    rm -rf openssl.tar.gz && \
    mv openssl-*/* ./

# Download Opus
RUN cd /sources/opus && \
    curl -L -# -o opus.tar.gz "$OPUS_DOWNLOAD_URL" && \
    tar xzf opus.tar.gz && \
    rm -rf opus.tar.gz && \
    mv opus-*/* ./ && \
    mkdir ./jni && \
    cp /usr/local/share/opus-Android.mk ./jni/Android.mk


##############################
# Build swig, openssl, opus
##############################

RUN mkdir -p /output/openssl/ && \
    mkdir -p /output/pjsip && \
    mkdir -p /output/opus

# Build opus
ADD ./build_opus.sh /usr/local/sbin/
RUN IFS=" " && \
    for arch in $TARGET_ARCHS; \
    do \
      /usr/local/sbin/build_opus.sh ${arch}; \
    done

# Build swig
RUN apt-get -y install libboost-dev libpcre3-dev
ENV PCRE2_DOWNLOAD_URL "https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.42/pcre2-10.42.tar.bz2"
RUN cd /sources/swig && \
    curl -L -# -o pcre2-10.42.tar.bz2 $PCRE2_DOWNLOAD_URL && \
    chmod +x ./Tools/pcre-build.sh && \
    ./Tools/pcre-build.sh && \
    ./configure && \
    make && \
    make install

# Build openssl
ADD ./build_openssl.sh /usr/local/sbin/
RUN IFS=" " && \
    for arch in $TARGET_ARCHS; \
    do \
      build_openssl.sh ${arch}; \
    done


# Build pjsip
ADD ./build_pjsip.sh /usr/local/sbin/

RUN IFS=" " && \
    for arch in $TARGET_ARCHS; \
    do \
      build_pjsip.sh ${arch}; \
    done

# Dist
RUN mkdir -p /dist/android/src/main && \
    mv /output/pjsip/* /dist/android/src/main && \
    rm -rf /dist/android/src/main/java/org/pjsip/pjsua2/app
