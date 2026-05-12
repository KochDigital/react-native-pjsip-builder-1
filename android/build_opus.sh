#!/bin/bash
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/opus/${TARGET_ARCH}

cp -r /sources/opus /tmp/opus

cd /tmp/opus/jni
"${ANDROID_NDK_ROOT}/ndk-build" \
    APP_ABI="${TARGET_ARCH}" \
    APP_PLATFORM="android-${ANDROID_TARGET_API}"

mkdir -p ${TARGET_PATH}/include
mkdir -p ${TARGET_PATH}/lib
cp -r ../include ${TARGET_PATH}/include/opus
cp ../obj/local/${TARGET_ARCH}/libopus.a ${TARGET_PATH}/lib/

rm -rf /tmp/pjsip