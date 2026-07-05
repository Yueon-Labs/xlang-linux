#!/usr/bin/env bash
# Test tr.x vs GNU tr: translate, ranges, delete, squeeze.
# Usage: tr_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/tr.x -o build/tr.c >/dev/null 2>&1; cc -O2 -o /tmp/xtr build/tr.c
T=/tmp/xtr

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf 'hello world' | "$T" "$@" 2>/dev/null)
    b=$(printf 'hello world' | tr "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$a]"; echo "       g:[$b]"; FAIL=$((FAIL+1)); fi
}

echo "== tr vs GNU"
cmp_gnu "translate"     'aeiou' 'XXXXX'
cmp_gnu "range a-z A-Z" 'a-z' 'A-Z'
cmp_gnu "range 0-9"     '0-9' '#'
cmp_gnu "delete -d"     -d 'aeiou'
cmp_gnu "delete range"  -d 'a-z'
cmp_gnu "squeeze -s"    -s ' '
cmp_gnu "squeeze range" -s 'a-z'
cmp_gnu "pad SET2 (aeiou→*)" 'aeiou' '*'
cmp_gnu "pad SET2 (elo→X)"  'elo' 'X'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
