#!/bin/sh
# The checks, by group: built (only those asked for), run one after
# another from build/, each given a verdict from check/verdicts.txt (ok
# when its output holds every line listed for it, WRONG otherwise; a
# check with nothing listed passes when it ends without an error).
#
#   tools/checks.sh              core: every gameplay change
#   tools/checks.sh time         going back: when the simulation, the
#                                undo log, saving or the alarms change
#   tools/checks.sh look         pictures to look at (build/shots/):
#                                when drawing changes
#   tools/checks.sh sound        when sounds or the music change
#   tools/checks.sh landing      the flight (off since 2026-11-01)
#   tools/checks.sh all          all five
#   tools/checks.sh gear aims    those checks by name
#
# The rest of check/ measure (balance, beasts, worlds, seeing, moves,
# tick, long, level, block, making): run them on their own when that is
# what is wanted. Outputs and programs go to build/checks/; a summary
# at the end, and the exit status is 1 if any is WRONG.
set -u
cd "$(dirname "$0")/.."
ROOT=$PWD
ENT=${ENT:-$ROOT/../ent-lang/tools/ent}

CORE="modechoice pausepanel grapple hudclicks menuclicks aims goals gear perils tutor advert strategies"
TIME="undo rewind stops"
LOOK="hudshots shots fxshots splits"
SOUND="sounds tunes"
LANDING="touchdown flights"

[ $# -eq 0 ] && set -- core
names=""
for a in "$@"; do
  case "$a" in
    core) names="$names $CORE" ;;
    time) names="$names $TIME" ;;
    look) names="$names $LOOK" ;;
    sound) names="$names $SOUND" ;;
    landing) names="$names $LANDING" ;;
    all) names="$names $CORE $TIME $LOOK $SOUND $LANDING" ;;
    *) if [ -f "check/$a.ent" ]; then names="$names $a"
       else echo "no check or group '$a'" >&2; exit 2; fi ;;
  esac
done

OUT=$ROOT/build/checks
mkdir -p "$OUT/bin" build/shots build/sounds
SUMMARY=$OUT/summary.txt
: > "$SUMMARY"
wrong=0
cd build
for n in $names; do
  s=$(date +%s)
  if ! ENT_PARALLEL_MIN=64 "$ENT" build --parallel -I .. "../check/$n.ent" \
       -o "$OUT/bin/$n" > "$OUT/$n.build.txt" 2>&1; then
    line="$n: WRONG (does not build: build/checks/$n.build.txt)"
    wrong=1
  else
    b=$(( $(date +%s) - s ))
    s=$(date +%s)
    timeout 1800 "$OUT/bin/$n" > "$OUT/$n.txt" 2>&1
    status=$?
    r=$(( $(date +%s) - s ))
    missing=""
    if [ $status -ne 0 ]; then
      missing="exit $status"
    else
      want=$(sed -n "s/^$n: //p" ../check/verdicts.txt)
      if [ -n "$want" ]; then
        missing=$(printf '%s\n' "$want" | while IFS= read -r w; do
          grep -qF -- "$w" "$OUT/$n.txt" || printf '[%s] ' "$w"; done)
      fi
    fi
    if [ -z "$missing" ]; then line="$n: ok (built ${b}s, ran ${r}s)"
    else line="$n: WRONG, missing $missing(built ${b}s, ran ${r}s; build/checks/$n.txt)"; wrong=1; fi
  fi
  echo "$line" | tee -a "$SUMMARY"
done
[ $wrong -eq 0 ] && echo "all ok" | tee -a "$SUMMARY"
exit $wrong
