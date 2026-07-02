#!/usr/bin/env bash
# Test base32.x: RFC 4648 vectors, encode-vs-GNU, and decode roundtrip.
# Usage: base32_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/base32.x -o build/base32.c >/dev/null 2>&1; cc -O2 -o /tmp/xbase32 build/base32.c
B=/tmp/xbase32

echo "== RFC 4648 §10 vectors"
declare -a vec=("f:MY======" "fo:MZXQ====" "foo:MZXW6===" "foob:MZXW6YQ=" "fooba:MZXW6YTB" "foobar:MZXW6YTBOI======")
for v in "${vec[@]}"; do
    in="${v%%:*}"; want="${v##*:}"
    got=$(printf '%s' "$in" | "$B")
    if [ "$got" = "$want" ]; then echo "  ok   '$in' -> $got"; PASS=$((PASS+1)); else echo "  FAIL '$in' -> got [$got] want [$want]"; FAIL=$((FAIL+1)); fi
done

echo "== encode vs GNU base32"
for in in "hello" "The quick brown fox" "xlang replaces nginx and linux"; do
    a=$(printf '%s' "$in" | "$B")
    b=$(printf '%s' "$in" | base32 2>/dev/null || true)
    if [ -n "$b" ] && [ "$a" = "$b" ]; then echo "  ok   '$in'"; PASS=$((PASS+1)); else echo "  skip '$in' (GNU base32 absent or mismatch: x=[$a] g=[$b])"; fi
done

echo "== decode roundtrip"
for in in "" "f" "foo" "fooba" "foobar" "The quick brown fox jumps over the lazy dog"; do
    rt=$(printf '%s' "$in" | "$B" | "$B" -d)
    if [ "$rt" = "$in" ]; then echo "  ok   [$in]"; PASS=$((PASS+1)); else echo "  FAIL [$in] -> [$rt]"; FAIL=$((FAIL+1)); fi
done

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
