#!/usr/env/bin bash
# Test stat.x: default format + -c FORMAT specifiers.
# Usage: stat_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/stat.x -o build/stat.c >/dev/null 2>&1; cc -O2 -o /tmp/xstat build/stat.c
ST=/tmp/xstat
ROOT="$(mktemp -d)"
printf 'hello' > "$ROOT/f1"
mkdir "$ROOT/d1"

echo "== stat default format"
out=$("$ST" "$ROOT/f1" 2>/dev/null)
if echo "$out" | grep -q "File:" && echo "$out" | grep -q "Size: 5" && echo "$out" | grep -q "regular file"; then
    echo "  ok   default file"; PASS=$((PASS+1))
else
    echo "  FAIL default file [$out]"; FAIL=$((FAIL+1))
fi

out2=$("$ST" "$ROOT/d1" 2>/dev/null)
if echo "$out2" | grep -q "directory"; then
    echo "  ok   directory type"; PASS=$((PASS+1))
else
    echo "  FAIL directory [$out2]"; FAIL=$((FAIL+1))
fi

out3=$("$ST" "$ROOT/nonexistent" 2>/tmp/stat_err); rc=$?
err3=$(cat /tmp/stat_err)
if [ $rc -ne 0 ] && [ -z "$out3" ] && echo "$err3" | grep -q "No such file"; then
    echo "  ok   not found + exit 1 (stderr)"; PASS=$((PASS+1))
else
    echo "  FAIL not found [$out3] rc=$rc err=[$err3]"; FAIL=$((FAIL+1))
fi

echo "== -c FORMAT"
sz=$("$ST" -c "%s" "$ROOT/f1" 2>/dev/null | tr -d '\n')
if [ "$sz" = "5" ]; then
    echo "  ok   -c %s (size)"; PASS=$((PASS+1))
else
    echo "  FAIL -c %s [$sz]"; FAIL=$((FAIL+1))
fi

name=$("$ST" -c "%n" "$ROOT/f1" 2>/dev/null | tr -d '\n')
if echo "$name" | grep -q "f1"; then
    echo "  ok   -c %n (name)"; PASS=$((PASS+1))
else
    echo "  FAIL -c %n [$name]"; FAIL=$((FAIL+1))
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
rm -rf "$ROOT"
[ "$FAIL" = 0 ]
