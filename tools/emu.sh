#!/bin/sh
# emu.sh - the Android version on the Android emulator of the PC: to see what Android really
# draws (its OpenGL ES, on the graphics card), without a phone.
#
#   tools/emu.sh start            runs the virtual phone "PinballNS" (1080 x 2400, 420 dpi; EMU_AVD=PinballNS_arm:
#                                 the Google APIs image, which runs ARM64 code by translation), without
#                                 a window (it returns when the phone stops: run it in the background)
#   tools/emu.sh ready            waits until it has started; a camera hole as the user's phone
#   tools/emu.sh apk              builds build/PinballNS-test.apk (arm64 + x86_64, -DPNS_TEST; TEST_ABIS=arm64-v8a:
#                                 arm64 only, run by translation on PinballNS_arm) and
#                                 installs it
#   tools/emu.sh rom FILE         gives the ROM to the app (its folder Android/data/.../files)
#   tools/emu.sh put FILE NAME    puts a file into the app's own folder as NAME (pinball.sav: the
#                                 cartridge save, settings.txt...); tools/emu.sh del NAME removes one
#   tools/emu.sh launch | kill    starts / stops the app (kill: also forgets nothing: saves stay)
#   tools/emu.sh reset            removes the app's data (ROM, saves, settings)
#   tools/emu.sh key NAME         a key held half a second: a, b, start, select, up, down, left, right, back
#   tools/emu.sh touch X Y [MS]   holds a finger at X, Y (screen pixels)
#   tools/emu.sh cmd "bonus 11"   a test command (app_test_command, test builds only)
#   tools/emu.sh status           what the game shows: screen, stage, playing, frame (test builds)
#   tools/emu.sh shot FILE.png    what the screen shows (screencap)
#   tools/emu.sh wait S           waits S seconds (decimals allowed)
#   tools/emu.sh run PROG ARGS    runs a program built for Android (tests) in /data/local/tmp
#   tools/emu.sh send FILE [NAME] | get NAME FILE   files to / from /data/local/tmp
#   tools/emu.sh stop             stops the virtual phone
#
# Needs the SDK packages platform-tools, emulator and system-images;android-34;default;x86_64
# in $ANDROID_HOME (default ~/Android/Sdk), and the virtual device ~/.android/avd/PinballNS.
set -e
ROOT=$(cd "$(dirname "$0")/.." && pwd)
# Git Bash: the Windows programs (adb, apksigner) want C:/... paths
win() { if command -v cygpath >/dev/null 2>&1; then cygpath -m "$1"; else printf '%s\n' "$1"; fi; }
ROOT=$(win "$ROOT")
SDK=${ANDROID_HOME:-$HOME/Android/Sdk}
ADB="$SDK/platform-tools/adb"
EMU="$SDK/emulator/emulator"
PKG=fr.pinballtc.app
FILES=/sdcard/Android/data/$PKG/files
export MSYS_NO_PATHCONV=1                  # Git Bash: keep /sdcard/... as it is
# the adb server keeps the folder it was started in: start it outside the project
adb() { (cd "$SDK" && "$ADB" "$@"); }

keycode() {
    case "$1" in
        a) echo KEYCODE_BUTTON_A ;; b) echo KEYCODE_BUTTON_B ;; start) echo KEYCODE_BUTTON_START ;;
        select) echo KEYCODE_BUTTON_SELECT ;; up) echo KEYCODE_DPAD_UP ;; down) echo KEYCODE_DPAD_DOWN ;;
        left) echo KEYCODE_DPAD_LEFT ;; right) echo KEYCODE_DPAD_RIGHT ;; back) echo KEYCODE_BACK ;;
        *) echo "unknown key $1" >&2; exit 2 ;;
    esac
}

case "$1" in
start)
    # in the foreground: run it in the background of the caller (it ends with "stop")
    (cd "$SDK" && ANDROID_SDK_ROOT=$SDK ANDROID_AVD_HOME=$HOME/.android/avd \
        "$EMU" -avd "${EMU_AVD:-PinballNS}" -no-window -no-audio -no-boot-anim -no-snapshot -gpu host -no-metrics)
    ;;
ready)
    adb wait-for-device
    until [ "$(adb shell getprop sys.boot_completed | tr -d '\r')" = 1 ]; do sleep 2; done
    adb shell cmd overlay enable com.android.internal.display.cutout.emulation.hole
    for k in window_animation_scale transition_animation_scale animator_duration_scale; do adb shell settings put global $k 0; done
    adb shell settings put secure immersive_mode_confirmations confirmed   # no "Viewing full screen" bubble
    echo "ready"
    ;;
apk)
    ABIS="${TEST_ABIS:-arm64-v8a x86_64}" EXTRA_CFLAGS=-DPNS_TEST APK_DEBUGGABLE=1 OUT_APK="$ROOT/build/PinballNS-test.apk" \
        sh "$ROOT/platform/android/build_apk.sh" > "$ROOT/build/apk_test.log" 2>&1 || { tail -20 "$ROOT/build/apk_test.log"; exit 1; }
    adb install -r "$ROOT/build/PinballNS-test.apk"
    ;;
rom)
    adb shell mkdir -p "$FILES"
    adb push "$(win "$2")" "$FILES/rom.gbc" > /dev/null
    ;;
put)
    adb push "$(win "$2")" /data/local/tmp/pns_put > /dev/null
    adb shell run-as $PKG sh -c "'mkdir -p files && cp /data/local/tmp/pns_put files/$3'"
    ;;
del) adb shell run-as $PKG rm -f "files/$2" ;;
launch) adb shell monkey -p $PKG -c android.intent.category.LAUNCHER 1 > /dev/null 2>&1 ;;
kill) adb shell am force-stop $PKG ;;
reset) adb shell pm clear $PKG > /dev/null; adb shell rm -rf "$FILES" ;;
key) adb shell input keyevent --longpress "$(keycode "$2")" ;;
touch)
    adb shell "input motionevent DOWN $2 $3; sleep $(awk "BEGIN{print ${4:-120}/1000}"); input motionevent UP $2 $3"
    ;;
cmd)
    printf '%s\n' "$2" > "$ROOT/build/emu_test.txt"
    adb push "$ROOT/build/emu_test.txt" "$FILES/test.txt" > /dev/null
    ;;
status) adb shell cat "$FILES/test_status.txt" 2>/dev/null | tr -d '\r' ;;
shot) adb exec-out screencap -p > "$(win "$2")" ;;
wait) sleep "$2" ;;
run)        # run PROGRAM ARGS...: a program built for Android, in /data/local/tmp (its folder)
    prog=$2; shift 2
    adb push "$(win "$prog")" "/data/local/tmp/$(basename "$prog")" > /dev/null
    adb shell "cd /data/local/tmp && chmod 755 '$(basename "$prog")' && ./'$(basename "$prog")' $*"
    ;;
send) adb push "$(win "$2")" "/data/local/tmp/${3:-$(basename "$2")}" > /dev/null ;;
get) adb pull "/data/local/tmp/$2" "$(win "$3")" > /dev/null ;;
stop) adb emu kill ;;
*) sed -n '2,22p' "$0"; exit 2 ;;
esac
