#!/bin/sh
# build_apk.sh - builds PinballNS.apk (arm64) from the C sources, without Gradle or Java code.
#
#   ABIS="arm64-v8a x86_64" OUT_APK=build/PinballNS-test.apk sh platform/android/build_apk.sh
#                     also the x86_64 library: for the Android emulator of the PC (tools/emu.sh)
#
# Needs: clang + lld able to target aarch64-linux-android, an Android sysroot (headers),
# aapt, zipalign, apksigner (+ keytool), android.jar, and tools/ndicon (built by `make`).
#
#   ANDROID_HOME      Android SDK (build-tools, platforms, ndk); default: the usual places
#   ANDROID_NDK_HOME  Android NDK (clang, lld, sysroot); default: the newest $ANDROID_HOME/ndk/*
#   ANDROID_SYSROOT   directory with usr/include (default: the NDK's, or ../android-sdk/sysroot)
#   ANDROID_JAR       android.jar used by aapt (default: the SDK's android-34, or
#                     /usr/lib/android-sdk/platforms/android-23/android.jar)
#   CC, LLVM_NM, LLVM_STRIP, AAPT, ZIPALIGN, APKSIGNER   tools (default: from the NDK / SDK)
#   ABIS              native libraries to build (default: arm64-v8a; also: x86_64)
#   OUT_APK           the APK made (default: build/PinballNS.apk)
#   EXTRA_CFLAGS      more compiler options (tools/emu.sh: -DPNS_TEST, its test commands)
#   APK_DEBUGGABLE    1: android:debuggable (tools/emu.sh: files put into the app's own folder)
#
# Works on Linux and on Windows (Git Bash / MSYS) with the Windows NDK and SDK.
#
# The libraries the app uses (libc, libandroid, libEGL...) are linked against small
# stub libraries generated here, so only the headers are needed; on the device the
# real system libraries are used.
set -e
cd "$(dirname "$0")/../.."
ROOT=$(pwd)
EXE=
BAT=
if command -v cygpath >/dev/null 2>&1; then
    # Windows: give the native tools C:/... paths, and find their .exe / .bat
    ROOT=$(cygpath -m "$ROOT")
    EXE=.exe
    BAT=.bat
fi
OUT=$ROOT/build/android
API=26
ABIS=${ABIS:-arm64-v8a}
OUT_APK=${OUT_APK:-$ROOT/build/PinballNS.apk}

newest() { ls -d "$@" 2>/dev/null | sort -V | tail -1; }
winpath() { if [ -n "$EXE" ] && [ -n "$1" ]; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }

# ---- SDK and NDK
if [ -z "$ANDROID_HOME" ]; then
    for d in "$ANDROID_SDK_ROOT" "$LOCALAPPDATA/Android/Sdk" "$HOME/Android/Sdk" /usr/lib/android-sdk; do
        if [ -n "$d" ] && [ -d "$d" ]; then ANDROID_HOME=$d; break; fi
    done
fi
ANDROID_HOME=$(winpath "$ANDROID_HOME")
if [ -z "$ANDROID_NDK_HOME" ] && [ -n "$ANDROID_HOME" ]; then ANDROID_NDK_HOME=$(newest "$ANDROID_HOME"/ndk/*); fi
ANDROID_NDK_HOME=$(winpath "$ANDROID_NDK_HOME")
NDK_BIN=
if [ -n "$ANDROID_NDK_HOME" ]; then NDK_BIN=$(newest "$ANDROID_NDK_HOME"/toolchains/llvm/prebuilt/*/bin); fi
BUILD_TOOLS=
if [ -n "$ANDROID_HOME" ]; then BUILD_TOOLS=$(newest "$ANDROID_HOME"/build-tools/*); fi

if [ -z "$ANDROID_SYSROOT" ]; then
    if [ -n "$ANDROID_NDK_HOME" ]; then
        ANDROID_SYSROOT=$(newest "$ANDROID_NDK_HOME"/toolchains/llvm/prebuilt/*/sysroot)
    else
        ANDROID_SYSROOT=$ROOT/../android-sdk/sysroot
    fi
fi
if [ -z "$ANDROID_JAR" ]; then
    ANDROID_JAR=/usr/lib/android-sdk/platforms/android-23/android.jar
    if [ -n "$ANDROID_HOME" ] && [ -f "$ANDROID_HOME/platforms/android-34/android.jar" ]; then
        ANDROID_JAR=$ANDROID_HOME/platforms/android-34/android.jar
    fi
fi

tool() {   # tool NAME DIR SUFFIX: DIR/NAME+SUFFIX if it exists, else NAME (from the PATH)
    if [ -n "$2" ] && [ -f "$2/$1$3" ]; then printf '%s\n' "$2/$1$3"; else printf '%s\n' "$1"; fi
}
CC=${CC:-$(tool clang "$NDK_BIN" "$EXE")}
LLVM_NM=${LLVM_NM:-$(tool llvm-nm "$NDK_BIN" "$EXE")}
LLVM_STRIP=${LLVM_STRIP:-$(tool llvm-strip "$NDK_BIN" "$EXE")}
AAPT=${AAPT:-$(tool aapt "$BUILD_TOOLS" "$EXE")}
ZIPALIGN=${ZIPALIGN:-$(tool zipalign "$BUILD_TOOLS" "$EXE")}
APKSIGNER=${APKSIGNER:-$(tool apksigner "$BUILD_TOOLS" "$BAT")}
echo "clang:     $CC"
echo "sysroot:   $ANDROID_SYSROOT"
echo "android:   $ANDROID_JAR"
echo "apksigner: $APKSIGNER"

rm -rf "$OUT/obj" "$OUT/stubs" "$OUT/apk"
mkdir -p "$OUT/res"

SRCS="platform/android/main_android.c platform/android/gles_render.c platform/mobile/app.c platform/mobile/ui.c platform/mobile/design.c src/game/pinball.c \
 src/core/gbc.c src/core/gbc_exec.c src/core/gbc_ppu.c src/core/gbc_apu.c"

# build_lib ABI: lib/ABI/libpinballtc.so
build_lib() {
    abi=$1
    case "$abi" in
        arm64-v8a) TARGET=aarch64-linux-android$API
            # -mno-outline-atomics: atomic read-modify-write operations are inlined. Otherwise clang
            # calls __aarch64_* helpers from its runtime library, which this link does not include
            # and which no system library exports: the app would not even start.
            # cpu_a64.S: the interpreter of the SM83 in assembly (tools/gencpu.c)
            ARCHFLAGS="-mno-outline-atomics -DPB_ASM"; ASM=src/core/cpu_a64.S ;;
        x86_64) TARGET=x86_64-linux-android$API; ARCHFLAGS=""; ASM= ;;
        *) echo "unknown ABI $abi" >&2; exit 1 ;;
    esac
    O=$OUT/obj/$abi
    ST=$OUT/stubs/$abi
    mkdir -p "$O" "$ST" "$OUT/apk/lib/$abi"
    CFLAGS="--target=$TARGET --sysroot=$ANDROID_SYSROOT -fPIC -O2 -std=c11 -Wall -Wextra -Wno-unused-function \
 -fvisibility=hidden -ffunction-sections -fdata-sections -fno-stack-protector $ARCHFLAGS -DNDEBUG $EXTRA_CFLAGS"
    for f in $SRCS; do
        "$CC" $CFLAGS -c "$f" -o "$O/$(basename "$f" .c).o"
    done
    [ -z "$ASM" ] || "$CC" $CFLAGS -c "$ASM" -o "$O/$(basename "$ASM" .S).o"

    # stub system libraries: one empty function per symbol the code uses
    # (the "file.o:" header lines are skipped: the project path may contain spaces)
    "$LLVM_NM" -u "$O"/*.o | awk '!/:$/ && NF==2 {print $2}' | sort -u > "$ST/undef.txt"
    "$LLVM_NM" --defined-only "$O"/*.o | awk '!/:$/ && NF==3 {print $3}' | sort -u > "$ST/def.txt"
    comm -23 "$ST/undef.txt" "$ST/def.txt" > "$ST/ext.txt"
    # helpers of the compiler's runtime library are not system symbols (see -mno-outline-atomics)
    if grep -E '^__(aarch64_|emutls|clear_cache|(u?(div|mod|mul)ti3)|[a-z]+tf[23]?$)' "$ST/ext.txt"; then
        echo "error: the code needs helpers of the compiler runtime (above): no system library has them" >&2
        exit 1
    fi
    for lib in c m dl log android EGL GLESv2 aaudio; do : > "$ST/$lib.c"; done
    while read -r s; do
        case "$s" in
            AAudio*) lib=aaudio ;;
            AInput*|AKeyEvent*|ALooper*|AMotionEvent*|ANativeActivity*|ANativeWindow*|AConfiguration*|AAsset*|ASensor*) lib=android ;;
            __android_log*) lib=log ;;
            dlopen|dlsym|dlclose|dlerror) lib=dl ;;
            egl*) lib=EGL ;;
            gl*) lib=GLESv2 ;;
            pow|powf|sqrt|sqrtf|floor|floorf|ceil|ceilf|fabs|fabsf|fmin|fminf|fmax|fmaxf|sin|sinf|cos|cosf|atan2|atan2f|exp|expf|log|logf|lround|lroundf|lrint|lrintf|round|roundf|fmod|fmodf|sincos|sincosf) lib=m ;;
            *) lib=c ;;
        esac
        echo "void $s(void) {}" >> "$ST/$lib.c"
    done < "$ST/ext.txt"
    for lib in c m dl log android EGL GLESv2 aaudio; do
        "$CC" --target=$TARGET -nostdlib -shared -fPIC -fuse-ld=lld -w -fno-builtin -Wl,-soname,lib$lib.so \
            -o "$ST/lib$lib.so" "$ST/$lib.c"
    done

    "$CC" --target=$TARGET -nostdlib -shared -fuse-ld=lld -Wl,-soname,libpinballtc.so -Wl,--gc-sections \
        -Wl,-z,defs -Wl,-z,max-page-size=16384 -Wl,--build-id=sha1 -Wl,--hash-style=both -Wl,-z,noexecstack \
        -o "$OUT/apk/lib/$abi/libpinballtc.so" "$O"/*.o \
        -L"$ST" -laaudio -lEGL -lGLESv2 -landroid -llog -ldl -lm -lc
    "$LLVM_STRIP" --strip-unneeded "$OUT/apk/lib/$abi/libpinballtc.so"
    echo "$abi: system symbols used: $(wc -l < "$ST/ext.txt") (list: build/android/stubs/$abi/ext.txt)"
}
for abi in $ABIS; do build_lib "$abi"; done

# launcher icon: the right flipper key of the Blue table, pixel perfect (whole enlargements of
# its 32 x 32 pixels): the layers of the adaptive icon (108 dp, the key in the 66 dp safe zone,
# the blue of the table behind), and the key on the blue for older launchers (48 dp)
rm -rf "$OUT/res/mipmap-"*
for d in mdpi:48:2:108:2 hdpi:72:2:162:2 xhdpi:96:2:216:3 xxhdpi:144:4:324:5 xxxhdpi:192:5:432:7; do
    dir=$(echo "$d" | cut -d: -f1); size=$(echo "$d" | cut -d: -f2); fs=$(echo "$d" | cut -d: -f3)
    layer=$(echo "$d" | cut -d: -f4); ks=$(echo "$d" | cut -d: -f5)
    mkdir -p "$OUT/res/mipmap-$dir"
    "$ROOT/build/ndicon$EXE" -flat "$size" "$fs" "$OUT/res/mipmap-$dir/ic_launcher.png"
    "$ROOT/build/ndicon$EXE" -key "$layer" "$ks" "$OUT/res/mipmap-$dir/ic_launcher_foreground.png"
    "$ROOT/build/ndicon$EXE" -bg "$layer" "$OUT/res/mipmap-$dir/ic_launcher_background.png"
done
mkdir -p "$OUT/res/mipmap-anydpi-v26"
cat > "$OUT/res/mipmap-anydpi-v26/ic_launcher.xml" <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@mipmap/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
XML

# package, align, sign
rm -f "$OUT/unsigned.apk" "$OUT/aligned.apk"
DEBUG_MODE=
if [ "$APK_DEBUGGABLE" = 1 ]; then DEBUG_MODE=--debug-mode; fi
"$AAPT" package -f $DEBUG_MODE -M platform/android/AndroidManifest.xml -S "$OUT/res" -I "$ANDROID_JAR" -F "$OUT/unsigned.apk"
for abi in $ABIS; do (cd "$OUT/apk" && "$AAPT" add "$OUT/unsigned.apk" lib/$abi/libpinballtc.so > /dev/null); done
"$ZIPALIGN" -f -p 4 "$OUT/unsigned.apk" "$OUT/aligned.apk"
KEY=$ROOT/platform/android/pinballtc.keystore
if [ ! -f "$KEY" ]; then
    keytool -genkeypair -keystore "$KEY" -storepass pinballtc -keypass pinballtc -alias pinballtc \
        -keyalg RSA -keysize 2048 -validity 20000 -dname "CN=Pinball TC, OU=usage personnel" > /dev/null 2>&1
fi
"$APKSIGNER" sign --ks "$KEY" --ks-pass pass:pinballtc --key-pass pass:pinballtc --ks-key-alias pinballtc \
    --out "$OUT_APK" "$OUT/aligned.apk"
"$APKSIGNER" verify "$OUT_APK"
echo "built $OUT_APK ($ABIS)"
