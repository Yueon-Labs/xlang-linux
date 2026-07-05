#!/usr/bin/env bash
# perf_vs_gnu.sh — head-to-head timing: xlang coreutils vs GNU coreutils on a
# large input. For each tool prints xlang time, GNU time, and the ratio, and
# flags anything ≥5× slower. This is the "replace linux" perf scoreboard.
#
# Informational & machine-dependent (NOT a CI gate): absolute times vary by
# host; the point is to track the gap and catch regressions. GNU tool absent
# or either side erroring → that row is skipped.
#
# Timer: uses /usr/bin/time -f %e when present (Linux), else falls back to
# date +%s%N deltas (MSYS2/git-bash). Env knobs: PERF_N (line count, default
# 200000), PERF_BEST (best-of runs, default 3). Usage: perf_vs_gnu.sh [xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
mkdir -p build bin

# Build the xlang coreutils we benchmark (skip any that fail to build — some
# use Linux-only directory/network builtins and won't link on Windows).
TOOLS="cat tac rev head tail wc sort uniq tr cut fold nl grep base64 base32 md5sum sha256sum expand unexpand paste comm join cate showall seq"
for t in $TOOLS; do
    if [ -f "coreutils/$t.x" ]; then
        "$XLANGC" c "coreutils/$t.x" -o "build/$t.c" >/dev/null 2>&1
        cc -O2 -o "bin/$t" "build/$t.c" 2>/dev/null || echo "  (skip $t: build failed)"
    fi
done

N=${PERF_N:-200000}
BEST=${PERF_BEST:-3}
seq 1 "$N" | awk '{print "line-"$1 " word-"$1 " data "$1}' > build/perf_in.txt
seq 1 "$N" | sort | uniq > build/perf_sorted.txt   # uniq needs sorted input
# Two lexically-sorted files with a half-overlap, for comm (file args, not stdin).
seq 1 "$N" | sort > build/perf_comm_a.txt
seq $((N/2)) $((N + N/2)) | sort > build/perf_comm_b.txt
# Field-separated files sorted on field 1, half-overlap, for join.
seq 1 "$N" | awk '{print $1" a"$1}' | sort -k1,1 > build/perf_join_a.txt
seq $((N/2)) $((N + N/2)) | awk '{print $1" b"$1}' | sort -k1,1 > build/perf_join_b.txt
printf 'a\tb\tc\td\te\n' > build/perf_tab.txt
head -c 1000000 build/perf_in.txt > build/perf_blob.txt   # for base64 / hashes
B="$PWD/bin"

# Timer selection.
HAVE_GTIME=0
command -v /usr/bin/time >/dev/null 2>&1 && HAVE_GTIME=1

# secs "cmd..." "input"  -> real seconds (decimal string).
secs() {
    local cmd="$1" inp="$2"
    if [ "$HAVE_GTIME" = 1 ]; then
        /usr/bin/time -f "%e" bash -c "$cmd < '$inp' >/dev/null" 2>&1 | tail -1
    else
        local s e
        s=$(date +%s%N); bash -c "$cmd < '$inp' >/dev/null" 2>/dev/null; e=$(date +%s%N)
        awk "BEGIN{printf \"%.3f\", ($e - $s)/1e9}"
    fi
}

# mn A B -> the smaller of two decimal-second strings (A="" ⇒ B)
mn() {
    [ -z "$1" ] && { printf '%s' "$2"; return; }
    awk "BEGIN{exit !($2 < $1)}" >/dev/null 2>&1 && printf '%s' "$2" || printf '%s' "$1"
}

# race LABEL INPUT "xlang cmd..." "gnu cmd..."  -> prints one result row.
race() {
    local label="$1" inp="$2" xlc="$3" gnuc="$4"
    local gnu_first="${gnuc%% *}"
    if ! command -v "$gnu_first" >/dev/null 2>&1; then
        printf "  %-22s  (GNU %s absent — skipped)\n" "$label" "$gnu_first"; return
    fi
    bash -c "$xlc < '$inp' >/dev/null 2>&1" || { printf "  %-22s  (xlang errored — skipped)\n" "$label"; return; }
    bash -c "$gnuc < '$inp' >/dev/null 2>&1" || { printf "  %-22s  (GNU errored — skipped)\n" "$label"; return; }
    local xlbest="" gbest="" e _i
    for _i in $(seq 1 "$BEST"); do
        e=$(secs "$xlc" "$inp"); xlbest=$(mn "$xlbest" "$e")
        e=$(secs "$gnuc" "$inp"); gbest=$(mn "$gbest" "$e")
    done
    # When GNU rounds to 0.00s the ratio is meaningless (and divides by zero);
    # report both as sub-resolution instead.
    if awk "BEGIN{exit !($gbest + 0 > 0.005)}" >/dev/null 2>&1; then
        local ratio; ratio=$(awk "BEGIN{printf \"%.2f\", $xlbest/$gbest}")
        local flag=""
        awk "BEGIN{exit !($ratio + 0 >= 5)}" >/dev/null 2>&1 && flag="  <-- slow"
        printf "  %-22s  %6.2fs  %6.2fs  %5.2fx%s\n" "$label" "$xlbest" "$gbest" "$ratio" "$flag"
    else
        printf "  %-22s  %6.2fs  %6.2fs    (sub-resolution)\n" "$label" "$xlbest" "$gbest"
    fi
}

echo "=== xlang coreutils vs GNU @ ${N} lines  (best-of-${BEST}; xlang / GNU / ratio) ==="
printf "  %-22s  %7s  %7s  %6s\n" "tool" "xlang" "GNU" "ratio"
race "cat"          build/perf_in.txt     "$B/cat"            "cat"
race "tac"          build/perf_in.txt     "$B/tac"            "tac"
race "rev"          build/perf_in.txt     "$B/rev"            "rev"
race "head -1000"   build/perf_in.txt     "$B/head -1000"     "head -1000"
race "tail -1000"   build/perf_in.txt     "$B/tail -1000"     "tail -1000"
race "wc -l"        build/perf_in.txt     "$B/wc -l"          "wc -l"
race "wc"           build/perf_in.txt     "$B/wc"             "wc"
race "sort"         build/perf_in.txt     "$B/sort"           "sort"
race "sort -n"      build/perf_in.txt     "$B/sort -n"        "sort -n"
race "uniq"         build/perf_sorted.txt "$B/uniq"           "uniq"
race "uniq -c"      build/perf_sorted.txt "$B/uniq -c"        "uniq -c"
race "tr -d aeiou"  build/perf_in.txt     "$B/tr -d aeiou"    "tr -d aeiou"
race "tr a-z A-Z"   build/perf_in.txt     "$B/tr a-z A-Z"     "tr a-z A-Z"
race "cut -d- -f2"  build/perf_in.txt     "$B/cut -d- -f2"    "cut -d- -f2"
race "fold -w 20"   build/perf_in.txt     "$B/fold -w 20"     "fold -w 20"
race "nl"           build/perf_in.txt     "$B/nl"             "nl"
race "grep word-500" build/perf_in.txt    "$B/grep word-500"  "grep word-500"
race "base64"       build/perf_blob.txt   "$B/base64"         "base64"
race "md5sum"       build/perf_blob.txt   "$B/md5sum"         "md5sum"
race "expand"       build/perf_tab.txt    "$B/expand"         "expand"
race "unexpand -a"  build/perf_in.txt     "$B/unexpand -a"    "unexpand -a"
race "cate (cat -E)"   build/perf_in.txt  "$B/cate"           "cat -E"
race "showall (cat -A)" build/perf_in.txt "$B/showall"        "cat -A"
# paste -s merges all stdin lines into one tab-separated line (serial mode,
# single-char delim → str_join fast path: one join + one write vs ~2N writes).
race "paste -s"       build/perf_in.txt  "$B/paste -s"       "paste -s"
race "paste -s -d,"   build/perf_in.txt  "$B/paste -s -d ,"  "paste -s -d ,"
# Parallel paste needs file args (not stdin); feed the same input twice.
race "paste a b"      build/perf_in.txt  "$B/paste build/perf_in.txt build/perf_in.txt" "paste build/perf_in.txt build/perf_in.txt"
# comm compares two sorted files (file args); dummy stdin is ignored.
race "comm a b"       build/perf_sorted.txt "$B/comm build/perf_comm_a.txt build/perf_comm_b.txt" "comm build/perf_comm_a.txt build/perf_comm_b.txt"
race "comm -3 a b"    build/perf_sorted.txt "$B/comm -3 build/perf_comm_a.txt build/perf_comm_b.txt" "comm -3 build/perf_comm_a.txt build/perf_comm_b.txt"
# join merges two field-1-sorted files (file args); dummy stdin is ignored.
race "join a b"       build/perf_sorted.txt "$B/join build/perf_join_a.txt build/perf_join_b.txt" "join build/perf_join_a.txt build/perf_join_b.txt"
# seq generates its own output (ignores stdin); feed input only for the harness.
race "seq 1 200000"   build/perf_in.txt "$B/seq 1 200000"    "seq 1 200000"
echo "=== done ==="
rm -f build/perf_in.txt build/perf_sorted.txt build/perf_comm_a.txt build/perf_comm_b.txt build/perf_join_a.txt build/perf_join_b.txt build/perf_tab.txt build/perf_blob.txt
