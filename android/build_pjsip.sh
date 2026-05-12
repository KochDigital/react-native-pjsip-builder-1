#!/bin/bash
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/pjsip/${TARGET_ARCH}
cp -r /sources/pjsip /tmp/pjsip

# TODO: Use flags like in vialerpjsip for config.h
cat <<EOF > "/tmp/pjsip/pjlib/include/pj/config_site.h"
#define PJ_CONFIG_ANDROID 1
#define PJMEDIA_HAS_G729_CODEC 1
#define PJMEDIA_HAS_G7221_CODEC 1
#include <pj/config_site_sample.h>
#define PJMEDIA_AUDIO_DEV_HAS_OPENSL 1
#define PJSIP_AUTH_AUTO_SEND_NEXT 0
EOF

cd /tmp/pjsip

export TARGET_ABI=${TARGET_ARCH}
export APP_PLATFORM=android-${ANDROID_TARGET_API}
export ANDROID_NDK_ROOT=/sources/android_ndk

# 16 KB memory page support (required by Google Play for targetSdk >= 35 apps with native libs).
# -Wl,-z,max-page-size=16384 instructs the linker to align ELF LOAD segments to 16 KB (0x4000)
# so the library can be mmap-ed on both 4 KB and 16 KB page-size kernels without re-extraction.
# NDK r26b+ is required for this flag to be honoured; we use r27b.
# See: https://developer.android.com/guide/practices/page-sizes
export LDFLAGS="-Wl,-z,max-page-size=16384"

./configure-android \
    --use-ndk-cflags \
    --with-ssl="/output/openssl/${TARGET_ARCH}" \
    --with-opus="/output/opus/${TARGET_ARCH}"

make dep
make

cd /tmp/pjsip/pjsip-apps/src/swig
make

ls -l ./java/android/pjsua2/src/main/jniLibs/

mkdir -p /output/pjsip/jniLibs/${TARGET_ARCH}/
mv ./java/android/pjsua2/src/main/jniLibs/**/libpjsua2.so /output/pjsip/jniLibs/${TARGET_ARCH}/

if [ ! -d "/output/pjsip/java" ]; then
  mv ./java/android/pjsua2/src/main/java /output/pjsip/java
fi

rm -rf /tmp/pjsip