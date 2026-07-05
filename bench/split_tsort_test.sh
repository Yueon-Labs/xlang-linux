#!/usr/bin/env bash
# Test split.x and tsort.x — these have non-standard interfaces (split writes
# files, tsort does topological sort), so tested structurally rather than
# vs GNU directly.
# Usage: split_tsort_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/split.x  -o build/split.c  >/dev/null 2>&1; cc -O2 -o /tmp/xsplit  build/split.c
"$XLANGC" c coreutils/tsort.x  -o build/tsort.c  >/dev/null 2>&1; cc -O2 -o /tmp/xtsort  build/tsort.c

echo "== split"
ROOT="$(mktemp -d)"
seq 1 10 > "$ROOT/input"
cd "$ROOT"
# GNU syntax: -l LINES, prefix, alpha suffix (aa, ab, ...). Verify vs GNU.
/tmp/xsplit -l 3 input s_ >/dev/null 2>&1
split -l 3 input g_ >/dev/null 2>&1
xn=$(ls s_* 2>/dev/null | wc -l)
gn=$(ls g_* 2>/dev/null | wc -l)
xsum=$(cat s_* 2>/dev/null | md5sum | cut -d' ' -f1)
gsum=$(cat g_* 2>/dev/null | md5sum | cut -d' ' -f1)
if [ "$xn" -eq "$gn" ] && [ "$xsum" = "$gsum" ] && [ "$xn" -eq 4 ]; then
    echo "  ok   split -l 3 matches GNU (4 files, content)"; PASS=$((PASS+1))
else
    echo "  FAIL split (xfiles=$xn gfiles=$gn)"; FAIL=$((FAIL+1))
fi
cd - >/dev/null
rm -rf "$ROOT"

echo "== tsort"
INPUT=$'a b\nb c\nc d\n'
result=$(printf '%s' "$INPUT" | /tmp/xtsort 2>/dev/null)
expected=$'a\nb\nc\nd'
if [ "$result" = "$expected" ]; then
    echo "  ok   tsort linear chain a→b→c→d"; PASS=$((PASS+1))
else
    echo "  FAIL tsort (got [$result])"; FAIL=$((FAIL+1))
fi

INPUT2=$'shirt belt\nbelt pants\npants shoes\n'
result2=$(printf '%s' "$INPUT2" | /tmp/xtsort 2>/dev/null)
if echo "$result2" | head -1 | grep -q 'shirt' && echo "$result2" | tail -1 | grep -q 'shoes'; then
    echo "  ok   tsort dependencies (shirt before shoes)"; PASS=$((PASS+1))
else
    echo "  FAIL tsort deps (got [$result2])"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
