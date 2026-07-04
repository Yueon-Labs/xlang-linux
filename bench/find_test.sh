#!/usr/bin/env bash
# Test the upgraded find.x (-name glob, -type, -maxdepth) vs GNU find.
#
# Usage: find_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."

PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/find.x -o build/find.c >/dev/null 2>&1; cc -O2 -o /tmp/xfind build/find.c
F=/tmp/xfind

ROOT="$(mktemp -d)"
mkdir -p "$ROOT/a/b/c"
printf 'x' > "$ROOT/top.x"
printf 'x' > "$ROOT/a/mid.txt"
printf 'x' > "$ROOT/a/b/deep.x"
printf 'x' > "$ROOT/a/b/c/leaf.x"
printf 'x' > "$ROOT/a/b/note.md"
printf 'x' > "$ROOT/a/README.MD"

# Compare xlang find vs GNU find (sorted), run from inside ROOT with start ".".
cmp_gnu() {  # cmp_gnu <label> <args...>
    local label="$1"; shift
    local a b
    a=$(cd "$ROOT" && "$F" "$@" 2>/dev/null | sort)
    b=$(cd "$ROOT" && find "$@" 2>/dev/null | sort)
    if [ "$a" = "$b" ]; then echo "  ok   $label"; PASS=$((PASS+1)); else echo "  FAIL $label"; echo "       xlang: $(echo "$a" | tr '\n' ' ')"; echo "       gnu:   $(echo "$b" | tr '\n' ' ')"; FAIL=$((FAIL+1)); fi
}

echo "== cross-check vs GNU find (sorted)"
cmp_gnu "-name *.x"        . -name "*.x"
cmp_gnu "-name *.md"       . -name "*.md"
cmp_gnu "-name a*"         . -name "a*"
cmp_gnu "-type f"          . -type f
cmp_gnu "-type d"          . -type d
cmp_gnu "-name *.x -type f" . -name "*.x" -type f
cmp_gnu "-maxdepth 1"      . -maxdepth 1
cmp_gnu "-maxdepth 2 -name *.x" . -maxdepth 2 -name "*.x"
cmp_gnu "-type d -maxdepth 2" . -type d -maxdepth 2
# -iname (case-insensitive): README.MD matches *.md only under -iname, not -name.
cmp_gnu "-name *.md (README.MD excluded)" . -name "*.md"
cmp_gnu "-iname *.md (README.MD included)" . -iname "*.md"
cmp_gnu "-iname readme*" . -iname "readme*"
cmp_gnu "-iname NOTE.md" . -iname "note.md"

echo "== find -exec (run a command per match; {} -> path)"
cmp_gnu "exec echo {}"     . -name "*.x" -exec echo X {} ";"
cmp_gnu "exec echo type-f" . -type f -exec echo F {} ";"

echo "== find -size"
cmp_gnu "size +1k"       . -type f -size +1k
cmp_gnu "size -1k"       . -type f -size -1k

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
