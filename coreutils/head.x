module main

// head [-n N | -N] [-c N] [-v] [-q] [file...] — first N lines (default 10) or,
// with -c, the first N bytes. Multiple files get "==> file <==" headers.

// Print the first `limit` bytes of path ("" = stdin). (Text/strlen-limited;
// not binary-safe past a NUL, like the rest of xlang's C-string I/O.)
fn head_file_bytes(path: String, limit: i32): i32 {
    let s: String = if str_len(path) > 0 { read_file(path) } else { read_stdin() }
    let n: i32 = str_len(s)
    let mut end: i32 = limit
    if end > n { end = n }
    if end < 0 { end = 0 }
    print_raw(str_slice(s, 0, end))
    return 0
}

// Print the first `limit` lines of path ("" = stdin).
fn head_file(path: String, limit: i32): i32 {
    let s: String = if str_len(path) > 0 { read_file(path) } else { read_stdin() }
    let n: i32 = str_len(s)
    let mut printed: i32 = 0
    let mut start: i32 = 0
    let mut k: i32 = 0
    while k < n {
        if str_char_at(s, k) == 10 {
            print_raw(str_slice(s, start, k))
            print_raw("\n")
            printed = printed + 1
            start = k + 1
            if printed >= limit {
                return 0
            }
        }
        k = k + 1
    }
    if start < n {
        if printed < limit {
            print_raw(str_slice(s, start, n))
            print_raw("\n")
        }
    }
    return 0
}

fn main(): i32 {
    let mut limit: i32 = 10
    let mut byte_mode: i32 = 0
    let mut want_v: i32 = 0
    let mut want_q: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        let c0: i32 = str_char_at(a, 0)
        if c0 == 45 {
            let la: i32 = str_len(a)
            if str_char_at(a, 1) == 99 {
                // -c N : byte mode
                byte_mode = 1
                if la > 2 {
                    limit = str_to_int(str_slice(a, 2, la))
                } else {
                    i = i + 1
                    if i < argc() {
                        limit = str_to_int(argv(i))
                    }
                }
            } else if str_char_at(a, 1) == 110 {
                if la > 2 {
                    limit = str_to_int(str_slice(a, 2, la))
                } else {
                    i = i + 1
                    if i < argc() {
                        limit = str_to_int(argv(i))
                    }
                }
            } else {
                let mut j: i32 = 1
                let mut gotnum: i32 = 0
                while j < la {
                    let ch: i32 = str_char_at(a, j)
                    if ch == 118 { want_v = 1 }
                    if ch == 113 { want_q = 1 }
                    if ch >= 48 { if ch <= 57 { gotnum = 1 } }
                    j = j + 1
                }
                if gotnum == 1 {
                    limit = str_to_int(str_slice(a, 1, la))
                }
            }
        } else {
            files.push(a)
        }
        i = i + 1
    }

    let nf: i32 = vec_len(files)
    if nf == 0 {
        if byte_mode == 1 {
            head_file_bytes("", limit)
        } else {
            head_file("", limit)
        }
        return 0
    }
    let mut show_header: i32 = 0
    if want_q == 0 {
        if nf > 1 { show_header = 1 }
        if want_v == 1 { show_header = 1 }
    }
    let mut p: i32 = 0
    while p < nf {
        if p > 0 {
            if show_header == 1 { print_raw("\n") }
        }
        if show_header == 1 {
            print_raw("==> ")
            print_raw(files[p])
            print_raw(" <==\n")
        }
        if byte_mode == 1 {
            head_file_bytes(files[p], limit)
        } else {
            head_file(files[p], limit)
        }
        p = p + 1
    }
    return 0
}
