#!/bin/sh
# regress.sh ROM BLARGG_DIR OUTDIR [SUFFIX] - the regression suite of the engine.
#
# Runs build/pbrun$SUFFIX, build/pbdebug$SUFFIX and build/testrom$SUFFIX (SUFFIX: "" for the
# current build, "_ref19" for the reference engine, ...) and writes their results, timings
# removed, to OUTDIR (one file per test). Two engines behave the same when
#     diff -r OUTDIR_A OUTDIR_B
# finds nothing: the fingerprints of every frame (picture and sound) of long games on both
# tables, the counters of pbdebug (consistency checks, oracle, bonus stages, special modes), the
# Blargg test ROMs (their verdicts and final screens).
#
#   JOBS   parallel runs (default 6)
#   QUICK  1: shorter runs (10 000 frames instead of 40 000)
set -e
ROM=$1; BL=$2; OUT=$3; SUF=$4
[ -n "$ROM" ] && [ -n "$OUT" ] || { sed -n '2,14p' "$0"; exit 2; }
cd "$(dirname "$0")/.."
JOBS=${JOBS:-6}
N=40000; [ "$QUICK" = 1 ] && N=10000
mkdir -p "$OUT"
PBRUN=build/pbrun$SUF.exe; PBDEBUG=build/pbdebug$SUF.exe; TESTROM=build/testrom$SUF.exe
[ -f "$PBRUN" ] || PBRUN=build/pbrun$SUF
[ -f "$PBDEBUG" ] || PBDEBUG=build/pbdebug$SUF
[ -f "$TESTROM" ] || TESTROM=build/testrom$SUF
notime() { sed -E -e 's/ in [0-9.]+s( \([0-9]+ fps\))?//' -e 's/ \([0-9.]+ s\)//'; }

job() {   # job NAME COMMAND...
    name=$1; shift
    ( "$@" 2>&1 | notime > "$OUT/$name.txt" ) &
    while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do sleep 1; done
}

for s in 2 3 5 7 11 13 14 16; do job "pbrun_bot_$s" "$PBRUN" "$ROM" -hash "B:$N:$s"; done
job pbrun_flippers "$PBRUN" "$ROM" -hash w:600 p:start:4 w:200 p:a:4 w:200 p:a:4 w:300 "R:$N:9"
job pbdebug_oracle "$PBDEBUG" "$ROM" -frames "$N" -seed 13 -pause 1800 -oracle 30
job pbdebug_red "$PBDEBUG" "$ROM" -frames "$N" -seed 2 -pause 1500
job pbdebug_bonus "$PBDEBUG" "$ROM" -frames "$N" -seed 5 -bonus 7,9,11,13,15:3000
job pbdebug_catch "$PBDEBUG" "$ROM" -frames 20000 -seed 2 -force catch:bottom:3000 -forcerepeat -autohit 40 -bbcheck
job pbdebug_evo "$PBDEBUG" "$ROM" -frames 20000 -seed 7 -force evo:top:3000 -forcerepeat -evocheck
job pbdebug_hud "$PBDEBUG" "$ROM" -frames 20000 -seed 16 -hudcheck
job pbdebug_selftest "$PBDEBUG" "$ROM" -selftest
if [ -n "$BL" ]; then
    for t in cpu_instrs instr_timing mem_timing halt_bug cgb_sound; do
        [ -f "$BL/$t.gb" ] || continue
        job "blargg_$t" sh -c "'$TESTROM' '$BL/$t.gb' 3600 '$OUT/blargg_$t.png' && sha1sum < '$OUT/blargg_$t.png' | cut -c1-40"
    done
fi
wait
# the screens of the test ROMs are compared by their fingerprint (the pictures stay for a look)
ls "$OUT" | grep -c txt | sed 's/^/tests: /'
