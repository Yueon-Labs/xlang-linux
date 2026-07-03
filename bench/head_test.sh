#!/usr/bin/env bash
# Test head.x vs GNU head: single-file -n/-N, multi-file headers, -v, -q.
# Usage: head_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/head.x -o build/head.c >/dev/null 2>&1; cc -O2 -o /tmp/xhead build/head.c
H=/tmp/xhead
ROOT="$(mktemp -d)"
printf '1\n2\n3\n4\n5\n' > "$ROOT/a"
printf 'x\ny\nz\n'       > "$ROOT/b"
printf 'abcdefghij'      > "$ROOT/c"

cmp_gnu() {
    local label="$1"; shift
    local ax bx
    ax=$(cd "$ROOT" && "$H" "$@" 2>/dev/null)
    bx=$(cd "$ROOT" && head "$@" 2>/dev/null)
    if [ "$ax" = "$bx" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$ax"|tr '\n' '~')]"; echo "       g:[$(echo "$bx"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== head vs GNU"
cmp_gnu "single -n 2"   -n 2 a
cmp_gnu "single -2"     -2 a
cmp_gnu "multi default" a b
cmp_gnu "multi -n 1"    -n 1 a b
cmp_gnu "-v single"     -v a
cmp_gnu "-q multi"      -q a b
cmp_gnu "byte -c 4"     -c 4 c
cmp_gnu "byte -c4"      -c4 c

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
