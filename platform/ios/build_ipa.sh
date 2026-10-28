#!/bin/sh
# build_ipa.sh - builds PinballNS.ipa (iPhone, arm64) from the C sources, without an Xcode project.
#
# On a Mac with Xcode: the real iOS SDK (xcrun --sdk iphoneos), and an ad-hoc signature.
# Elsewhere (Windows with Git Bash, Linux): clang and lld of the Android NDK (or of the system),
# the declarations of platform/apple/sdk, and the system libraries replaced at link time by .tbd
# lists of the symbols used (generated here). lld writes an ad-hoc signature.
#
# Either way the .ipa is not signed for a device: it is signed with your Apple ID when you
# install it (Sideloadly or AltStore on Windows, Xcode or Sideloadly on a Mac), see README.md.
#
#   IOS_MIN         lowest iOS version (default 14.0)
#   CC, LD, NM      tools (default: xcrun on a Mac, else the newest NDK under ANDROID_HOME)
#   ZIP_TOOL        build/mkzip (made by tools/build_msvc.bat mkzip, or make mkzip) when no zip
#   NDICON          build/ndicon (the icon)
set -e
cd "$(dirname "$0")/../.."
ROOT=$(pwd)
EXE=
if command -v cygpath >/dev/null 2>&1; then ROOT=$(cygpath -m "$ROOT"); EXE=.exe; fi
OUT=$ROOT/build/ios          # only Payload/: the content of the .ipa
WORK=$ROOT/build/ios-work    # objects, .tbd stubs
APP=$OUT/Payload/PinballNS.app
VERSION=$(sed -n 's/.*android:versionName="\([^"]*\)".*/\1/p' platform/android/AndroidManifest.xml)
BUILD=$(sed -n 's/.*android:versionCode="\([^"]*\)".*/\1/p' platform/android/AndroidManifest.xml)
IOS_MIN=${IOS_MIN:-14.0}
IOS_SDK=17.0

newest() { ls -d "$@" 2>/dev/null | sort -V | tail -1; }

SRCS="platform/ios/main_ios.c platform/ios/metal_render.c platform/mobile/app.c platform/mobile/ui.c \
 platform/mobile/design.c platform/mobile/screen.c src/game/pinball.c src/core/gbc.c src/core/gbc_exec.c src/core/gbc_ppu.c \
 src/core/gbc_apu.c"
FRAMEWORKS="Foundation UIKit QuartzCore Metal AudioToolbox GameController CoreMotion UniformTypeIdentifiers"
WARN="-Wall -Wextra -Wno-unused-function -Wno-unused-parameter -Wno-missing-field-initializers"

if [ -z "$CC" ] && command -v xcrun >/dev/null 2>&1 && xcrun --sdk iphoneos --show-sdk-path >/dev/null 2>&1; then
    MODE=xcode
    SDK=$(xcrun --sdk iphoneos --show-sdk-path)
    IOS_SDK=$(xcrun --sdk iphoneos --show-sdk-version)
    CC="xcrun --sdk iphoneos clang"
    NM="xcrun llvm-nm"
    CFLAGS="-arch arm64 -miphoneos-version-min=$IOS_MIN -isysroot $SDK -O2 -std=c11 -fblocks $WARN -DNDEBUG -DPB_ASM"
else
    MODE=mini
    if [ -z "$CC" ]; then
        for d in "$ANDROID_HOME" "$ANDROID_SDK_ROOT" "$HOME/Android/Sdk" "$LOCALAPPDATA/Android/Sdk"; do
            if [ -n "$d" ] && [ -d "$d/ndk" ]; then
                NDK_BIN=$(newest "$d"/ndk/*/toolchains/llvm/prebuilt/*/bin)
                [ -n "$NDK_BIN" ] && break
            fi
        done
        if [ -n "$NDK_BIN" ]; then
            CC=$NDK_BIN/clang$EXE; LD=${LD:-$NDK_BIN/ld.lld$EXE}; NM=${NM:-$NDK_BIN/llvm-nm$EXE}
        else
            CC=clang; LD=${LD:-ld.lld}; NM=${NM:-llvm-nm}
        fi
    fi
    LD=${LD:-ld.lld}
    NM=${NM:-llvm-nm}
    CFLAGS="--target=arm64-apple-ios$IOS_MIN -nostdlibinc -isystem platform/apple/sdk/libc -isystem platform/apple/sdk/include \
 -O2 -std=c11 -fblocks $WARN -fno-stack-protector -DNDEBUG -DPB_ASM"
fi
echo "mode:    $MODE (iOS $IOS_MIN, SDK $IOS_SDK)"
echo "clang:   $CC"

rm -rf "$WORK" "$OUT"
mkdir -p "$WORK/obj" "$APP"
for f in $SRCS; do
    $CC $CFLAGS -DPNS_VERSION="\"$VERSION\"" -c "$f" -o "$WORK/obj/$(basename "$f" .c).o"
done
$CC $CFLAGS -c src/core/cpu_a64.S -o "$WORK/obj/cpu_a64.o"     # the interpreter in assembly (tools/gencpu.c)

FWFLAGS=
for fw in $FRAMEWORKS; do FWFLAGS="$FWFLAGS -framework $fw"; done
if [ "$MODE" = xcode ]; then
    $CC -arch arm64 -miphoneos-version-min=$IOS_MIN -isysroot "$SDK" -dead_strip -o "$APP/PinballNS" "$WORK"/obj/*.o $FWFLAGS -lobjc
else
    # the system libraries: a .tbd per library, with the symbols the code takes from it
    # (the "file.o:" header lines of llvm-nm are skipped: the path may contain spaces)
    S=$WORK/stubs
    mkdir -p "$S/usr/lib"
    "$NM" -u "$WORK"/obj/*.o | awk '!/:$/ && NF>=1 {print $NF}' | sort -u > "$S/undef.txt"
    "$NM" --defined-only "$WORK"/obj/*.o | awk '!/:$/ && NF==3 {print $3}' | sort -u > "$S/def.txt"
    comm -23 "$S/undef.txt" "$S/def.txt" > "$S/ext.txt"
    echo dyld_stub_binder >> "$S/ext.txt"      # lazy binding helper (libdyld, through libSystem)
    for lib in System objc $FRAMEWORKS CoreFoundation; do : > "$S/$lib.syms"; done
    while read -r s; do
        case "$s" in
            _objc_*|_class_*|_sel_*|_object_*|_protocol_*|_method_*) lib=objc ;;
            _Audio*) lib=AudioToolbox ;;
            _UI*) lib=UIKit ;;
            _NS*) lib=Foundation ;;
            _CA*) lib=QuartzCore ;;
            _MTL*) lib=Metal ;;
            _GC*) lib=GameController ;;
            _CF*|_kCF*) lib=CoreFoundation ;;
            _CM*) lib=CoreMotion ;;
            _[A-Z]*) echo "error: which library has $s? (platform/ios/build_ipa.sh)" >&2; exit 1 ;;
            *) lib=System ;;
        esac
        echo "$s" >> "$S/$lib.syms"
    done < "$S/ext.txt"
    tbd() {   # tbd INSTALL_NAME SYMBOLS_FILE OUT
        {
            echo "--- !tapi-tbd"
            echo "tbd-version:     4"
            echo "targets:         [ arm64-ios ]"
            echo "install-name:    '$1'"
            if [ -s "$2" ]; then
                echo "exports:"
                echo "  - targets:         [ arm64-ios ]"
                echo "    symbols:         [ $(paste -sd, "$2" | sed 's/,/, /g') ]"
            fi
            echo "..."
        } > "$3"
    }
    tbd /usr/lib/libSystem.B.dylib "$S/System.syms" "$S/usr/lib/libSystem.tbd"
    tbd /usr/lib/libobjc.A.dylib "$S/objc.syms" "$S/usr/lib/libobjc.tbd"
    for fw in $FRAMEWORKS CoreFoundation; do
        mkdir -p "$S/System/Library/Frameworks/$fw.framework"
        tbd "/System/Library/Frameworks/$fw.framework/$fw" "$S/$fw.syms" "$S/System/Library/Frameworks/$fw.framework/$fw.tbd"
    done
    "$LD" -flavor darwin -arch arm64 -platform_version ios "$IOS_MIN" "$IOS_SDK" -syslibroot "$S" \
        -dead_strip -adhoc_codesign -o "$APP/PinballNS" "$WORK"/obj/*.o -lSystem -lobjc $FWFLAGS
    echo "system symbols used: $(wc -l < "$S/ext.txt") (list: build/ios-work/stubs/ext.txt)"
fi

# Info.plist, icon (the right flipper key of the Blue table, as on Android: 60 points, x2 and x3)
sed -e "s/@VERSION@/$VERSION/" -e "s/@BUILD@/$BUILD/" -e "s/@MINOS@/$IOS_MIN/" -e "s/@SDK@/$IOS_SDK/g" \
    platform/ios/Info.plist > "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"
NDICON=${NDICON:-$ROOT/build/ndicon$EXE}
"$NDICON" -flat 120 3 "$APP/AppIcon60x60@2x.png"
"$NDICON" -flat 180 4 "$APP/AppIcon60x60@3x.png"
if [ "$MODE" = xcode ]; then codesign --force --sign - "$APP" >/dev/null 2>&1 || true; fi

rm -f "$ROOT/build/PinballNS.ipa"
if [ -z "$ZIP_TOOL" ] && command -v zip >/dev/null 2>&1; then
    (cd "$OUT" && zip -qr -X "$ROOT/build/PinballNS.ipa" Payload)
else
    "${ZIP_TOOL:-$ROOT/build/mkzip$EXE}" "$ROOT/build/PinballNS.ipa" "$OUT" PinballNS
fi
echo "built $ROOT/build/PinballNS.ipa ($VERSION, build $BUILD)"
