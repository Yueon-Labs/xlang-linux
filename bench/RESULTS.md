# xlang coreutils vs GNU — performance results

Authoritative **Linux** numbers from `bench/perf_vs_gnu.sh`, run on a fast
multi-core box (2,000,000 lines, best-of-3, xlang release `xlangc` vs GNU
coreutils). Ratio = xlang_time / GNU_time (**< 1.0 means xlang is FASTER**).

These are the real "replace linux" perf numbers. Absolute ratios vary run-to-
run — the box is shared (64 cores, other load), so a single snapshot has ±~0.3×
noise; the *trend* (which tools win / lose) is stable across runs.

## Snapshot — 2026-06-04 (2,000,000 lines, best-of-3)

### xlang FASTER than GNU

| tool | xlang | GNU | ratio |
|---|---|---|---|
| rev | 0.52s | 1.96s | **0.27×** (3.7× faster) |
| wc (l/w/c) | 0.18s | 0.47s | **0.38×** (2.6× faster) |
| sort | 0.68s | 1.58s | **0.43×** (2.3× faster) |
| sort -n | 1.19s | 1.70s | **0.70×** |
| unexpand -a | 0.37s | 0.61s | **0.61×** |
| fold -w 20 | 0.38s | 0.41s | **0.93×** (≈tied) |
| cat | 0.00s | 0.01s | ≤ GNU (sendfile zero-copy) |

xlang's merge sort + `strcmp` beats GNU sort (GNU does locale collation);
`rev`/`wc`/`unexpand` win on lean per-line processing; `cat` uses
`sendfile_stdout()` zero-copy.

### xlang slower than GNU (remaining gaps)

| tool | xlang | GNU | ratio | note |
|---|---|---|---|---|
| tac | 0.28s | 0.06s | 4.67× | per-line reverse + I/O (read-all + reverse) |
| showall (cat -A) | 0.19s | 0.07s | 2.71× | bulk `cat_show` (residual gap) |
| cut -d- -f2 | 0.55s | 0.21s | 2.62× | per-field slice |
| tr a-z A-Z | 0.15s | 0.06s | 2.50× | bulk `str_translate` (residual gap) |
| wc -l | 0.07s | 0.03s | 2.33× | bulk newline count via `str_find_from` |
| uniq | 0.17s | 0.08s | 2.12× | line-compare overhead |
| tr -d aeiou | 0.17s | 0.08s | 2.12× | bulk `str_delete` (residual gap) |
| cate (cat -E) | 0.20s | 0.11s | 1.82× | bulk `cat_show` (residual gap) |
| uniq -c | 0.54s | 0.30s | 1.80× | |
| nl | 0.59s | 0.41s | 1.44× | |

The biggest remaining gap is **tac** (4.67×) — it reads all lines into a Vec
and reverses (per-element malloc), where GNU tac streams. The 2–2.7× cluster
(`tr`/`cut`/`uniq`/`cate`/`showall`/`wc -l`) is dominated by **per-element /
per-line processing** that the bulk-C builtins reduced but didn't fully close
(GNU also benefits from highly-tuned inner loops). Sub-resolution tools
(`head`/`tail`/`grep`/`seq`/`base64`/`md5sum` — both sides < 0.01s) are omitted.

## How to reproduce
```
PERF_N=2000000 PERF_BEST=3 bash bench/perf_vs_gnu.sh <path/to/release/xlangc>
```
(linux; needs GNU coreutils + `/usr/bin/time`. Portable timer: falls back to
`date +%s%N` where `/usr/bin/time` is absent, e.g. git-bash on Windows.)
