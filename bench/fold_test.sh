#!/usr/bin/env bash
# fold_test.sh — verify fold.x matches GNU fold byte-for-byte at various widths
# and edge cases. Guards the buffered-output rewrite (perf fix) against regressions.
# Usage: fold_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/fold.x -o build/fold.c >/dev/null 2>&1; cc -O2 -o build/xfold build/fold.c
F=build/xfold

# ck DESC INPUT XL_ARGS GNU_ARGS
ck() {
    local desc="$1" inp="$2" xa="$3" ga="$4" a b
    a=$($F $xa < "$inp" 2>/dev/null)
    b=$(fold $ga < "$inp" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $desc"; PASS=$((PASS+1))
    else echo "  FAIL $desc"; FAIL=$((FAIL+1))
         echo "    xlang: [$(echo "$a" | head -3 | tr '\n' '|')]"
         echo "    gnu:   [$(echo "$b" | head -3 | tr '\n' '|')]"; fi
}

printf 'abcdefghij\n' > build/f_in1.txt
seq 1 60 | awk '{printf "w"$1" "}' > build/f_in2.txt; printf '\n' >> build/f_in2.txt
printf 'aaa bbb ccc ddd eee\nfff ggg\n' > build/f_in3.txt
printf '' > build/f_empty.txt

echo "== widths"
ck "w=20 short line"      build/f_in1.txt "-w 20" "-w 20"
ck "w=5  short line"      build/f_in1.txt "-w 5"  "-w 5"
ck "w=1 (char-per-line)"  build/f_in1.txt "-w 1"  "-w 1"
ck "w=100 no fold"        build/f_in2.txt "-w 100" "-w 100"
ck "w=10 long line"       build/f_in2.txt "-w 10" "-w 10"
ck "w=4  mixed"           build/f_in3.txt "-w 4"  "-w 4"
ck "w=80 mixed (default-ish)" build/f_in3.txt "-w 80" "-w 80"
ck "no -w (default 80)"   build/f_in3.txt ""      ""
ck "empty input"          build/f_empty.txt "-w 10" "-w 10"

echo "== fold -s (break at blanks)"
ck "w=12 -s words"  build/f_in2.txt "-w 12 -s" "-w 12 -s"
ck "w=10 -s words"  build/f_in2.txt "-w 10 -s" "-w 10 -s"
ck "w=7 -s mixed"   build/f_in3.txt "-w 7 -s"  "-w 7 -s"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
