# xlang-linux — Linux userland in X Language

**101 coreutils + a shell + network tools**, all written in [xlang](https://github.com/Yueon-Labs/xlang), compiled to C, and verified against GNU on Linux CI.

## Highlights

- **GNU-parity coreutils** — grep (-r/-i/-n/-c), find (-name glob/-type/-maxdepth), ls (-l/-a/-R), sed (multi-command/-e/-n), cat (-n/-b/-s/-A), head/tail (multi-file/-v/-q), wc (multi-file/total), diff (LCS-based), cut, sort, uniq, tr, base64 — all cross-checked vs GNU on every PR.
- **Shell** — `xsh`: pipelines, redirects, `$(cmd)`, `$((expr))`, `for`/`if`/`elif`/`else`/`while`, `case`/`esac`, functions, `&&`/`||`, comments, `test`/`[` (full operator set).
- **Network tools** — `httpget` (HTTP client, GET+POST, binary-safe), `nc` (netcat, connect+listen), `xwrk` (HTTP load generator, mini wrk).
- **New tools** — `calc` (f64 expression evaluator, recursive-descent parser), `xargs` (build commands from stdin), `dd` (binary block copy), `timeout` (run with time limit), `diff` (LCS-based file diff).
- **File ops** — `cp -r` (binary-safe recursive), `mv` (multi-file), `mkdir -p` (parents), `rm -rf` (recursive).
- **CI** — 18 per-tool functional suites (bench/\*_test.sh) + a pure-xlang pipeline integration test + 71-case GNU cross-check, all run on ubuntu on every PR.

## Tool Categories

**Text processing**: cat, grep, sed, awk, cut, sort, uniq, tr, head, tail, wc, diff, nl, od, paste, comm, fold, expand, unexpand, fmt, rev, tac, printf, tsort, csplit, split, base64, expr, factor, seq, shuf, calc

**File operations**: ls, cp, mv, rm, mkdir, rmdir, chmod, touch, truncate, ln, link, find, du, stat, readlink, realpath, dd, mkfifo, mktemp, install, pathchk, split

**System**: ps, kill, env, printenv, hostname, whoami, pwd, uname, nproc, date, uptime, free, tty, arch, id, groups, users

**Network**: httpget, nc, xwrk

**Shell**: xsh

**Misc**: echo, yes, true, false, clear, test, sleep, basename, dirname, xargs, timeout

## Shell (xsh)

```
xsh script.xsh    # run a script
echo $PATH        # env-var expansion
cmd1 | cmd2 | cmd3   # N-stage pipelines
cmd > f / < f / >> f  # redirects
for x in a b c; do echo $x; done   # for loop
if [ $n -lt 5 ]; then echo small; elif [ $n -lt 10 ]; then echo med; else echo big; fi
case $x in pat*) echo match ;; *) echo default ;; esac
result=$(cmd)    # command substitution
sum=$((a + b))   # arithmetic expansion
```

## Build

Requires the [xlang compiler](https://github.com/Yueon-Labs/xlang):
```sh
xlangc c coreutils/cat.x && cc -O2 -o cat cat.c && echo hello | ./cat
```

Build all:
```sh
mkdir -p build bin
for f in coreutils/*.x; do
  stem=$(basename "$f" .x)
  xlangc c "$f" -o "build/$stem.c"
  cc -O2 -o "bin/$stem" "build/$stem.c"
done
```

## Testing

```sh
# Cross-check vs GNU
bash bench/coreutils_xcheck.sh bin/

# Per-tool functional suites
bash bench/grep_test.sh xlangc
bash bench/pipeline_test.sh bin/   # pure-xlang pipeline integration
```

## Methodology

Built iteratively: **replicate → hit a limitation → modify xlang → implement → verify**.
Every tool is compiled xlang → C → `cc -O2`, with correctness verified against GNU.
