#!/usr/bin/env bash
# Test csplit.x vs GNU csplit: line numbers, /PAT/, %PAT%, {N}/{*} repeats,
# -f/-n/-s/-z. Compares exit code, stdout (byte counts), and the written
# section files. Run on Linux where both binaries coexist.
# Usage: csplit_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/csplit.x -o build/csplit.c >/dev/null 2>&1
cc -O2 -o /tmp/xcsplit build/csplit.c
X=/tmp/xcsplit

# cmp_case <label> <data> <args...> — run xlang and GNU csplit on the same
# input in separate dirs; compare exit code, stdout (only when both succeed,
# since error diagnostics go to different streams), and the section files.
cmp_case() {
  local label="$1" data="$2"; shift 2
  local xd gd xe ge xrc grc
  xd=$(mktemp -d); gd=$(mktemp -d)
  printf "%s" "$data" > "$xd/in"; printf "%s" "$data" > "$gd/in"
  xe=$(cd "$xd" && "$X" "$@" in 2>/dev/null); xrc=$?
  ge=$(cd "$gd" && csplit "$@" in 2>/dev/null); grc=$?
  local ok=1
  [ "$xrc" = "$grc" ] || ok=0
  # stdout always compared: byte counts match, and diagnostics (now on
  # stderr via eprint_*) don't leak into stdout.
  [ "$xe" = "$ge" ] || ok=0
  local xfiles gfiles
  xfiles=$(cd "$xd" && ls 2>/dev/null | grep -v '^in$' | sort | tr '\n' ' ')
  gfiles=$(cd "$gd" && ls 2>/dev/null | grep -v '^in$' | sort | tr '\n' ' ')
  [ "$xfiles" = "$gfiles" ] || ok=0
  local f
  for f in $(cd "$xd" && ls 2>/dev/null | grep -v '^in$'); do
    diff -q "$xd/$f" "$gd/$f" >/dev/null 2>&1 || ok=0
  done
  if [ $ok = 1 ]; then echo "  ok   $label"; PASS=$((PASS+1)); else
    echo "  FAIL $label"; echo "    xout:[$xe] gou:[$ge] xrc=$xrc grc=$grc"
    echo "    xfiles:$xfiles gfiles:$gfiles"; FAIL=$((FAIL+1)); fi
  rm -rf "$xd" "$gd"
}

D10=$(seq 1 10)
DAB=$(printf "a\nb\na\nb\na\n")

echo "== csplit vs GNU"
cmp_case "line 3 6"          "$D10" 3 6
cmp_case "line 2"            "$D10" 2
cmp_case "/5/ match"         "$D10" /5/
cmp_case "/a/ {*} repeat"    "$DAB" /a/ '{*}'
cmp_case "/a/{*} combined"   "$DAB" '/a/{*}'
cmp_case "3 {2} repeat"      "$D10" 3 '{2}'
cmp_case "%b% skip"          "$DAB" '%b%'
cmp_case "-f pre"            "$D10" -f pre 2
cmp_case "-n 3 digits"       "$D10" -n 3 2
cmp_case "-z elide empty"    "$DAB" -z /a/ '{*}'
cmp_case "-s silent"         "$D10" -s 3 6
cmp_case "no match (error)"  "$D10" /zz/
echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
