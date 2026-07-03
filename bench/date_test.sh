#!/usr/bin/env bash
# Test date.x: strftime formatting, -u (UTC), -R (RFC 2822), -I (ISO 8601),
# and +FORMAT. Time is live, so we lean on deterministic UTC checks (%Z=UTC,
# %z=+0000), structural regexes for the formatter, and a GNU cross-check on a
# second-free format (to dodge the 1-second boundary race).
# Usage: date_test.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
PASS=0; FAIL=0
mkdir -p build
"$XLANGC" c coreutils/date.x -o build/date.c >/dev/null 2>&1; cc -O2 -o build/xdate build/date.c
D=build/xdate

ck() {  # ck DESC EXPECTED ACTUAL
    if [ "$2" = "$3" ]; then echo "  ok   $1"; PASS=$((PASS+1))
    else echo "  FAIL $1 -> got [$3] want [$2]"; FAIL=$((FAIL+1)); fi
}
ckre() {  # ckre DESC REGEX ACTUAL
    if printf '%s' "$3" | grep -Eq "$2"; then echo "  ok   $1"; PASS=$((PASS+1))
    else echo "  FAIL $1 -> [$3] !~ /$2/"; FAIL=$((FAIL+1)); fi
}

echo "== UTC is fully deterministic"
ck "%Z in UTC is 'UTC'"     "UTC"    "$("$D" -u +%Z)"
ck "%z in UTC is '+0000'"   "+0000"  "$("$D" -u +%z)"

echo "== formatter structural checks"
ckre "%%Y is 4 digits"          '^[0-9]{4}$'                 "$("$D" +%Y)"
ckre "%%H:%%M is HH:MM"         '^[0-9]{2}:[0-9]{2}$'        "$("$D" +%H:%M)"
ckre "%%Y-%%m-%%d is a date"    '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$("$D" +%Y-%m-%d)"
ckre "%%j is 3-digit day-of-year" '^[0-9]{3}$'               "$("$D" +%j)"
ckre "weekday %%a is 3 letters" '^[A-Z][a-z]{2}$'            "$("$D" +%a)"
ckre "month %%b is 3 letters"   '^[A-Z][a-z]{2}$'            "$("$D" +%b)"

echo "== -I (ISO 8601)"
ckre "-I is a date"             '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' "$("$D" -I)"
ckre "-Iseconds"                '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}$' "$("$D" -Iseconds)"
ckre "--iso-8601=minutes"       '^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}$' "$("$D" --iso-8601=minutes)"

echo "== -R (RFC 2822)"
ckre "-R shape" '^[A-Z][a-z]{2}, [0-9]{2} [A-Z][a-z]{2} [0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2} [+-][0-9]{4}$' "$("$D" -R)"

echo "== quoted +FORMAT with a space"
ckre "quoted +%%Y-%%m-%%d %%H:%%M" '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$' "$("$D" "+%Y-%m-%d %H:%M")"

echo "== GNU cross-check (second-free format to avoid boundary race)"
if command -v date >/dev/null 2>&1; then
    for fmt in "%Y" "%m" "%d" "%Y-%m-%d %H:%M" "%j"; do
        a=$("$D" "$fmt")
        b=$(date "$fmt")
        ck "vs GNU $fmt" "$b" "$a"
    done
    # UTC cross-check on %H:%M (skipping seconds).
    a=$("$D" -u +%H:%M)
    b=$(date -u +%H:%M)
    ck "vs GNU -u +%H:%M" "$b" "$a"
else
    echo "  skip GNU cross-check (GNU date absent)"
fi

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
