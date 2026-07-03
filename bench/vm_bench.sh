#!/usr/bin/env bash
# vm_bench.sh — a stack-based bytecode VM dogfooding payload enums
# (enum Op { Push(i32), Add, Sub, Mul, Halt }) and benchmarking enum match
# dispatch against a hand-written C VM (tagged union + switch).
#
# Correctness gate: xlang and C produce the same accumulated sum. Timing is
# informational — the enum-match lowering should be within ~1.2x of a C switch.
#
# Usage: vm_bench.sh [path/to/xlangc]
set -u
XLANGC="${1:-xlangc}"
cd "$(dirname "$0")/.."
mkdir -p bin

"$XLANGC" c bench/vm_bench.x -o build/vm_bench.c >/dev/null 2>&1
cc -O2 -o bin/vm_bench build/vm_bench.c
cc -O2 -o bin/vm_bench_ref bench/vm_bench_ref.c

PASS=0; FAIL=0
echo "== correctness (xlang enum-VM vs C switch-VM, same program)"
for n in 100 100000 2000000; do
    xl=$(./bin/vm_bench "$n" 2>/dev/null)
    cf=$(./bin/vm_bench_ref "$n" 2>/dev/null)
    if [ "$xl" = "$cf" ] && [ -n "$xl" ]; then
        echo "  ok   N=$n → $xl"; PASS=$((PASS+1))
    else
        echo "  FAIL N=$n → xlang $xl, C $cf"; FAIL=$((FAIL+1))
    fi
done

echo "== perf vs hand-written C (informational)"
timeit() {  # timeit <label> <exe> <N>
    local label="$1" exe="$2" n="$3" t
    t=$(/usr/bin/time -f "%e" "$exe" "$n" 2>&1 >/dev/null | tail -1)
    printf "  %-30s %ss\n" "$label" "$t"
}
timeit "xlang enum-VM  N=2M" ./bin/vm_bench     2000000
timeit "C switch-VM   N=2M" ./bin/vm_bench_ref 2000000

echo
echo "RESULT: pass=$PASS fail=$FAIL"
[ "$FAIL" = 0 ]
