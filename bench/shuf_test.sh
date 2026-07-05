#!/usr/bin/env bash
# Test shuf.x structurally (output is random, so check counts + element sets).
# Usage: shuf_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/shuf.x -o build/shuf.c >/dev/null 2>&1; cc -O2 -o /tmp/xshuf build/shuf.c
S=/tmp/xshuf

# set_eq "label" "xlang-output" "expected-space-joined"
set_eq() {
    local label="$1" got="$2" want="$3"
    local g w
    g=$(printf '%s\n' $got | sort | tr '\n' ' ')
    w=$(printf '%s\n' $want | sort | tr '\n' ' ')
    if [ "$g" = "$w" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label: got[$g] want[$w]"; FAIL=$((FAIL+1)); fi
}
count_eq() {
    local label="$1" got="$2" want="$3"
    if [ "$got" = "$want" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label: got $got want $want"; FAIL=$((FAIL+1)); fi
}

echo "== shuf -i (input range)"
out=$(/tmp/xshuf -i 1-5 2>/dev/null)
set_eq "-i 1-5 elements" "$out" "1 2 3 4 5"
count_eq "-i 1-5 count" "$(printf '%s\n' "$out" | grep -c .)" 5
count_eq "-i 1-10 -n3 count" "$(/tmp/xshuf -i 1-10 -n3 2>/dev/null | grep -c .)" 3

echo "== shuf -e (args)"
out=$(/tmp/xshuf -e a b c d 2>/dev/null)
set_eq "-e elements" "$out" "a b c d"
count_eq "-e count" "$(printf '%s\n' "$out" | grep -c .)" 4

echo "== shuf stdin"
out=$(printf 'x\ny\nz\n' | /tmp/xshuf 2>/dev/null)
set_eq "stdin elements" "$out" "x y z"

echo "== shuf -r (with replacement)"
count_eq "-i 1-2 -r -n4 count" "$(/tmp/xshuf -i 1-2 -r -n4 2>/dev/null | grep -c .)" 4

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
