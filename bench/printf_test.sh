#!/usr/bin/env bash
# Test printf.x vs GNU printf: specifiers, width, flags, precision, cycling.
# Usage: printf_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/printf.x -o build/printf.c >/dev/null 2>&1; cc -O2 -o /tmp/xprintf build/printf.c
P=/tmp/xprintf

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$P" "$@" 2>/dev/null)
    b=$(printf "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$a]"; echo "       g:[$b]"; FAIL=$((FAIL+1)); fi
}

echo "== printf vs GNU"
cmp_gnu "%d"             '%d' 42
cmp_gnu "%d negative"    '%d' -7
cmp_gnu "%x / %X"        '%x %X' 255 255
cmp_gnu "%o"             '%o' 64
cmp_gnu "%s"             '%s' hello
cmp_gnu "%c"             '%c' ABC
cmp_gnu "%% literal"     'a%%b'
cmp_gnu "width %5d"      '%5d|' 42
cmp_gnu "left %-5d"      '%-5d|' 42
cmp_gnu "zero %05d"      '%05d' 42
cmp_gnu "width %10s"     '%10s|' hi
cmp_gnu "left %-10s"     '%-10s|' hi
cmp_gnu "prec %.3s"      '%.3s|' hello
cmp_gnu "+ flag"         '%+d' 42
cmp_gnu "space flag"     '% d|' 42
cmp_gnu "width %5x"      '%5x' 255
cmp_gnu "zero %05x"      '%05x' 255
cmp_gnu "multi-arg"      '%d %s %d' 1 two 3
cmp_gnu "cycling"        '%d,' 1 2 3

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
