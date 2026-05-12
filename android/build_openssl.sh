#!/bin/bash
# Build OpenSSL for Android using the NDK r27 unified clang toolchain.
# NDK r17+ removed GCC; this script uses the llvm/prebuilt clang compiler for all ABIs.
# OpenSSL 1.1.x is required because PJSIP 2.13 does not support OpenSSL 3.x.
set -e

TARGET_ARCH=$1
TARGET_PATH=/output/openssl/${TARGET_ARCH}

cp -r /sources/openssl /tmp/openssl
cd /tmp/openssl

TOOLCHAIN="${ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/${MACHINE}"
export PATH="${TOOLCHAIN}/bin:${PATH}"

case "$TARGET_ARCH" in
    armeabi-v7a)
        TARGET=android-arm
        CLANG_TARGET="armv7a-linux-androideabi${ANDROID_TARGET_API}"
        ;;
    arm64-v8a)
        TARGET=android-arm64
        CLANG_TARGET="aarch64-linux-android${ANDROID_TARGET_API}"
        ;;
    x86)
        TARGET=android-x86
        CLANG_TARGET="i686-linux-android${ANDROID_TARGET_API}"
        ;;
    x86_64)
        TARGET=android-x86_64
        CLANG_TARGET="x86_64-linux-android${ANDROID_TARGET_API}"
        ;;
    *)
        echo "Unsupported target ABI: $TARGET_ARCH" >&2
        exit 1
        ;;
esac

export CC="${TOOLCHAIN}/bin/${CLANG_TARGET}-clang"
export CXX="${TOOLCHAIN}/bin/${CLANG_TARGET}-clang++"
export AR="${TOOLCHAIN}/bin/llvm-ar"
export RANLIB="${TOOLCHAIN}/bin/llvm-ranlib"
export STRIP="${TOOLCHAIN}/bin/llvm-strip"

./Configure ${TARGET} \
    no-asm \
    no-unit-test \
    no-shared \
    --prefix="${TARGET_PATH}" \
    --openssldir="${TARGET_PATH}"

make -j$(nproc)
make install_sw

rm -rf /tmp/openssl
