# react-native-pjsip-builder

Docker-based build system for PJSIP with OpenSSL, Opus and G.729 for Android.
Forked from [aldiand/react-native-pjsip-builder](https://github.com/aldiand/react-native-pjsip-builder)
and maintained by [KochDigital](https://github.com/KochDigital).

## Library versions

| Library     | Version | Notes |
|-------------|---------|-------|
| Android API | 29      | Matches `minSdkVersion` of the app |
| Android NDK | r27b    | Required for 16 KB ELF page alignment |
| PJSIP       | 2.13    | |
| OpenSSL     | 1.1.1w  | Last LTS 1.1.x release (PJSIP 2.13 does not support OpenSSL 3.x) |
| OPUS        | 1.2.1   | |

## Target ABIs

`armeabi-v7a`, `x86`, `arm64-v8a`, `x86_64`

## 16 KB memory page support

Starting from **v3.3-16kb** this build produces ELF libraries aligned to
16 KB (`-Wl,-z,max-page-size=16384`), which is required by Google Play
for apps with `targetSdk ≥ 35` as of May 2025.

The flag is applied in `android/build_pjsip.sh` via:
```bash
export LDFLAGS="-Wl,-z,max-page-size=16384"
```

NDK r26b+ is required for this flag to be honoured. This fork uses **r27b**.

Verify alignment after build:
```bash
llvm-readelf --program-headers libpjsua2.so | grep Align
# Expected: Align 0x4000
```

## Build for Android

Prerequisites: Docker installed and running.

```bash
git clone https://github.com/KochDigital/react-native-pjsip-builder-1
cd react-native-pjsip-builder-1
./build_android.sh
# Output: dist/android/src/main/jniLibs/<abi>/libpjsua2.so
```

The build takes ~20-40 minutes on first run (downloads and compiles all
dependencies inside Docker). Subsequent runs reuse Docker layer cache.

## Updating the callkeep fork

After a successful build, update the `libs.sh` version reference in
[KochDigital/react-native-callkeep](https://github.com/KochDigital/react-native-callkeep)
to point to the new release tag and run `npm install` in the app repo.
