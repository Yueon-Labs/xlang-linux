# xlang coreutils vs GNU — performance results

Authoritative **Linux** numbers from `bench/perf_vs_gnu.sh`, run on a fast
multi-core box (2,000,000 lines, best-of-3, xlang release `xlangc` vs GNU
coreutils). Ratio = xlang_time / GNU_time (**< 1.0 means xlang is FASTER**).

These are the real "replace linux" perf numbers. Absolute ratios vary run-to-
run — the box is shared (64 cores, other load), so a single snapshot has ±~0.3×
noise; the *trend* (which tools win / lose) is stable across runs.

## Snapshot — 2026-07-05 (2,000,000 lines, best-of-3)

### xlang FASTER than GNU

| tool | xlang | GNU | ratio | note |
|---|---|---|---|---|
| rev | 0.53s | 1.94s | **0.27×** (3.7× faster) | |
| comm -3 a b | 0.33s | 1.00s | **0.33×** (3.0× faster) | sb-buffered merge (xlang-linux#145) |
| comm a b | 0.38s | 1.05s | **0.36×** (2.8× faster) | sb-buffered merge (xlang-linux#145) |
| wc (l/w/c) | 0.18s | 0.47s | **0.38×** (2.6× faster) | |
| sort | 0.65s | 1.52s | **0.43×** (2.3× faster) | merge sort + strcmp beats GNU locale collation |
| sort -n | 1.15s | 1.67s | **0.69×** | |
| unexpand -a | 0.38s | 0.62s | **0.61×** | |
| fold -w 20 | 0.38s | 0.42s | **0.90×** (≈tied) | |
| uniq | 0.09s | 0.08s | 1.12× (≈tied) | byte-range compare + `sb_push_slice` |
| cat | 0.00s | 0.01s | ≤ GNU | `sendfile_stdout()` zero-copy |

### xlang SLOWER than GNU (remaining gaps)

| tool | xlang | GNU | ratio | root cause / note |
|---|---|---|---|---|
| factor 1..N | 2.20s | 0.48s | **4.58×** | **compute-bound**: trial division vs GNU's Pollard-rho + GMP. Output buffering didn't help — the factoring math dominates. (xlang-linux#146) |
| wc -l | 0.11s | 0.03s | **3.67×** | `count_newlines` memchr vs GNU's tuned loop; plus `read_file` loads whole file |
| tac | 0.23s | 0.07s | **3.29×** | inherent: read-all + reverse (2M mallocs) |
| showall (cat -A) | 0.18s | 0.07s | **2.57×** | `cat_show` C builtin 1:N expansion (residual) |
| tr a-z A-Z | 0.15s | 0.06s | **2.50×** | `str_translate` bulk C builtin (residual) |
| tr -d aeiou | 0.17s | 0.08s | **2.12×** | `str_delete` bulk C builtin (residual) |
| paste a b | 0.79s | 0.41s | **1.93×** | sb output buffering helped (#144), but **upstream `str_split`** builds 4M malloc'd lines — the bottleneck, not output. Next: `sb_push_slice` refactor. |
| cate (cat -E) | 0.18s | 0.11s | **1.64×** | `cat_show` C builtin (residual) |
| join a b | 2.47s | 1.52s | **1.62×** | sb batching helped (#145), but **per-line `split_fields`** (str_slice per field) re-allocates every line — the bottleneck. Next: avoid re-splitting. |
| uniq -c | 0.46s | 0.30s | **1.53×** | |
| nl | 0.60s | 0.42s | **1.43×** | |
| cut -d- -f2 | 0.27s | 0.22s | **1.23×** | `sb_push_slice` (was 2.62×) |

### Matching-bound (output buffering applied, but matching dominates)

| tool | xlang | GNU | note |
|---|---|---|---|
| grep word (all match) | 0.59s | <0.01s | **regex-bound**: xlang uses POSIX `regexec` per line; GNU grep uses a custom DFA + Boyyer-Moore literal matcher (>1 GB/s). Output is buffered (#147) but the per-line `regexec` is the ~100× gap. Closing it needs a custom matcher, not output work. |

### Sub-resolution (GNU < 0.01s; ratio not measurable)

`head -1000`, `tail -1000`, `seq`, `base64`, `md5sum`, `expand` — both sides
finish below `/usr/bin/time`'s 0.01s resolution on this box.

## What changed since the 2026-06-04 snapshot

The **output-buffering sweep** (`str_join` + StringBuilder batching) landed
for `paste` (#144), `comm`/`join` (#145), `factor`/`awk` (#146), `grep`
(#147), joining the earlier `cat`/`tac`/`nl`/`uniq`/`cut`/`cate`/`showall`/
`expand`/`unexpand`/`fold`/`sort`. **`comm` went from a syscall storm to
2.8–3.0× faster than GNU.** But the sweep also clarified where the REAL
bottlenecks are — for `paste`/`join` it's **upstream per-line allocation**
(`str_split`/`split_fields`), and for `grep`/`factor` it's the **algorithm**
(regex engine / trial division), neither of which output buffering touches.
Those are the next targets. `paste` now also reads stdin (#TBD), matching
GNU.

## How to reproduce
```
PERF_N=2000000 PERF_BEST=3 bash bench/perf_vs_gnu.sh <path/to/release/xlangc>
```
(linux; needs GNU coreutils + `/usr/bin/time`. Portable timer: falls back to
`date +%s%N` where `/usr/bin/time` is absent, e.g. git-bash on Windows.)
