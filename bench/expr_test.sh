#!/usr/bin/env bash
# Test expr.x vs GNU expr: arithmetic, modulo, comparisons, chained.
# Usage: expr_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/expr.x -o build/expr.c >/dev/null 2>&1; cc -O2 -o /tmp/xexpr build/expr.c
E=/tmp/xexpr

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$E" "$@" 2>/dev/null)
    b=$(expr "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$a]"; echo "       g:[$b]"; FAIL=$((FAIL+1)); fi
}

echo "== expr vs GNU"
cmp_gnu "6 + 4"      6 + 4
cmp_gnu "10 - 3"     10 - 3
cmp_gnu "7 \* 8"     7 \* 8
cmp_gnu "20 / 6"     20 / 6
cmp_gnu "20 % 6"     20 % 6
cmp_gnu "3 < 5"      3 \< 5
cmp_gnu "5 = 5"      5 = 5
cmp_gnu "5 != 6"     5 "!=" 6
cmp_gnu "10 >= 10"   10 ">=" 10
cmp_gnu "1 + 2 + 3"  1 + 2 + 3

echo "== precedence + parens"
cmp_gnu "5 + 2 * 3"  5 + 2 \* 3
cmp_gnu "(5+2)*3"    \( 5 + 2 \) \* 3
cmp_gnu "2*3+5"      2 \* 3 + 5

echo "== string comparison + regex + functions"
cmp_gnu "abc < def"   abc \< def
cmp_gnu "abc = abc"   abc = abc
cmp_gnu "regex :"     abc : "a.c"
cmp_gnu "regex len"   abcdef : "a.*"
cmp_gnu "length"      length abcde
cmp_gnu "substr"      substr abcdef 2 3
cmp_gnu "index"       index abcdef cd
cmp_gnu "and"         3 \& 7
cmp_gnu "or"          0 \| 5

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
