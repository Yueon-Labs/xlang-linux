module main

// csplit [OPTION]... FILE PATTERN...
//
// Split FILE into sections determined by PATTERNs, writing each section to a
// separate file (xx00, xx01, ...). A faithful subset of GNU csplit.
//
// Patterns (one per argv token, or with a trailing {..} suffix):
//   N          split before line N (1-based)
//   /PAT/      split before the next line containing PAT
//   %PAT%      skip (discard) everything up to the next line containing PAT
//   {N}        repeat the preceding pattern N more times
//   {*}        repeat the preceding pattern until it no longer matches
//
// Options:
//   -f PREFIX   filename prefix            (default "xx")
//   -n DIGITS   digits in filenames        (default 2)
//   -s, -q      silent: suppress byte counts
//   -z          elide empty output files
//   -k          keep files on error
//
// NOTE: pattern matching is literal substring, not POSIX regex. Patterns
// without regex metacharacters behave identically to GNU csplit.
//
// State is threaded through a 3-slot Vec: [cur_line, fileno, last_match].

// Zero-pad `num` to at least `width` digits.
fn pad_num(num: i32, width: i32): String {
    let s: String = int_to_str(num)
    let l: i32 = str_len(s)
    if l >= width {
        return s
    }
    sb_new()
    let mut k: i32 = l
    while k < width {
        sb_push("0")
        k = k + 1
    }
    sb_push(s)
    return sb_str()
}

// Write the lines [a_line, b_line) to the next file, print the section's byte
// count (unless silent), and return the next fileno. With -z, empty sections
// are skipped (fileno unchanged). a_line/b_line are line indices; byte offsets
// come from line_starts.
fn write_section(s: String, line_starts: Vec<i32>, a_line: i32, b_line: i32, fileno: i32, prefix: String, digits: i32, silent: i32, elide: i32): i32 {
    let a: i32 = line_starts[a_line]
    let b: i32 = line_starts[b_line]
    let nbytes: i32 = b - a
    if elide == 1 && nbytes == 0 {
        return fileno
    }
    let name: String = str_concat(prefix, pad_num(fileno, digits))
    write_file(name, str_slice(s, a, b))
    if silent == 0 {
        print_i32(nbytes)
    }
    return fileno + 1
}

// First line index >= from_idx whose content contains pat, skipping the
// previously-matched line (last_match) so repeats don't re-split the same
// line. Returns -1 if no match.
fn find_match(s: String, line_starts: Vec<i32>, from_idx: i32, last_match: i32, pat: String): i32 {
    let total: i32 = vec_len(line_starts) - 1
    let mut idx: i32 = from_idx
    while idx < total {
        let lo: i32 = line_starts[idx]
        let hi: i32 = line_starts[idx + 1]
        let line: String = str_slice(s, lo, hi)
        if str_contains(line, pat) {
            if idx == last_match {
                idx = idx + 1
            } else {
                return idx
            }
        } else {
            idx = idx + 1
        }
    }
    return -1
}

// Apply one pattern once. kind: 0=LINE, 1=MATCH(/PAT/), 2=SKIP(%PAT%).
// For LINE, n is the line number (absolute if relative==0, else +n from cur).
// For MATCH/SKIP, pat is the substring. Mutates state. Returns 1 on success,
// 0 if the pattern could not be satisfied (no match / line out of range).
fn apply_pattern(s: String, line_starts: Vec<i32>, state: Vec<i32>, kind: i32, n: i32, pat: String, relative: i32, prefix: String, digits: i32, silent: i32, elide: i32): i32 {
    let total: i32 = vec_len(line_starts) - 1
    let cur: i32 = state[0]
    if kind == 0 {
        let mut target: i32 = n - 1
        if relative == 1 {
            target = cur + n
        }
        if target < cur {
            return 0
        }
        if target > total {
            return 0
        }
        state[1] = write_section(s, line_starts, cur, target, state[1], prefix, digits, silent, elide)
        state[0] = target
        return 1
    }
    let m: i32 = find_match(s, line_starts, cur, state[2], pat)
    if m < 0 {
        return 0
    }
    if kind == 1 {
        state[1] = write_section(s, line_starts, cur, m, state[1], prefix, digits, silent, elide)
    }
    state[2] = m
    state[0] = m
    return 1
}

// Repeat the preceding pattern. count==-1 means {*} (run until it fails,
// gracefully). Returns 1 normally, 0 if a fixed-count repeat failed.
fn run_repeat(s: String, line_starts: Vec<i32>, state: Vec<i32>, count: i32, pkind: i32, pn: i32, ppat: String, prefix: String, digits: i32, silent: i32, elide: i32): i32 {
    if count == 0 {
        return 1
    }
    let mut r: i32 = 0
    while count == -1 || r < count {
        let ok: i32 = apply_pattern(s, line_starts, state, pkind, pn, ppat, 1, prefix, digits, silent, elide)
        if ok == 0 {
            if count == -1 {
                return 1
            }
            return 0
        }
        r = r + 1
    }
    return 1
}

// Remove files prefix+pad(0..count-1) (used on error when not -k).
fn cleanup(prefix: String, digits: i32, count: i32): i32 {
    let mut k: i32 = 0
    while k < count {
        remove_file(str_concat(prefix, pad_num(k, digits)))
        k = k + 1
    }
    return 0
}

fn main(): i32 {
    let mut prefix: String = "xx"
    let mut digits: i32 = 2
    let mut silent: i32 = 0
    let mut elide: i32 = 0
    let mut keep: i32 = 0
    let mut file: String = ""
    let patterns: Vec<String> = vec_new()

    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-s") || str_eq(a, "-q") || str_eq(a, "--silent") || str_eq(a, "--quiet") {
            silent = 1
        } else if str_eq(a, "-z") || str_eq(a, "--elide-empty-files") {
            elide = 1
        } else if str_eq(a, "-k") || str_eq(a, "--keep-files") {
            keep = 1
        } else if str_starts_with(a, "--prefix=") {
            prefix = str_slice(a, 9, str_len(a))
        } else if str_starts_with(a, "--digits=") {
            digits = str_to_int(str_slice(a, 9, str_len(a)))
        } else if str_starts_with(a, "-f") {
            if str_len(a) > 2 {
                prefix = str_slice(a, 2, str_len(a))
            } else {
                i = i + 1
                if i < argc() {
                    prefix = argv(i)
                }
            }
        } else if str_starts_with(a, "-n") {
            if str_len(a) > 2 {
                digits = str_to_int(str_slice(a, 2, str_len(a)))
            } else {
                i = i + 1
                if i < argc() {
                    digits = str_to_int(argv(i))
                }
            }
        } else {
            if str_len(file) == 0 {
                file = a
            } else {
                patterns.push(a)
            }
        }
        i = i + 1
    }

    if str_len(file) == 0 {
        eprint_raw("csplit: usage: csplit [OPTION]... FILE PATTERN...\n")
        return 1
    }
    if vec_len(patterns) == 0 {
        eprint_raw("csplit: missing pattern\n")
        return 1
    }

    let mut s: String = ""
    if str_eq(file, "-") {
        s = read_stdin()
    } else {
        s = read_file(file)
    }

    // Build line-start byte offsets; line_starts[total] == len(s) (EOF).
    let line_starts: Vec<i32> = vec_new()
    let n: i32 = str_len(s)
    if n > 0 {
        line_starts.push(0)
    }
    let mut j: i32 = 0
    while j < n {
        if str_char_at(s, j) == 10 {
            if j + 1 < n {
                line_starts.push(j + 1)
            }
        }
        j = j + 1
    }
    line_starts.push(n)
    let total: i32 = vec_len(line_starts) - 1

    // state: [cur_line, fileno, last_match]
    let state: Vec<i32> = vec_new()
    state.push(0)
    state.push(0)
    state.push(-1)

    let mut prev_kind: i32 = -1
    let mut prev_n: i32 = 0
    let mut prev_pat: String = ""

    let mut errored: i32 = 0
    let mut pi: i32 = 0
    let np: i32 = vec_len(patterns)
    while pi < np && errored == 0 {
        let tok: String = patterns[pi]
        // Repeat token: {N} or {*}
        if str_char_at(tok, 0) == 123 && str_char_at(tok, str_len(tok) - 1) == 125 {
            if prev_kind < 0 {
                errored = 1
                break
            }
            let inner: String = str_slice(tok, 1, str_len(tok) - 1)
            let mut count: i32 = -1
            if str_eq(inner, "*") == 0 {
                count = str_to_int(inner)
            }
            if run_repeat(s, line_starts, state, count, prev_kind, prev_n, prev_pat, prefix, digits, silent, elide) == 0 {
                errored = 1
                break
            }
            pi = pi + 1
            continue
        }

        // New pattern. Determine kind by first char.
        let c0: i32 = str_char_at(tok, 0)
        if c0 == 47 || c0 == 37 {
            let mut kind: i32 = 1
            if c0 == 37 {
                kind = 2
            }
            // Find the closing delimiter, then any trailing {..} suffix.
            let delim: String = chr(c0)
            let ci: i32 = str_find_from(tok, delim, 1)
            let mut core: String = ""
            let mut suffix: String = ""
            if ci >= 0 {
                core = str_slice(tok, 1, ci)
                suffix = str_slice(tok, ci + 1, str_len(tok))
            } else {
                core = str_slice(tok, 1, str_len(tok) - 1)
                suffix = ""
            }
            state[2] = -1
            if apply_pattern(s, line_starts, state, kind, 0, core, 0, prefix, digits, silent, elide) == 0 {
                errored = 1
                break
            }
            prev_kind = kind
            prev_pat = core
            prev_n = 0
            if str_len(suffix) > 0 && str_char_at(suffix, 0) == 123 {
                let inner2: String = str_slice(suffix, 1, str_len(suffix) - 1)
                let mut count2: i32 = -1
                if str_eq(inner2, "*") == 0 {
                    count2 = str_to_int(inner2)
                }
                if run_repeat(s, line_starts, state, count2, kind, 0, core, prefix, digits, silent, elide) == 0 {
                    errored = 1
                    break
                }
            }
        } else {
            // LINE: integer, optionally with trailing {..}.
            let brace: i32 = str_find(tok, "{")
            let mut numstr: String = ""
            let mut repstr: String = ""
            if brace >= 0 {
                numstr = str_slice(tok, 0, brace)
                repstr = str_slice(tok, brace, str_len(tok))
            } else {
                numstr = tok
                repstr = ""
            }
            let nv: i32 = str_to_int(numstr)
            if apply_pattern(s, line_starts, state, 0, nv, "", 0, prefix, digits, silent, elide) == 0 {
                errored = 1
                break
            }
            prev_kind = 0
            prev_n = nv
            prev_pat = ""
            if str_len(repstr) > 0 {
                let inner3: String = str_slice(repstr, 1, str_len(repstr) - 1)
                let mut count3: i32 = -1
                if str_eq(inner3, "*") == 0 {
                    count3 = str_to_int(inner3)
                }
                if run_repeat(s, line_starts, state, count3, 0, nv, "", prefix, digits, silent, elide) == 0 {
                    errored = 1
                    break
                }
            }
        }
        pi = pi + 1
    }

    if errored == 1 {
        if keep == 0 {
            cleanup(prefix, digits, state[1])
        }
        eprint_raw("csplit: '")
        eprint_raw(patterns[pi])
        eprint_raw("': match not found or line out of range\n")
        return 1
    }

    // Final remainder [cur, total).
    state[1] = write_section(s, line_starts, state[0], total, state[1], prefix, digits, silent, elide)
    return 0
}
