#!/bin/sh
# build_mac.sh - builds "Pinball NS.app" (macOS 10.15 and later, universal: Apple silicon and Intel) and its
# zip, build/PinballNS-macOS-VERSION.zip, from the C sources, without an Xcode project.
#
# On a Mac with Xcode: the real macOS SDK (xcrun), then an ad-hoc signature (codesign).
# Elsewhere (Windows with Git Bash, Linux): the clang and lld of the Android NDK, the declarations of
# platform/apple/sdk (as platform/ios/build_ipa.sh), the system libraries replaced at link time by .tbd
# lists of the symbols used (generated here); lld signs each slice ad hoc.
#
# The app is not notarized: the first time, open it with a right click > Open (or allow it in System
# Settings > Privacy & Security), see platform/macos/README.md.
#
#   CC, LD, NM, LIPO   tools (default: xcrun on a Mac, else the newest NDK under ANDROID_HOME)
#   ZIP_TOOL           build/mkzip (tools/build_msvc.bat mkzip) when there is no zip
#   NDICON             build/ndicon (the icon)
set -e
cd "$(dirname "$0")/../.."
ROOT=$(pwd)
EXE=
if command -v cygpath >/dev/null 2>&1; then ROOT=$(cygpath -m "$ROOT"); EXE=.exe; fi
VERSION=$(sed -n 's/#define DESK_VERSION "\(.*\)"/\1/p' platform/desktop/desk.h)
BUILD=$(sed -n 's/.*android:versionCode="\([^"]*\)".*/\1/p' platform/android/AndroidManifest.xml)
WORK=$ROOT/build/mac-work
OUT=$ROOT/build/mac
APP="$OUT/Pinball NS.app"
MACOS_SDK=14.0

newest() { ls -d "$@" 2>/dev/null | sort -V | tail -1; }

SRCS="platform/macos/main_macos.c platform/desktop/desk.c platform/mobile/ui.c platform/mobile/design.c platform/mobile/screen.c
      src/game/pinball.c src/core/gbc.c src/core/gbc_exec.c src/core/gbc_ppu.c src/core/gbc_apu.c"
FRAMEWORKS="AppKit Foundation CoreFoundation CoreGraphics CoreVideo QuartzCore AudioToolbox GameController"
WARN="-Wall -Wextra -Wno-unused-function -Wno-unused-parameter -Wno-missing-field-initializers"

if [ -z "$CC" ] && command -v xcrun >/dev/null 2>&1 && xcrun --sdk macosx --show-sdk-path >/dev/null 2>&1; then
    MODE=xcode
    SDK=$(xcrun --sdk macosx --show-sdk-path)
    CC="xcrun --sdk macosx clang"
    LIPO="xcrun lipo"
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
            CC=$NDK_BIN/clang$EXE; LD=${LD:-$NDK_BIN/ld.lld$EXE}; NM=${NM:-$NDK_BIN/llvm-nm$EXE}; LIPO=${LIPO:-$NDK_BIN/llvm-lipo$EXE}
        else
            CC=clang; LD=${LD:-ld.lld}; NM=${NM:-llvm-nm}; LIPO=${LIPO:-llvm-lipo}
        fi
    fi
fi
echo "mode:    $MODE"
echo "clang:   $CC"

rm -rf "$WORK" "$OUT"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
for ARCH in arm64 x86_64; do
    if [ $ARCH = arm64 ]; then MIN=11.0; ASM="-DPB_ASM"; else MIN=10.15; ASM=; fi
    O=$WORK/$ARCH
    mkdir -p "$O/obj"
    if [ $MODE = xcode ]; then
        CFLAGS="-arch $ARCH -mmacosx-version-min=$MIN -isysroot $SDK -O2 -std=c11 $WARN -DNDEBUG $ASM"
    else
        CFLAGS="--target=$ARCH-apple-macos$MIN -nostdlibinc -isystem platform/apple/sdk/libc -isystem platform/apple/sdk/include \
 -O2 -std=c11 $WARN -fno-stack-protector -DNDEBUG $ASM"
    fi
    for f in $SRCS; do $CC $CFLAGS -c "$f" -o "$O/obj/$(basename "$f" .c).o"; done
    [ $ARCH = arm64 ] && $CC $CFLAGS -c src/core/cpu_a64.S -o "$O/obj/cpu_a64.o"   # the interpreter in assembly
    FW=
    for fw in $FRAMEWORKS; do FW="$FW -framework $fw"; done
    if [ $MODE = xcode ]; then
        $CC -arch $ARCH -mmacosx-version-min=$MIN -isysroot "$SDK" -dead_strip -o "$O/PinballNS" "$O"/obj/*.o $FW -lobjc
    else
        # the system libraries: a .tbd per library, with the symbols the code takes from it ("file.o:" lines skipped)
        S=$O/stubs
        mkdir -p "$S/usr/lib"
        "$NM" -u "$O"/obj/*.o | awk '!/:$/ && NF>=1 {print $NF}' | sort -u > "$S/undef.txt"
        "$NM" --defined-only "$O"/obj/*.o | awk '!/:$/ && NF==3 {print $3}' | sort -u > "$S/def.txt"
        comm -23 "$S/undef.txt" "$S/def.txt" > "$S/ext.txt"
        echo dyld_stub_binder >> "$S/ext.txt"
        for lib in System objc $FRAMEWORKS; do : > "$S/$lib.syms"; done
        while read -r s; do
            case "$s" in
                _objc_*|_class_*|_sel_*|_object_*|_protocol_*|_method_*) lib=objc ;;
                _Audio*) lib=AudioToolbox ;;
                _NSPasteboard*) lib=AppKit ;;
                _NS*) lib=Foundation ;;
                _kCA*|_CA*) lib=QuartzCore ;;
                _CG*) lib=CoreGraphics ;;
                _CV*) lib=CoreVideo ;;
                _CF*|_kCF*) lib=CoreFoundation ;;
                _GC*) lib=GameController ;;
                _[A-Z]*) echo "error: which library has $s? (platform/macos/build_mac.sh)" >&2; exit 1 ;;
                *) lib=System ;;
            esac
            echo "$s" >> "$S/$lib.syms"
        done < "$S/ext.txt"
        tbd() {   # tbd INSTALL_NAME SYMBOLS_FILE OUT
            {
                echo "--- !tapi-tbd"
                echo "tbd-version:     4"
                echo "targets:         [ $ARCH-macos ]"
                echo "install-name:    '$1'"
                if [ -s "$2" ]; then
                    echo "exports:"
                    echo "  - targets:         [ $ARCH-macos ]"
                    echo "    symbols:         [ $(paste -sd, "$2" | sed 's/,/, /g') ]"
                fi
                echo "..."
            } > "$3"
        }
        tbd /usr/lib/libSystem.B.dylib "$S/System.syms" "$S/usr/lib/libSystem.tbd"
        tbd /usr/lib/libobjc.A.dylib "$S/objc.syms" "$S/usr/lib/libobjc.tbd"
        for fw in $FRAMEWORKS; do
            case $fw in AppKit|Foundation) V=C ;; *) V=A ;; esac
            mkdir -p "$S/System/Library/Frameworks/$fw.framework"
            tbd "/System/Library/Frameworks/$fw.framework/Versions/$V/$fw" "$S/$fw.syms" "$S/System/Library/Frameworks/$fw.framework/$fw.tbd"
        done
        "$LD" -flavor darwin -arch $ARCH -platform_version macos $MIN $MACOS_SDK -syslibroot "$S" \
            -dead_strip -adhoc_codesign -o "$O/PinballNS" "$O"/obj/*.o -lSystem -lobjc $FW
        echo "$ARCH: system symbols used: $(wc -l < "$S/ext.txt")"
    fi
done
$LIPO -create "$WORK/arm64/PinballNS" "$WORK/x86_64/PinballNS" -output "$APP/Contents/MacOS/PinballNS"

# Info.plist, the icon (the right flipper key of the Blue table, as on the other versions)
sed -e "s/@VERSION@/$VERSION/" -e "s/@BUILD@/$BUILD/" platform/macos/Info.plist > "$APP/Contents/Info.plist"
printf 'APPL????' > "$APP/Contents/PkgInfo"
NDICON=${NDICON:-$ROOT/build/ndicon$EXE}
"$NDICON" -icns "$APP/Contents/Resources/PinballNS.icns"
cp platform/macos/README.md "$OUT/README.md"
if [ $MODE = xcode ]; then codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || true; fi

Z="$ROOT/build/PinballNS-macOS-$VERSION.zip"
rm -f "$Z"
if [ -z "$ZIP_TOOL" ] && command -v zip >/dev/null 2>&1; then
    (cd "$OUT" && zip -qry -X "$Z" "Pinball NS.app" README.md)
else
    "${ZIP_TOOL:-$ROOT/build/mkzip$EXE}" "$Z" "$OUT" PinballNS
fi
echo "built $Z"
