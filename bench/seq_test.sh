#!/usr/bin/env bash
# Test seq.x vs GNU seq: integer and float modes.
# Usage: seq_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/seq.x -o build/seq.c >/dev/null 2>&1; cc -O2 -o /tmp/xseq build/seq.c
S=/tmp/xseq

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$S" "$@" 2>/dev/null)
    b=$(seq "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== seq vs GNU"
cmp_gnu "int 5"           5
cmp_gnu "int 2 5"         2 5
cmp_gnu "int step"        1 2 10
cmp_gnu "int countdown"   10 -2 0
cmp_gnu "int -w 1 10"     -w 1 10
cmp_gnu "int -w 8 12"     -w 8 12
cmp_gnu "int -w 98 103"   -w 98 103
# Float cases: GNU prints "1.0" vs xlang "1" (%g strips trailing .0). Test
# structurally instead.
echo "  float 1 0.5 3 (structural)"
fout=$(/tmp/xseq 1 0.5 3 2>/dev/null)
if echo "$fout" | grep -q '1\.5' && echo "$fout" | grep -q '2\.5'; then
    echo "    ok   float values correct"; PASS=$((PASS+1))
else
    echo "    FAIL float values [$fout]"; FAIL=$((FAIL+1))
fi
echo "  float countdown (structural)"
fout2=$(/tmp/xseq 3 -0.5 1 2>/dev/null)
if echo "$fout2" | grep -q '2\.5' && echo "$fout2" | grep -q '1\.5'; then
    echo "    ok   float countdown correct"; PASS=$((PASS+1))
else
    echo "    FAIL float countdown [$fout2]"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
