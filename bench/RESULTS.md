# xlang coreutils vs GNU — performance results

Authoritative **Linux** numbers from `bench/perf_vs_gnu.sh`, run on a fast
multi-core box (2,000,000 lines, best-of-2, xlang release `xlangc` vs GNU
coreutils). Ratio = xlang_time / GNU_time (< 1.0 means xlang is FASTER).

These are the real "replace linux" perf numbers — the Windows-local run
understates some gaps (Linux I/O is faster, so per-element overhead shows more).

## xlang FASTER than GNU

| tool | xlang | GNU | ratio |
|---|---|---|---|
| sort | 0.66s | 2.50s | **0.26×** (3.8× faster) |
| rev | 0.87s | 2.77s | **0.31×** (3.2× faster) |
| wc (l/w/c) | 0.17s | 0.46s | **0.37×** (2.7× faster) |
| sort -n | 1.17s | 2.52s | **0.46×** |
| unexpand -a | 0.37s | 0.62s | **0.60×** |
| fold -w 20 | 0.35s | 0.41s | **0.85×** |

xlang's merge sort + `strcmp` beats GNU sort (GNU does locale collation);
`rev`/`wc`/`unexpand` win on lean per-line processing.

## xlang slower than GNU (and what was done)

| tool | xlang | GNU | ratio | status |
|---|---|---|---|---|
| cat | 0.06s | 0.01s | 6.0× | I/O copy (read+write vs GNU splice) — inherent |
| tac | 0.58s | 0.12s | 4.8× | per-line reverse + I/O |
| **wc -l** | 0.37s | 0.04s | ~~9.25×~~ → **3.0×** | **fixed**: bulk newline count via `str_find_from` (0.37s→0.03s) |
| tr a-z A-Z | 0.47s | 0.06s | 7.8× | per-char translate table |
| tr -d aeiou | 0.33s | 0.07s | 4.7× | per-char |
| showall (cat -A) | 0.35s | 0.06s | 5.8× | per-char |
| cate (cat -E) | 0.35s | 0.11s | 3.2× | per-char |
| cut -d- -f2 | 0.54s | 0.21s | 2.6× | per-field slice |
| uniq | 0.17s | 0.08s | 2.1× | |
| uniq -c | 0.54s | 0.30s | 1.8× | |
| nl | 0.66s | 0.41s | 1.6× | |

The remaining gaps are mostly **per-char/per-element processing** (translate,
cat -A/-E) or **I/O copy** (cat — GNU uses zero-copy splice on pipes, which
xlang's read+write can't match without a sendfile-to-stdout builtin). Several
tools are already faster than GNU.

## How to reproduce
```
PERF_N=2000000 PERF_BEST=2 bash bench/perf_vs_gnu.sh <path/to/release/xlangc>
```
(linux; needs GNU coreutils + `/usr/bin/time`. Portable timer: falls back to
`date +%s%N` where `/usr/bin/time` is absent, e.g. git-bash on Windows.)
