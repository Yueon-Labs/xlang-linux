#!/usr/bin/env bash
# Test awk.x vs GNU awk: NR patterns, /regex/ patterns (POSIX ERE), print
# fields ($N/NR/NF/literals), and -F separator. Cross-checked vs GNU awk.
# Usage: awk_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/awk.x -o build/awk.c >/dev/null 2>&1; cc -O2 -o /tmp/xawk build/awk.c
A=/tmp/xawk

# cmp_gnu <label> <input> <awk program args...>
cmp_gnu() {
    local label="$1" input="$2"; shift 2
    local a b
    a=$(printf '%s' "$input" | "$A" "$@" 2>/dev/null)
    b=$(printf '%s' "$input" | awk "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else
        echo "  FAIL $label"; echo "       x:[$(echo "$a"|tr '\n' '~')]" ; echo "       g:[$(echo "$b"|tr '\n' '~')]"; FAIL=$((FAIL+1)); fi
}

WORDS=$'apple\nbanana\ncherry\n'
CSV=$'a,b,c\n1,2,3\nx,y,z\n'

echo "== awk NR patterns"
cmp_gnu "NR==2"   "$WORDS" 'NR==2'
cmp_gnu "NR>1"    "$WORDS" 'NR>1'
cmp_gnu "NR<=2"   "$WORDS" 'NR<=2'
cmp_gnu "NR!=1"   "$WORDS" 'NR!=1'

echo "== awk /regex/ patterns (POSIX ERE)"
cmp_gnu "/apple/"        "$WORDS" '/apple/'
cmp_gnu "/^a/ anchor"    "$WORDS" '/^a/'
cmp_gnu "/an/"           "$WORDS" '/an/'
cmp_gnu "/e+/ quantifier" "$WORDS" '/e+/'
cmp_gnu "/^c/ no-action" "$WORDS" '/^c/'

echo "== awk print fields"
cmp_gnu "{print}"       "$WORDS" '{print}'
cmp_gnu "{print \$1}"   "$WORDS" '{print $1}'
cmp_gnu "{print \$2,\$1}" "$WORDS" '{print $2, $1}'
cmp_gnu "{print NR}"    "$WORDS" '{print NR}'

echo "== awk -F separator"
cmp_gnu "-F, \$2"       "$CSV" -F, '{print $2}'
cmp_gnu "-F, \$1,\$3"   "$CSV" -F, '{print $1, $3}'

echo "== awk BEGIN/END blocks"
cmp_gnu "BEGIN+body+END" "$WORDS" 'BEGIN{print "HEADER"} {print} END{print "FOOTER"}'
cmp_gnu "END{print NR}"  "$WORDS" '{print} END{print NR}'
cmp_gnu "BEGIN only"     "$WORDS" 'BEGIN{print "START"}'

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
