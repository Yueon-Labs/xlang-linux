#!/usr/bin/env bash
# Test paste.x vs GNU paste: parallel merge, -d delim, -s serial.
# Usage: paste_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/paste.x -o build/paste.c >/dev/null 2>&1; cc -O2 -o /tmp/xpaste build/paste.c
P=/tmp/xpaste
ROOT="$(mktemp -d)"
printf 'a\nb\nc\n' > "$ROOT/f1"
printf '1\n2\n3\n' > "$ROOT/f2"
printf 'x\ny\n' > "$ROOT/f3"

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$("$P" "$@" "$ROOT/f1" "$ROOT/f2" 2>/dev/null)
    b=$(paste "$@" "$ROOT/f1" "$ROOT/f2" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== paste vs GNU (f1+f2)"
cmp_gnu "parallel"
cmp_gnu "-d ,"       -d ,
cmp_gnu "-s"         -s
cmp_gnu "-s -d :"    -s -d :
# Multi-char -d exercises the char-cycling fallback (dn>1), not the
# str_join fast path — guards against regressing the rare path.
cmp_gnu "-d xy"      -d xy
cmp_gnu "-s -d xy"   -s -d xy

echo "== 3 files"
a3=$("$P" "$ROOT/f1" "$ROOT/f2" "$ROOT/f3" 2>/dev/null)
b3=$(paste "$ROOT/f1" "$ROOT/f2" "$ROOT/f3" 2>/dev/null)
if [ "$a3" = "$b3" ]; then echo "  ok   3 files parallel"; PASS=$((PASS+1)); else echo "  FAIL 3 files"; FAIL=$((FAIL+1)); fi

# stdin: GNU paste reads stdin when no file given, and "-" means stdin.
cmp_stdin() {
    local label="$1"; shift
    local a b
    a=$("$P" "$@" < "$ROOT/f1" 2>/dev/null)
    b=$(paste "$@" < "$ROOT/f1" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; FAIL=$((FAIL+1)); fi
}
echo "== stdin (no file ⇒ stdin)"
cmp_stdin "stdin default"
cmp_stdin "stdin -s"
cmp_stdin "stdin -s -d,"
cmp_stdin 'stdin "-"'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
