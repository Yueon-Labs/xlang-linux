#!/usr/bin/env bash
# Test pathchk.x vs GNU pathchk: valid paths (silent, exit 0), -p nonportable
# chars, -P leading dash, --portability, length limits. Compares exit codes
# always; stdout is compared only when both exit 0 (GNU writes diagnostics to
# stderr, xlang to stdout, so the streams differ on error).
# Usage: pathchk_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/pathchk.x -o build/pathchk.c >/dev/null 2>&1
cc -O2 -o /tmp/xpathchk build/pathchk.c
X=/tmp/xpathchk

cmp_case() {
  local label="$1"; shift
  local xo go xrc grc xerr
  xo=$("$X" "$@" 2>/tmp/xpkerr); xrc=$?
  xerr=$(cat /tmp/xpkerr)
  go=$(pathchk "$@" 2>/dev/null); grc=$?
  local ok=1
  [ "$xrc" = "$grc" ] || ok=0
  # stdout always compared: diagnostics (now on stderr via eprint_*) don't
  # leak into stdout, so it matches GNU (empty) on both success and error.
  [ "$xo" = "$go" ] || ok=0
  # routing check: on error the diagnostic must land on stderr, not stdout.
  if [ "$xrc" != 0 ] && [ -z "$xerr" ]; then ok=0; fi
  if [ $ok = 1 ]; then echo "  ok   $label"; PASS=$((PASS+1)); else
    echo "  FAIL $label (x=$xrc g=$grc)"; FAIL=$((FAIL+1)); fi
}

echo "== pathchk vs GNU"
cmp_case "valid simple"        hello.txt
cmp_case "valid abs path"      /tmp/foo
cmp_case "valid deep rel"      a/b/c/d
cmp_case "-p valid"            -p good_name.txt
cmp_case "-p space nonport"    -p "bad name"
cmp_case "-p colon nonport"    -p "a:b"
cmp_case "-P leading dash"     -P -- -foo
cmp_case "dash ok without -P"  -- -foo
cmp_case "--portability space" --portability "a b"
cmp_case "-P --portability ok" --portability ok-name.txt
echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
