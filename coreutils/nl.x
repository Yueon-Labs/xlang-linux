module main

// nl [-ba] [-w WIDTH] [-s SEP] [file] — number each line (GNU nl compatible).
//   -ba         number all lines (default)
//   -w N        width of the line number field (default 6)
//   -s SEP      separator after the number (default tab)
// stdin if no file.

fn main(): i32 {
    let mut width: i32 = 6
    let mut sep: String = "\t"
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let c1: i32 = str_char_at(a, 1)
                if c1 == 119 {
                    if str_len(a) > 2 {
                        width = str_to_int(str_slice(a, 2, str_len(a)))
                    } else {
                        i = i + 1
                        if i < argc() { width = str_to_int(argv(i)) }
                    }
                }
                if c1 == 115 {
                    if str_len(a) > 2 {
                        sep = str_slice(a, 2, str_len(a))
                    } else {
                        i = i + 1
                        if i < argc() { sep = argv(i) }
                    }
                }
                i = i + 1
            } else {
                file = a
                i = i + 1
            }
        } else {
            file = a
            i = i + 1
        }
    }
    let mut s: String = ""
    if str_len(file) > 0 {
        s = read_file(file)
    } else {
        s = read_stdin()
    }
    let n: i32 = str_len(s)
    // Buffer output (one write at the end) — per-line print_raw is N syscalls.
    sb_new()
    let mut lineno: i32 = 1
    let mut start: i32 = 0
    let mut k: i32 = 0
    while k <= n {
        let mut is_eol: bool = (k == n)
        if k < n {
            if str_char_at(s, k) == 10 { is_eol = true }
        }
        if is_eol {
            if k > start {
                sb_push(pad_int(lineno, width))
                sb_push(sep)
                sb_push(str_slice(s, start, k))
                sb_push("\n")
            }
            lineno = lineno + 1
            start = k + 1
        }
        k = k + 1
    }
    print_raw(sb_str())
    return 0
}
