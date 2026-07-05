module main

// cut -d<delim> -f<fields> [-s] [--complement] [file]
// cut -c<chars>  [--complement] [file]   (character positions)
// cut -b<bytes>  [--complement] [file]   (bytes; same as -c for ASCII)
// Specs are a comma list of: N, N-M, N- (to end of line), -M (from start).
// GNU-compatible: selected items are emitted ONCE in ascending order;
// --complement inverts the selection; -s suppresses lines with no delim.

fn main(): i32 {
    let mut delim_s: String = "\t"
    let mut mode: i32 = 0
    let mut only_delim: i32 = 0
    let mut complement: i32 = 0
    let mut file: String = ""
    let maxidx: i32 = 4096
    // want[i] == 1 ⇒ field/char index i is selected. A set, so duplicates in
    // the spec (e.g. -f1,1) collapse, and complement is a simple inversion.
    let want: Vec<i32> = vec_new()
    let mut z: i32 = 0
    while z < maxidx {
        want.push(0)
        z = z + 1
    }
    let mut have_spec: i32 = 0
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "--complement") {
            complement = 1
            i = i + 1
        } else {
            if str_char_at(a, 0) == 45 {
                let c1: i32 = str_char_at(a, 1)
                if c1 == 100 {
                    if str_len(a) > 2 {
                        delim_s = str_slice(a, 2, 3)
                    } else {
                        i = i + 1
                        if i < argc() { delim_s = str_slice(argv(i), 0, 1) }
                    }
                    i = i + 1
                } else {
                    if c1 == 102 || c1 == 99 || c1 == 98 {
                        have_spec = 1
                        if c1 == 102 {
                            mode = 0
                        } else {
                            mode = 1
                        }
                        let mut spec: String = ""
                        if str_len(a) > 2 {
                            spec = str_slice(a, 2, str_len(a))
                        } else {
                            i = i + 1
                            if i < argc() { spec = argv(i) }
                        }
                        // Parse the spec (comma list of N / N-M / N- / -M).
                        let sn: i32 = str_len(spec)
                        let mut st: i32 = 0
                        let mut k: i32 = 0
                        while k <= sn {
                            if k == sn || str_char_at(spec, k) == 44 {
                                if k > st {
                                    let item: String = str_slice(spec, st, k)
                                    let dash: i32 = str_find(item, "-")
                                    let mut lo_val: i32 = 1
                                    let mut hi_val: i32 = maxidx
                                    if dash < 0 {
                                        lo_val = str_to_int(item)
                                        hi_val = lo_val
                                    } else {
                                        let lo_str: String = str_slice(item, 0, dash)
                                        let hi_str: String = str_slice(item, dash + 1, str_len(item))
                                        if str_len(lo_str) > 0 { lo_val = str_to_int(lo_str) }
                                        if str_len(hi_str) > 0 { hi_val = str_to_int(hi_str) }
                                    }
                                    let mut f: i32 = lo_val
                                    while f <= hi_val && f < maxidx {
                                        if f >= 1 { want[f] = 1 }
                                        f = f + 1
                                    }
                                }
                                st = k + 1
                            }
                            k = k + 1
                        }
                        i = i + 1
                    } else {
                        if c1 == 115 {
                            only_delim = 1
                        }
                        i = i + 1
                    }
                }
            } else {
                file = a
                i = i + 1
            }
        }
    }
    if complement == 1 {
        let mut z2: i32 = 1
        while z2 < maxidx {
            if want[z2] == 1 {
                want[z2] = 0
            } else {
                want[z2] = 1
            }
            z2 = z2 + 1
        }
    }
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let n: i32 = str_len(s)
    // Buffer output (one write) — per-line/per-field print_raw is N syscalls.
    sb_new()
    let mut lstart: i32 = 0
    let mut p: i32 = 0
    while p <= n {
        if p == n || str_char_at(s, p) == 10 {
            // GNU emits no extra blank line for the empty trailing segment
            // after a final newline; genuine empty lines mid-file still emit.
            if p == n && lstart == n {
                lstart = p + 1
            } else {
                let ln: i32 = p - lstart
                if mode == 1 {
                    // Character/byte mode: emit positions 1..ln that are wanted.
                    let mut pos: i32 = 1
                    while pos <= ln {
                        if pos < maxidx {
                            if want[pos] == 1 {
                                sb_push_slice(s, lstart + pos - 1, lstart + pos)
                            }
                        }
                        pos = pos + 1
                    }
                    sb_push("\n")
                } else {
                    // Field mode. A line with no delimiter passes through
                    // UNCHANGED (the whole line) unless -s, which suppresses it.
                    let dd: i32 = str_find_from(s, delim_s, lstart)
                    let mut has_delim: i32 = 0
                    if dd >= 0 && dd < p {
                        has_delim = 1
                    }
                    if has_delim == 0 {
                        if only_delim == 0 {
                            sb_push_slice(s, lstart, p)
                            sb_push("\n")
                        }
                    } else {
                        let mut first_out: i32 = 1
                        let mut fstart: i32 = lstart
                        let mut cur: i32 = 1
                        let mut q: i32 = lstart
                        while true {
                            let d: i32 = str_find_from(s, delim_s, q)
                            let mut fend: i32 = p
                            let mut last: i32 = 0
                            if d < 0 || d >= p {
                                fend = p
                                last = 1
                            } else {
                                fend = d
                            }
                            if cur < maxidx {
                                if want[cur] == 1 {
                                    if first_out == 0 {
                                        sb_push(delim_s)
                                    }
                                    sb_push_slice(s, fstart, fend)
                                    first_out = 0
                                }
                            }
                            if last == 1 {
                                break
                            }
                            cur = cur + 1
                            fstart = d + 1
                            q = d + 1
                        }
                        sb_push("\n")
                    }
                }
                lstart = p + 1
            }
        }
        p = p + 1
    }
    print_raw(sb_str())
    return 0
}
