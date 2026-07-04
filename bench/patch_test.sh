#!/usr/bin/env bash
# Test patch.x vs GNU patch: apply a unified diff, compare the patched files.
# Usage: patch_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/patch.x -o build/patch.c >/dev/null 2>&1
cc -O2 -o /tmp/xpatch build/patch.c
P=/tmp/xpatch

ROOT="$(mktemp -d)"
cleanup() { rm -rf "$ROOT"; }
trap cleanup EXIT

# Create a file and a diff (change a line + add a line).
printf 'alpha\nbeta\ngamma\ndelta\nepsilon\n' > "$ROOT/orig.txt"
printf 'alpha\nBETA\nNEW\ngamma\ndelta\nepsilon\n' > "$ROOT/new.txt"
diff -u "$ROOT/orig.txt" "$ROOT/new.txt" > "$ROOT/test.patch" 2>/dev/null || true

# Apply xlang patch (rewrite --- header to target a copy).
cp "$ROOT/orig.txt" "$ROOT/xlang.txt"
sed "s|orig.txt|xlang.txt|g" "$ROOT/test.patch" | (cd "$ROOT" && "$P") >/dev/null 2>&1

# Apply GNU patch to another copy.
cp "$ROOT/orig.txt" "$ROOT/gnu.txt"
sed "s|orig.txt|gnu.txt|g" "$ROOT/test.patch" | (cd "$ROOT" && patch -s) 2>/dev/null

if diff -q "$ROOT/xlang.txt" "$ROOT/gnu.txt" >/dev/null 2>&1; then
    echo "  ok   patch matches GNU"; PASS=$((PASS+1))
else
    echo "  FAIL patch"; echo "       xlang:"; sed 's/^/         /' "$ROOT/xlang.txt"
    echo "       gnu:"; sed 's/^/         /' "$ROOT/gnu.txt"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
