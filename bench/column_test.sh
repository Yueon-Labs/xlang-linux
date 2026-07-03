#!/usr/bin/env bash
# Test column.x -t vs GNU column -t.
# Usage: column_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/column.x -o build/column.c >/dev/null 2>&1; cc -O2 -o /tmp/xcolumn build/column.c
C=/tmp/xcolumn

cmp_gnu() {
    local label="$1"; shift
    local input="$1"; shift
    local a b
    a=$(printf '%s' "$input" | "$C" -t 2>/dev/null)
    b=$(printf '%s' "$input" | column -t 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

# cmp_s LABEL INPUT ARGS... — compare "$C" ARGS to GNU column ARGS (for -s).
cmp_s() {
    local label="$1"; shift
    local input="$1"; shift
    local a b
    a=$(printf '%s' "$input" | "$C" "$@" 2>/dev/null)
    b=$(printf '%s' "$input" | column "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== column -t vs GNU"
cmp_gnu "simple"        $'a bb ccc\n1 22 333\n'
cmp_gnu "uneven"        $'aaa b\nc ddd\n'
cmp_gnu "table"         $'name age city\nalice 30 nyc\nbob 25 la\n'
cmp_gnu "single col"    $'a\nb\nc\n'
cmp_gnu "ragged"        $'one two\nthree\nfour five six\n'

echo "== column -t -s SEP vs GNU"
cmp_s "csv attached -s,"   $'alice,30,engineer\nbob,25,designer\ncarol,40,manager\n' -t -s,
cmp_s "csv separate -s ,"  $'a,b,c\nxx,yy\n' -t -s ,
cmp_s "multi-char -s,:"    $'a:b,c\nd:e,f\n' -t -s,:
cmp_s "pipe -s |"          $'a|b|c\n1|2|3\n' -t -s '|'
cmp_s "empty field -s,"    $'a,,c\n1,2,3\n' -t -s,

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
