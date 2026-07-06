#!/usr/bin/env bash
# Test xargs.x vs GNU xargs: stdin tokens appended as args.
# Usage: xargs_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/xargs.x -o build/xargs.c >/dev/null 2>&1; cc -O2 -o /tmp/xxargs build/xargs.c
X=/tmp/xxargs

cmp_gnu() {
    local label="$1"; shift
    local input="$1"; shift
    local a b
    a=$(printf '%s' "$input" | "$X" "$@" 2>/dev/null)
    b=$(printf '%s' "$input" | xargs "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$a]"; echo "       g:[$b]"; FAIL=$((FAIL+1)); fi
}

echo "== xargs vs GNU"
cmp_gnu "basic"        $'a\nb\nc\n'   echo
cmp_gnu "initial args" $'1\n2\n'      echo X Y
cmp_gnu "spaces"       $'a b\nc d\n'  echo
cmp_gnu "empty stdin"  ''             echo default
cmp_gnu "-n1"          $'a b c\n'     -n1 echo
cmp_gnu "-n2"          $'a b c d\n'   -n2 echo
cmp_gnu "-n1 multiline" $'a\nb\nc\n'  -n1 echo

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
