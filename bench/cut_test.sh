#!/usr/bin/env bash
# Test cut.x vs GNU cut: -f fields, -f ranges, -c, -d.
# Usage: cut_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/cut.x -o build/cut.c >/dev/null 2>&1; cc -O2 -o /tmp/xcut build/cut.c
C=/tmp/xcut
INPUT=$'a:b:c:d:e\n1:2:3:4:5\n'

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$C" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | cut "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== cut vs GNU"
cmp_gnu "-f1"         -d: -f1
cmp_gnu "-f2,4"       -d: -f2,4
cmp_gnu "-f1-3"       -d: -f1-3
cmp_gnu "-f2-4"       -d: -f2-4
cmp_gnu "-f1,3-5"     -d: -f1,3-5
cmp_gnu "-f3- (open)" -d: -f3-
cmp_gnu "-f-2 (open)" -d: -f-2
cmp_gnu "-f1,1 (dedup)" -d: -f1,1
cmp_gnu "-f3,1 (order)" -d: -f3,1
cmp_gnu "-f1 --complement" -d: -f1 --complement
cmp_gnu "-f2-4 --complement" -d: -f2-4 --complement
cmp_gnu "-c1-3"       -c1-3
cmp_gnu "-c2-"        -c2-
cmp_gnu "-c2,5,7"     -c2,5,7
cmp_gnu "-c1-3 --complement" -c1-3 --complement
cmp_gnu "-b1-4"       -b1-4

echo "== cut -s (only-delimited lines) vs GNU"
ND=$'plain line\nx:y\n'
cks() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$ND" | "$C" "$@" 2>/dev/null)
    b=$(printf '%s' "$ND" | cut "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}
cks "-f1 (no-delim passes)" -d: -f1
cks "-f1 -s (no-delim skipped)" -d: -f1 -s

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
