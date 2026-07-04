#!/usr/bin/env bash
# Test the upgraded grep.x (-r/-n/-i/-c/-v, multi-file) and cross-check vs GNU grep.
#
# Usage: grep_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/grep.x -o build/grep.c >/dev/null 2>&1; cc -O2 -o /tmp/xgrep build/grep.c
G=/tmp/xgrep

ROOT="$(mktemp -d)"
printf 'apple\nBanana\ncherry\napple pie\n' > "$ROOT/f1"
mkdir "$ROOT/sub"
printf 'grape\nApple\n' > "$ROOT/sub/f2"

# Cross-check xlang grep output (sorted) vs GNU grep output (sorted) for stability.
xc() {  # xc <label> <xlang-args...> -- the comparison is sorted diff vs GNU
    local label="$1"; shift
    local xg=$("$G" "$@" 2>/dev/null | sort)
    shift $((0))  # no-op
    :
}
# Simpler: compare xlang vs GNU directly (same args), sorted.
cmp_gnu() {  # cmp_gnu <label> <args...>
    local label="$1"; shift
    local a b
    a=$(cd "$ROOT" && "$G" "$@" 2>/dev/null | sort)
    b=$(cd "$ROOT" && grep "$@" 2>/dev/null | sort)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       xlang: $a"; echo "       gnu:   $b"; FAIL=$((FAIL+1)); fi
}

echo "== cross-check vs GNU grep (sorted)"
cmp_gnu "basic"      apple f1
cmp_gnu "-n"         -n apple f1
cmp_gnu "-i"         -i apple f1
cmp_gnu "-c"         -c apple f1
cmp_gnu "-v"         -v apple f1
cmp_gnu "multi-file" apple f1 sub/f2
cmp_gnu "-r"         -r apple .
cmp_gnu "-rn"        -rn apple .

echo "== regex (ERE; xlang is always ERE, GNU via -E)"
cmp_gnu "regex dot"    -E 'ap.le' f1
cmp_gnu "regex star"   -E 'app*' f1
cmp_gnu "regex class"  -E '[a-z]+le' f1
cmp_gnu "regex anchor" -E '^cherry' f1

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
