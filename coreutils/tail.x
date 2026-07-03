module main

// tail [-n N | -N] [-c N] [-v] [-q] [file...] — last N lines (default 10) or,
// with -c, the last N bytes. Multiple files get "==> file <==" headers.

// Print the last `limit` bytes of path ("" = stdin).
fn tail_file_bytes(path: String, limit: i32): i32 {
    let mut s: String = ""
    if str_len(path) > 0 {
        s = read_file(path)
    } else {
        s = read_stdin()
    }
    let n: i32 = str_len(s)
    let mut start: i32 = n - limit
    if start < 0 { start = 0 }
    print_raw(str_slice(s, start, n))
    return 0
}

// Print the last `limit` lines of path ("" = stdin).
fn tail_file(path: String, limit: i32): i32 {
    let mut s: String = ""
    if str_len(path) > 0 {
        s = read_file(path)
    } else {
        s = read_stdin()
    }
    let n: i32 = str_len(s)
    let lines: Vec<String> = vec_new()
    let mut start: i32 = 0
    let mut k: i32 = 0
    while k < n {
        if str_char_at(s, k) == 10 {
            lines.push(str_slice(s, start, k))
            start = k + 1
        }
        k = k + 1
    }
    if start < n {
        lines.push(str_slice(s, start, n))
    }
    let count: i32 = vec_len(lines)
    let mut j: i32 = 0
    if count > limit {
        j = count - limit
    }
    while j < count {
        print_raw(lines[j])
        print_raw("\n")
        j = j + 1
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
            tail_file_bytes("", limit)
        } else {
            tail_file("", limit)
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
            tail_file_bytes(files[p], limit)
        } else {
            tail_file(files[p], limit)
        }
        p = p + 1
    }
    return 0
}
