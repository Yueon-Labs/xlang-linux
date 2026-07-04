#!/usr/bin/env bash
# Test sed.x vs GNU sed: single + multiple commands, -e, addresses, -n, literal
# ';' inside s///.
# Usage: sed_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/sed.x -o build/sed.c >/dev/null 2>&1; cc -O2 -o /tmp/xsed build/sed.c
S=/tmp/xsed
INPUT=$'banana\napple\ncherry\n'

cmp_gnu() {
    local label="$1"; shift
    local a b
    a=$(printf '%s' "$INPUT" | "$S" "$@" 2>/dev/null)
    b=$(printf '%s' "$INPUT" | sed "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]"; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

echo "== sed vs GNU"
cmp_gnu "s global"           's/a/X/g'
cmp_gnu "two commands"       's/a/X/g; s/n/N/'
cmp_gnu "two -e"             -e 's/a/X/' -e 's/n/N/g'
cmp_gnu "delete line 2"      '2d'
cmp_gnu "print only line 2"  -n '2p'
cmp_gnu "addr range sub"     '1,2s/e/3/g'
cmp_gnu "literal ; in repl"  's/a/A;B/'
cmp_gnu "s with & (matched)" 's/banana/[&]/'
cmp_gnu "s with & global"    's/a/[&]/g'

echo "== sed regex substitution (. [...] ^ * agree with GNU BRE)"
cmp_gnu "regex dot"     's/a./X/g'
cmp_gnu "regex class"   's/[an]/Z/g'
cmp_gnu "regex anchor"  's/^ba/X/'
cmp_gnu "regex star"    's/ch*/Y/g'

echo "== sed = (line numbers) and q (quit)"
cmp_gnu "= line nums"   '='
cmp_gnu "3q quit"       '3q'
cmp_gnu "2,3d + ="      '2,3d;='

echo "== sed a (append) and i (insert)"
cmp_gnu "a text"        'a APPENDED'
cmp_gnu "i text"        'i INSERTED'
cmp_gnu "2a addressed"  '2a AFTER2'

echo "== sed y (transliterate) and c (change)"
cmp_gnu "y translit"    'y/elo/ELI/'
cmp_gnu "2c change"     '2c CHANGED'

echo "== sed -i (in-place edit)"
# -i writes a temp file and renames over the original (POSIX rename overwrites;
# the Windows-native binary can't overwrite, so this is a Linux-CI test).
TF=$(mktemp)
printf 'alpha\nbeta\ngamma\n' > "$TF"
"$S" -i 's/a/X/g' "$TF"
xi=$(cat "$TF")
printf 'alpha\nbeta\ngamma\n' > "$TF"
sed -i 's/a/X/g' "$TF"
gi=$(cat "$TF")
if [ "$xi" = "$gi" ]; then echo "  ok   sed -i == GNU sed -i"; PASS=$((PASS+1)); else echo "  FAIL sed -i: x=[$xi] g=[$gi]"; FAIL=$((FAIL+1)); fi
rm -f "$TF"

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
