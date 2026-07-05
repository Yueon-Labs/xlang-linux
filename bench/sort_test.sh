#!/usr/bin/env bash
# Test sort.x vs GNU sort: default, -n, -r, -u, -k, -t.
# Usage: sort_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/sort.x -o build/sort.c >/dev/null 2>&1; cc -O2 -o /tmp/xsort build/sort.c
S=/tmp/xsort
INPUT=$'3\n1\n2\n3\n1\n10\n2\n'

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$S" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | sort "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== sort vs GNU"
cmp_gnu "default"
cmp_gnu "-n"       -n
cmp_gnu "-r"       -r
cmp_gnu "-u"       -u
cmp_gnu "-nr"      -nr
cmp_gnu "-nu"      -nu
cmp_gnu "-nru"     -nru

echo "== sort -k (key-field) vs GNU"
KEYINPUT=$'b 3\na 1\nc 2\nb 1\na 3\n'

ck() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$KEYINPUT" | "$S" "$@" 2>/dev/null)
    b=$(printf '%s' "$KEYINPUT" | sort "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

ck "-k2"           -k2
ck "-k2,2"         -k2,2
ck "-k2,2 -n"      -k2,2 -n
ck "-k2 -r"        -k2 -r
ck "-k1,1 -k2,2"   -k1,1 -k2,2
ck "-k 2 (sep)"    -k 2

echo "== sort -t (delimiter) vs GNU"
CSVINPUT=$'x,3\ny,1\nz,2\nx,1\n'

ckt() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$CSVINPUT" | "$S" "$@" 2>/dev/null)
    b=$(printf '%s' "$CSVINPUT" | sort "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

ckt "-t, -k2"      -t, -k2
ckt "-t, -k2,2 -n" -t, -k2,2 -n
ckt "-t, -k1,1"    -t, -k1,1

echo "== sort -f (fold / ignore case) vs GNU"
FOLDINPUT=$'banana\napple\nCherry\napple\nBanana\n'
cf() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$FOLDINPUT" | "$S" "$@" 2>/dev/null)
    b=$(printf '%s' "$FOLDINPUT" | sort "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}
cf "-f"            -f
cf "-fu"           -fu
cf "-fur"          -fur

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
