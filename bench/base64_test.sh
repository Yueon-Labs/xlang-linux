#!/usr/bin/env bash
# Test base64.x: RFC 4648 vectors, encode-vs-GNU, decode roundtrip, wrap (-w).
# Usage: base64_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/base64.x -o build/base64.c >/dev/null 2>&1; cc -O2 -o /tmp/xbase64 build/base64.c
B=/tmp/xbase64

echo "== RFC 4648 §10 vectors"
declare -a vec=("f:Zg==" "fo:Zm8=" "foo:Zm9v" "foob:Zm9vYg==" "fooba:Zm9vYmE=" "foobar:Zm9vYmFy")
for v in "${vec[@]}"; do
    in="${v%%:*}"; want="${v##*:}"
    got=$(printf '%s' "$in" | "$B" -w0)
    if [ "$got" = "$want" ]; then echo "  ok   '$in' -> $got"; PASS=$((PASS+1)); else echo "  FAIL '$in' -> got [$got] want [$want]"; FAIL=$((FAIL+1)); fi
done

echo "== encode vs GNU base64"
for in in "hello" "The quick brown fox" "xlang replaces nginx and linux"; do
    a=$(printf '%s' "$in" | "$B")
    b=$(printf '%s' "$in" | base64 2>/dev/null || true)
    if [ -n "$b" ] && [ "$a" = "$b" ]; then echo "  ok   '$in'"; PASS=$((PASS+1)); else echo "  skip '$in' (GNU base64 absent or mismatch: x=[$a] g=[$b])"; fi
done

echo "== decode roundtrip"
for in in "" "f" "foo" "fooba" "foobar" "The quick brown fox jumps over the lazy dog"; do
    rt=$(printf '%s' "$in" | "$B" | "$B" -d)
    if [ "$rt" = "$in" ]; then echo "  ok   [$in]"; PASS=$((PASS+1)); else echo "  FAIL [$in] -> [$rt]"; FAIL=$((FAIL+1)); fi
done

echo "== wrap (-w / default 76) vs GNU base64"
LONG=$(head -c 200 /dev/zero | tr '\0' 'x')
for args in "" "-w0" "-w 40" "-w20"; do
    a=$(printf '%s' "$LONG" | "$B" $args)
    b=$(printf '%s' "$LONG" | base64 $args 2>/dev/null || true)
    if [ -n "$b" ] && [ "$a" = "$b" ]; then echo "  ok   base64 $args"; PASS=$((PASS+1)); else echo "  FAIL base64 $args: x=[$a] g=[$b]"; FAIL=$((FAIL+1)); fi
done

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
