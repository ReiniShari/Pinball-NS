#!/bin/sh
# compat.sh - the Android version on virtual phones of several kinds, one after the other: Android 8, 11,
# 14 and 16, small and large screens, a tablet, a 21:9 screen, camera cut-outs, gesture or button
# navigation. For each: a virtual device made for the test, the test APK (tools/emu.sh apk) installed,
# the US ROM given, then: the title, a game (A pressed), the controls touched (a flipper key, the TILT
# pad, a tap on the game), the menu and its page ABOUT (keys), the app stopped and started again (the
# suspended game), Pokemon Pinball Generations installed (it is then played), the original chosen again
# in the menu; a screenshot at each
# step, the app's state (test_status.txt) and the system's log looked at for crashes. The device is
# deleted after its test (its disk).
#
#   tools/compat.sh US_ROM GEN_ROM OUTDIR [PROFILE...]    (default: every profile)
#
# OUTDIR/PROFILE_*.png, OUTDIR/PROFILE.log (status, crashes), OUTDIR/summary.txt.
# Needs the system images android-26, -30, -34, -36 (default, x86_64) in the SDK, and the test APK
# (build/PinballNS-test.apk: tools/emu.sh apk builds it, with the x86_64 library).
set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
win() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
SDK=${ANDROID_HOME:-$HOME/Android/Sdk}
ADB="$SDK/platform-tools/adb"
EMU="$SDK/emulator/emulator"
AVDS=$HOME/.android/avd
PKG=fr.pinballtc.app
FILES=/sdcard/Android/data/$PKG/files
export MSYS_NO_PATHCONV=1
PORT=5580                                  # the virtual phone of the test (another one may be listed, offline)
SERIAL=emulator-$PORT
adb() { (cd "$SDK" && "$ADB" -s $SERIAL "$@"); }
# no virtual phone left running (one that did not start would answer the next test's commands)
emulators_off() { taskkill //F //IM qemu-system-x86_64-headless.exe > /dev/null 2>&1; taskkill //F //IM emulator.exe > /dev/null 2>&1; sleep 3; }

US=$1; GEN=$2; OUT=$3; shift 3
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)

# name  api  width  height  dpi  cut-out (none, hole, tall, corner)  navigation (gestures, buttons)
PROFILES="
a8_small     26  720  1280 320  none   buttons
a11_notch    30  1080 2340 400  tall   gestures
a14_poco_f4  34  1080 2400 395  hole   gestures
a16_nothing  36  1080 2412 394  hole   gestures
a14_tablet   34  1600 2560 320  none   buttons
a14_21x9     34  1080 2520 420  corner buttons
a14_tiny     34  480  854  240  none   buttons
"

make_avd() {   # name api w h dpi
    dir="$AVDS/pns_$1.avd"
    mkdir -p "$dir"
    cat > "$AVDS/pns_$1.ini" <<EOF
avd.ini.encoding=UTF-8
path=$(cygpath -w "$dir" 2>/dev/null || echo "$dir")
path.rel=avd/pns_$1.avd
target=android-$2
EOF
    cat > "$dir/config.ini" <<EOF
AvdId = pns_$1
avd.ini.displayname = pns $1
avd.ini.encoding = UTF-8
PlayStore.enabled = false
abi.type = x86_64
hw.cpu.arch = x86_64
hw.cpu.ncore = 4
hw.ramSize = 2048
disk.dataPartition.size = 2147483648
hw.lcd.width = $3
hw.lcd.height = $4
hw.lcd.density = $5
hw.gpu.enabled = yes
hw.gpu.mode = auto
hw.keyboard = yes
hw.mainKeys = no
hw.audioInput = no
hw.audioOutput = no
hw.accelerometer = yes
hw.gps = no
hw.sdCard = no
hw.camera.back = none
hw.camera.front = none
hw.sensors.orientation = no
hw.sensors.proximity = no
showDeviceFrame = no
fastboot.forceColdBoot = yes
image.sysdir.1 = system-images\\android-$2\\default\\x86_64\\
tag.display = Default Android System Image
tag.id = default
EOF
}

shot() { adb exec-out screencap -p > "$(win "$OUT/$1.png")"; }
# (Android 11: adb cannot read the app's own external folder; the app itself can: run-as, a debuggable APK)
status() {
    st=$(adb shell cat "$FILES/test_status.txt" 2>/dev/null | tr -d '\r' | head -1)
    [ -z "$st" ] && st=$(adb shell run-as $PKG cat "$FILES/test_status.txt" 2>/dev/null | tr -d '\r' | head -1)
    echo "$st"
}
# a file into the app's private storage (where it keeps its ROMs and settings)
put_private() {
    adb push "$(win "$1")" /data/local/tmp/pns_put > /dev/null
    adb shell run-as $PKG sh -c "'mkdir -p files && cp /data/local/tmp/pns_put files/$2'"
}
key() { if [ "$1" = KEYCODE_BACK ] || [ "$1" = KEYCODE_HOME ]; then adb shell input keyevent "$1"; else adb shell input keyevent --longpress "$1"; fi; sleep "${2:-0.3}"; }
tap() { adb shell input tap "$1" "$2"; sleep "${3:-0.3}"; }
alive() { adb shell pidof $PKG | tr -d '\r'; }

run_profile() {   # name api w h dpi cut nav
    name=$1; api=$2; w=$3; h=$4; dpi=$5; cut=$6; nav=$7
    log="$OUT/$name.log"
    : > "$log"
    if [ ! -d "$SDK/system-images/android-$api/default/x86_64" ]; then echo "$name: no system image android-$api" | tee -a "$log"; return; fi
    make_avd "$name" "$api" "$w" "$h" "$dpi"
    (cd "$SDK" && ANDROID_SDK_ROOT=$SDK ANDROID_AVD_HOME=$AVDS "$EMU" -avd "pns_$name" -port $PORT -no-window -no-audio \
        -no-boot-anim -no-snapshot -wipe-data -gpu host -no-metrics > "$OUT/$name.emulator.txt" 2>&1) &
    epid=$!
    t=0
    until adb devices | grep -q "^$SERIAL.device" || [ $t -gt 420 ]; do sleep 3; t=$((t + 3)); done
    if [ $t -gt 420 ]; then
        echo "$name: the emulator did not start (see $name.emulator.txt)" | tee -a "$log"
        emulators_off
        rm -rf "$AVDS/pns_$name.avd"; rm -f "$AVDS/pns_$name.ini"
        return
    fi
    t=0
    until [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ] || [ $t -gt 600 ]; do sleep 3; t=$((t + 3)); done
    echo "$name: booted after ${t}s, $(adb shell getprop ro.build.version.release | tr -d '\r') (API $api), ${w}x${h} ${dpi} dpi, cut-out $cut, $nav" | tee -a "$log"
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do adb shell settings put global $k 0; done
    adb shell settings put secure immersive_mode_confirmations confirmed
    [ "$cut" != none ] && adb shell cmd overlay enable com.android.internal.display.cutout.emulation.$cut 2>/dev/null
    [ "$nav" = gestures ] && adb shell cmd overlay enable com.android.internal.systemui.navbar.gestural 2>/dev/null
    [ "$nav" = buttons ] && adb shell cmd overlay enable com.android.internal.systemui.navbar.threebutton 2>/dev/null
    sleep 3
    adb install -r "$(win "$ROOT/build/PinballNS-test.apk")" >> "$log" 2>&1
    adb logcat -c
    # the app's own folder made by the app first (Android 11: one made by adb stays closed to it), then the ROM
    adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 5
    adb shell am force-stop $PKG
    put_private "$US" rom.gbc

    # the original: the title, a game, the controls
    adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 10
    shot "${name}_1_title"
    echo "title: $(status)" >> "$log"
    for i in 1 2 3 4 5 6 7 8 9 10; do key KEYCODE_BUTTON_A 1.5; done
    sleep 4
    shot "${name}_2_game"
    echo "game: $(status)" >> "$log"
    # a flipper key (bottom left quarter), the TILT pad (middle, near the bottom), a tap on the game (top)
    tap $((w / 8)) $((h - h / 12)) 0.5
    tap $((w / 2)) $((h - h / 7)) 0.5
    tap $((w / 2)) $((h / 5)) 0.5
    shot "${name}_3_touched"
    # the menu (back: RESUME chosen, row 0), its page ABOUT (row 12, A), back to the game
    key KEYCODE_BACK 1
    shot "${name}_4_menu"
    for i in 1 2 3 4 5 6 7 8 9 10 11 12; do key KEYCODE_DPAD_DOWN 0.15; done
    key KEYCODE_BUTTON_A 1
    shot "${name}_5_about"
    key KEYCODE_BACK 0.5
    key KEYCODE_BACK 1
    echo "after the menu: $(status)" >> "$log"
    # stopped and started again: the game suspended comes back
    adb shell input keyevent KEYCODE_HOME
    sleep 2
    adb shell am force-stop $PKG
    adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 8
    shot "${name}_6_resumed"
    echo "resumed: $(status)" >> "$log"

    # Generations: installed next to the US ROM and chosen as the game played (settings), a game; then the
    # original again with the menu (GAME: row 10)
    adb shell am force-stop $PKG
    put_private "$GEN" gen_rom.gbc
    printf 'game=1\n' > "$OUT/settings_gen.txt"
    put_private "$OUT/settings_gen.txt" settings.txt
    adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1
    sleep 10
    shot "${name}_7_generations"
    for i in 1 2 3 4 5 6 7 8 9 10; do key KEYCODE_BUTTON_A 1.5; done
    sleep 4
    shot "${name}_8_gen_game"
    echo "generations: $(status)" >> "$log"
    key KEYCODE_BACK 1
    for i in 1 2 3 4 5 6 7 8 9 10; do key KEYCODE_DPAD_DOWN 0.15; done
    key KEYCODE_BUTTON_A 6
    shot "${name}_9_original_again"
    echo "the original again: $(status)" >> "$log"

    # what the system said
    pid=$(alive)
    adb logcat -d > "$OUT/$name.logcat.txt" 2>/dev/null
    crashes=$(grep -cE "FATAL EXCEPTION|Fatal signal|ANR in $PKG|Abort message|Process: $PKG" "$OUT/$name.logcat.txt")
    vib=$(grep -m1 -o "Vibrator [^;]*; gamepad [a-z ]*" "$OUT/$name.logcat.txt")
    echo "app running at the end: ${pid:-NO}, crash or ANR lines in the log: $crashes" | tee -a "$log"
    grep -E "pns|PinballNS" "$OUT/$name.logcat.txt" | grep -iE "error|fail|cannot|could not" | head -5 >> "$log"
    adb emu kill > /dev/null 2>&1
    wait $epid 2>/dev/null
    emulators_off
    rm -rf "$AVDS/pns_$name.avd"
    rm -f "$AVDS/pns_$name.ini"
}

emulators_off
: > "$OUT/summary.txt"
echo "$PROFILES" | while read -r name api w h dpi cut nav; do
    [ -z "$name" ] && continue
    if [ $# -gt 0 ]; then
        want=0
        for p in "$@"; do [ "$p" = "$name" ] && want=1; done
        [ $want = 0 ] && continue
    fi
    run_profile "$name" "$api" "$w" "$h" "$dpi" "$cut" "$nav" < /dev/null     # (adb shell would read the list)
    cat "$OUT/$name.log" >> "$OUT/summary.txt"
    echo >> "$OUT/summary.txt"
done
echo "done"
