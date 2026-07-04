module main

// cut -d<delim> -f<fields> [file]   OR   cut -c<range> [file]
// -f: comma field list (1 or 2,3). -c: char range (2 or 1-3). GNU-compatible.
fn main(): i32 {
    let mut delim_s: String = "\t"
    let fields: Vec<i32> = vec_new()
    let mut char_mode: bool = false
    let mut cstart: i32 = 0
    let mut cend: i32 = 0
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_char_at(a, 0) == 45 {
            let c1: i32 = str_char_at(a, 1)
            if c1 == 100 {
                if str_len(a) > 2 {
                    delim_s = str_slice(a, 2, 3)
                } else {
                    i = i + 1
                    delim_s = str_slice(argv(i), 0, 1)
                }
            }
            if c1 == 102 {
                let mut spec: String = ""
                if str_len(a) > 2 {
                    spec = str_slice(a, 2, str_len(a))
                } else {
                    i = i + 1
                    spec = argv(i)
                }
                let sn: i32 = str_len(spec)
                let mut st: i32 = 0
                let mut k: i32 = 0
                while k <= sn {
                    if k == sn || str_char_at(spec, k) == 44 {
                        if k > st {
                            let item: String = str_slice(spec, st, k)
                            let dash: i32 = str_find(item, "-")
                            if dash >= 0 {
                                let lo_str: String = str_slice(item, 0, dash)
                                let hi_str: String = str_slice(item, dash + 1, str_len(item))
                                let lo: i32 = 1
                                let mut lo_val: i32 = lo
                                if str_len(lo_str) > 0 {
                                    lo_val = str_to_int(lo_str)
                                }
                                if str_len(hi_str) > 0 {
                                    let hi_val: i32 = str_to_int(hi_str)
                                    let mut f: i32 = lo_val
                                    while f <= hi_val {
                                        fields.push(f)
                                        f = f + 1
                                    }
                                } else {
                                    fields.push(lo_val)
                                }
                            } else {
                                fields.push(str_to_int(item))
                            }
                        }
                        st = k + 1
                    }
                    k = k + 1
                }
            }
            if c1 == 99 {
                char_mode = true
                let mut spec: String = ""
                if str_len(a) > 2 {
                    spec = str_slice(a, 2, str_len(a))
                } else {
                    i = i + 1
                    spec = argv(i)
                }
                let sn: i32 = str_len(spec)
                let mut dash: i32 = -1
                let mut k: i32 = 0
                while k < sn {
                    if str_char_at(spec, k) == 45 {
                        dash = k
                    }
                    k = k + 1
                }
                if dash < 0 {
                    cstart = str_to_int(spec)
                    cend = cstart
                } else {
                    let lo_str: String = str_slice(spec, 0, dash)
                    let hi_str: String = str_slice(spec, dash + 1, sn)
                    if str_len(lo_str) > 0 {
                        cstart = str_to_int(lo_str)
                    } else {
                        cstart = 1
                    }
                    if str_len(hi_str) > 0 {
                        cend = str_to_int(hi_str)
                    } else {
                        cend = 1000000
                    }
                }
            }
        } else {
            file = a
        }
        i = i + 1
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
            // after a final newline; genuine empty lines mid-file (lstart < p)
            // are still emitted. (Without this, "a\nb\n" → "a\nb\n\n".)
            if p == n && lstart == n {
                lstart = p + 1
            } else {
            let ln: i32 = p - lstart
            if char_mode {
                let mut a: i32 = cstart - 1
                if a < 0 {
                    a = 0
                }
                let mut b: i32 = cend
                if b > ln {
                    b = ln
                }
                if a < b {
                    sb_push_slice(s, lstart + a, lstart + b)
                }
                sb_push("\n")
            } else {
                // Scan fields within this line's byte range [lstart, p) in the
                // single buffer s — emit matching fields directly to the sb via
                // sb_push_slice (no per-line str_slice, no per-field Vec/malloc).
                let fcount: i32 = vec_len(fields)
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
                    let mut fi: i32 = 0
                    while fi < fcount {
                        if fields[fi] == cur {
                            if first_out == 0 {
                                sb_push(delim_s)
                            }
                            sb_push_slice(s, fstart, fend)
                            first_out = 0
                        }
                        fi = fi + 1
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
            lstart = p + 1
            }
        }
        p = p + 1
    }
    print_raw(sb_str())
    return 0
}
