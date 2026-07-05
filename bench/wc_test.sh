#!/usr/bin/env bash
# Test the multi-file wc.x vs GNU wc (exact output match). Uses tiny files so all
# counts stay single-digit (GNU wc right-justifies to the max column width — with
# 1-digit counts there's no padding to match).
#
# Usage: wc_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/wc.x -o build/wc.c >/dev/null 2>&1; cc -O2 -o /tmp/xwc build/wc.c
W=/tmp/xwc
ROOT="$(mktemp -d)"
printf 'a\n'  > "$ROOT/f1"   # 1 line, 1 word, 2 bytes
printf 'bb\n' > "$ROOT/f2"   # 1 line, 1 word, 3 bytes

cmp_gnu() {  # cmp_gnu <label> <args...>  (exact, order-significant)
    local label="$1"; shift
    local a b
    a=$(cd "$ROOT" && "$W" "$@" 2>/dev/null)
    b=$(cd "$ROOT" && LC_ALL=C wc "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       xlang: |$(echo "$a"|tr '\n' '~')|"; echo "       gnu:   |$(echo "$b"|tr '\n' '~')|"; FAIL=$((FAIL+1)); fi
}

echo "== vs GNU wc (exact)"
cmp_gnu "single -l"      -l f1
cmp_gnu "single default" f1
cmp_gnu "single -m"      -m f1
cmp_gnu "multi default"  f1 f2
cmp_gnu "multi -l"       -l f1 f2
cmp_gnu "multi -w"       -w f1 f2
cmp_gnu "multi -lw"      -lw f1 f2
cmp_gnu "single -L"      -L f2

echo "== stdin (pipe) — GNU pads multi-count to min width 7"
cmp_stdin() {  # cmp_stdin <label> <input> <args...>
    local label="$1" inp="$2"; shift 2
    local a b
    a=$(printf '%s' "$inp" | LC_ALL=C "$W" "$@" 2>/dev/null)
    b=$(printf '%s' "$inp" | LC_ALL=C wc "$@" 2>/dev/null)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       xlang: |$a|"; echo "       gnu:   |$b|"; FAIL=$((FAIL+1)); fi
}
cmp_stdin "stdin default" $'a b\nc d e\n'
cmp_stdin "stdin -l"      $'a b\nc d e\n' -l
cmp_stdin "stdin -m"      $'a b\nc d e\n' -m

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
