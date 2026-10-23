#!/bin/sh
# campaign.sh ROM OUTDIR [REF_SUFFIX] - the long test campaign of the engine and of the unified field.
#
#   1. the same games on this build and on a reference build (build/pbrun$REF_SUFFIX.exe, e.g.
#      "_ref19" for the engine of 1.9.1): the fingerprints of all their frames and sound must be the
#      same (8 bot games of 200 000 frames, both tables);
#   2. the consistency checks of pbdebug on long games: natural games (both tables, the original
#      width), bonus stages, catch and evolution modes forced on each half, the oracle (the other
#      half compared to a fresh load), the status bar, the save states (selftest);
#   3. a summary (OUTDIR/summary.txt): every counter that must be 0 is listed, "ALL OK" at the end
#      when they all are.
#
#   JOBS    parallel runs (default 5)
#   FRAMES  frames of the long games (default 200000)
#   EXTRA   more pbdebug options for all its runs (e.g. "-antilag -tiltglow")
set -e
ROM=$1; OUT=$2; REF=$3
[ -n "$ROM" ] && [ -n "$OUT" ] || { sed -n '2,16p' "$0"; exit 2; }
cd "$(dirname "$0")/.."
JOBS=${JOBS:-5}; F=${FRAMES:-200000}; F2=$((F * 3 / 5))
mkdir -p "$OUT"
EXE=; [ -f build/pbrun.exe ] && EXE=.exe
notime() { sed -E -e 's/ in [0-9.]+s( \([0-9]+ fps\))?//' -e 's/ \([0-9.]+ s\)//'; }
job() {   # job NAME COMMAND...: output (timings removed) in OUT/NAME.txt
    name=$1; shift
    ( "$@" 2>&1 | notime > "$OUT/$name.txt" ) &
    while [ "$(jobs -r | wc -l)" -ge "$JOBS" ]; do sleep 1; done
}
CHK="-hudcheck -evocheck -oracle 30 -pause 1800 ${EXTRA:-}"

# 1. fingerprints against the reference
for s in 2 3 11 16 5 7 13 14; do
    job "hash_$s" build/pbrun$EXE "$ROM" -hash "B:$F:$s"
    [ -z "$REF" ] || job "hashref_$s" build/pbrun$REF$EXE "$ROM" -hash "B:$F:$s"
done
# 2. pbdebug: natural games, original width, bonus stages, special modes, states
for s in 2 3 11 16 5 7 13 14; do job "nat_$s" build/pbdebug$EXE "$ROM" -frames "$F" -seed "$s" $CHK; done
job nar_3 build/pbdebug$EXE "$ROM" -frames "$F" -seed 3 -narrow $CHK
job nar_13 build/pbdebug$EXE "$ROM" -frames "$F" -seed 13 -narrow $CHK
for s in 2 5 11 7; do job "bonus_$s" build/pbdebug$EXE "$ROM" -frames "$F2" -seed "$s" -bonus 7,9,11,13,15:3000 $CHK; done
job catch_red_bottom build/pbdebug$EXE "$ROM" -frames "$F2" -seed 2 -force catch:bottom:3000 -forcerepeat -autohit 150 -bbcheck $CHK
job catch_red_top build/pbdebug$EXE "$ROM" -frames "$F2" -seed 3 -force catch:top:3000 -forcerepeat -autohit 150 -bbcheck $CHK
job catch_blue_bottom build/pbdebug$EXE "$ROM" -frames "$F2" -seed 5 -force catch:bottom:3000 -forcerepeat -autohit 150 -bbcheck $CHK
job catch_blue_top build/pbdebug$EXE "$ROM" -frames "$F2" -seed 7 -force catch:top:3000 -forcerepeat -autohit 150 -bbcheck -narrow $CHK
job evo_red_top build/pbdebug$EXE "$ROM" -frames "$F2" -seed 16 -force evo:top:3000 -forcerepeat $CHK
job evo_red_bottom build/pbdebug$EXE "$ROM" -frames "$F2" -seed 11 -force evo:bottom:3000 -forcerepeat $CHK
job evo_blue_top build/pbdebug$EXE "$ROM" -frames "$F2" -seed 14 -force evo:top:3000 -forcerepeat $CHK
job evo_blue_bottom build/pbdebug$EXE "$ROM" -frames "$F2" -seed 13 -force evo:bottom:3000 -forcerepeat $CHK
job selftest build/pbdebug$EXE "$ROM" -selftest
job check_11 build/pbrun$EXE "$ROM" -check "B:$F:11"
job check_5 build/pbrun$EXE "$ROM" -check "B:$F:5"
wait

# 3. summary
S="$OUT/summary.txt"
: > "$S"
bad=0
for s in 2 3 11 16 5 7 13 14; do
    h=$(grep '^hash' "$OUT/hash_$s.txt" | cut -d' ' -f2)
    if [ -n "$REF" ]; then
        r=$(grep '^hash' "$OUT/hashref_$s.txt" | cut -d' ' -f2)
        if [ -n "$h" ] && [ "$h" = "$r" ]; then echo "hash seed $s: $h (= reference)" >> "$S"
        else echo "HASH seed $s: $h, reference $r: DIFFERENT" >> "$S"; bad=1; fi
    else
        echo "hash seed $s: $h" >> "$S"
    fi
done
for f in "$OUT"/nat_*.txt "$OUT"/nar_*.txt "$OUT"/bonus_*.txt "$OUT"/catch_*.txt "$OUT"/evo_*.txt; do
    n=$(basename "$f" .txt)
    l=$(grep -m1 'frames: unified=' "$f" || echo "no summary line")
    # counters that must be 0 (resets: 1 at most, the game's own reset at the start)
    issues=$(printf '%s\n' "$l" | tr ' ' '\n' | grep -E '^(aborts|wild|stale_window)=' | grep -v '=0$' || true)
    o=$(grep -o 'oracle: [0-9]* checks ([0-9]* failed), stale_other_half=[0-9]*' "$f" || true)
    printf '%s\n' "$o" | grep -q '(0 failed), stale_other_half=0' || issues="$issues oracle:[$o]"
    grep -q 'status bar cells not matching the score and icons: 0 ' "$f" || issues="$issues $(grep 'status bar cells' "$f")"
    e=$(grep -o '[0-9]* with fewer than 3 trinkets' "$f" || true)
    [ -z "$e" ] || [ "${e%% *}" = 0 ] || issues="$issues evolution:[$e]"
    g=$(grep 'slot halo without its upper part' "$f" || true)
    [ -z "$g" ] || printf '%s\n' "$g" | grep -q ': 0 frames' || issues="$issues halo:[$g]"
    # with the anti-lag, no VBlank in a routine of a hook and no sprite list of the other half (2.5)
    if printf '%s' "$CHK" | grep -q -- -antilag; then
        m=$(grep 'sprite lists of the other half' "$f" || true)
        printf '%s\n' "$m" | grep -q 'late frame): 0; OAM DMAs in a routine called by a hook: 0' || issues="$issues sprites:[$m]"
    fi
    b=$(grep 'grey billboard frames' "$f" || true)
    [ -z "$b" ] || printf '%s
' "$b" | grep -q '3 hits: 0; Pokemon sprite with empty tiles: 0 frames' || issues="$issues billboard:[$b]"
    if [ -n "$(printf '%s' "$issues" | tr -d ' ')" ]; then echo "$n: $issues" >> "$S"; bad=1
    else echo "$n: ok ($l)" >> "$S"; fi
done
grep -q 'SELFTEST OK (0 failures)' "$OUT/selftest.txt" && echo "selftest: ok" >> "$S" || { echo "selftest: $(tail -1 "$OUT/selftest.txt")" >> "$S"; bad=1; }
for c in 11 5; do
    l=$(grep 'wild=' "$OUT/check_$c.txt" | head -1)
    printf '%s\n' "$l" | grep -q 'wild=0 resets=1' && echo "check $c: ok ($l)" >> "$S" || { echo "check $c: $l" >> "$S"; bad=1; }
done
[ $bad = 0 ] && echo "ALL OK" >> "$S" || echo "PROBLEMS (above)" >> "$S"
cat "$S"
