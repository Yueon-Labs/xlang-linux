#!/usr/bin/env bash
# Test join.x vs GNU join: default field-1 join, -1/-2 join fields, -t sep, -a.
# Both files are sorted on the join field (a join precondition).
# Usage: join_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/join.x -o build/join.c >/dev/null 2>&1; cc -O2 -o /tmp/xjoin build/join.c
J=/tmp/xjoin
ROOT="$(mktemp -d)"
# Whitespace-separated; sorted on field 1.
printf '1 alice\n2 bob\n3 carol\n5 eve\n' > "$ROOT/f1"
printf '1 NY\n3 LA\n4 SF\n5 Denver\n' > "$ROOT/f2"
# Colon-separated; sorted on field 2 (f2b) / field 1 (f1b).
printf 'a:1\nb:1\nc:2\n' > "$ROOT/f1b"
printf '1:x\n2:y\n' > "$ROOT/f2b"

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$J" "$@" 2>/dev/null)
    b=$(join "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== join vs GNU"
cmp_gnu "default"          "$ROOT/f1" "$ROOT/f2"
cmp_gnu "-a 1"             -a 1 "$ROOT/f1" "$ROOT/f2"
cmp_gnu "-a 2"             -a 2 "$ROOT/f1" "$ROOT/f2"
cmp_gnu "-a 1 -a 2"        -a 1 -a 2 "$ROOT/f1" "$ROOT/f2"
cmp_gnu "-t: default fld"  -t : "$ROOT/f1b" "$ROOT/f2b"
cmp_gnu "-t: -1 2 -2 1"    -t : -1 2 -2 1 "$ROOT/f1b" "$ROOT/f2b"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
