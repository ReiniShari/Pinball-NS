#!/bin/sh
# build_ndk.sh [ABI...] - the test tools (pbrun, pbdebug, testrom, cpucheck) built for Android with
# the NDK, into build/ndk-ABI/, to run on a phone or on the emulator:
#     tools/emu.sh run build/ndk-arm64-v8a/cpucheck fuzz 1 300 2000
# ABI: arm64-v8a (default; with the assembly interpreter src/core/cpu_a64.S) or x86_64 (the C one).
# The ARM64 tools run on the x86_64 emulator image with the ARM translation (AVD PinballNS_arm).
#   ANDROID_NDK_HOME  the NDK (default: the newest of $HOME/Android/Sdk/ndk)
set -e
cd "$(dirname "$0")/.."
NDK=${ANDROID_NDK_HOME:-$(ls -d "$HOME"/Android/Sdk/ndk/* 2>/dev/null | sort | tail -1)}
BIN=$(ls -d "$NDK"/toolchains/llvm/prebuilt/*/bin | head -1)
CC=$BIN/clang; [ -f "$CC.exe" ] && CC=$CC.exe
[ $# -gt 0 ] || set -- arm64-v8a
CORE="src/core/gbc.c src/core/gbc_exec.c src/core/gbc_ppu.c src/core/gbc_apu.c"
for abi in "$@"; do
    case $abi in
    arm64-v8a) T=aarch64-linux-android26; ASM="src/core/cpu_a64.S"; DEF=-DPB_ASM; EXTRA=-mno-outline-atomics ;;
    x86_64) T=x86_64-linux-android26; ASM=; DEF=; EXTRA= ;;
    *) echo "unknown ABI $abi"; exit 2 ;;
    esac
    OUT=build/ndk-$abi
    mkdir -p "$OUT"
    CFLAGS="--target=$T -O2 -std=c11 -fno-stack-protector $EXTRA $DEF"
    "$CC" $CFLAGS -o "$OUT/pbrun" tools/pbrun.c src/game/pinball.c $CORE $ASM -lm
    "$CC" $CFLAGS -o "$OUT/pbdebug" tools/pbdebug.c src/game/pinball.c $CORE $ASM -lm
    "$CC" $CFLAGS -o "$OUT/testrom" tools/testrom.c $CORE $ASM -lm
    "$CC" $CFLAGS -o "$OUT/cpucheck" tools/cpucheck.c $CORE $ASM -lm
    echo "$OUT: pbrun pbdebug testrom cpucheck"
done
