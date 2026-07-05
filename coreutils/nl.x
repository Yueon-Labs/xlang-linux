module main

// nl [-ba|-bt|-bn] [-w WIDTH] [-s SEP] [-n rn|rz] [file] — number lines (GNU nl).
//   -bt  number non-empty body lines, show empty lines with a blank number
//        field and DON'T increment the counter (DEFAULT)
//   -ba  number all lines
//   -bn  number no lines
//   -w N   number field width (default 6)
//   -s SEP separator after the number field (default tab)
//   -n FORMAT  rn = right-justified space-pad (default), rz = zero-pad
// stdin if no file.


fn main(): i32 {
    let mut width: i32 = 6
    let mut sep: String = "\t"
    // body mode: 1 = -bt (non-empty, default), 2 = -ba (all), 0 = -bn (none)
    let mut body: i32 = 1
    let mut zeropad: i32 = 0
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let c1: i32 = str_char_at(a, 1)
                // -b TYPE  /  -n FORMAT  take an attached value or the next arg.
                if c1 == 98 {
                    let mut bt: String = ""
                    if str_len(a) > 2 {
                        bt = str_slice(a, 2, str_len(a))
                    } else {
                        i = i + 1
                        if i < argc() { bt = argv(i) }
                    }
                    if str_eq(bt, "a") { body = 2 }
                    if str_eq(bt, "t") { body = 1 }
                    if str_eq(bt, "n") { body = 0 }
                    i = i + 1
                } else {
                    if c1 == 110 {
                        let mut nf: String = ""
                        if str_len(a) > 2 {
                            nf = str_slice(a, 2, str_len(a))
                        } else {
                            i = i + 1
                            if i < argc() { nf = argv(i) }
                        }
                        if str_eq(nf, "rz") { zeropad = 1 }
                        i = i + 1
                    } else {
                        if c1 == 119 {
                            if str_len(a) > 2 {
                                width = str_to_int(str_slice(a, 2, str_len(a)))
                            } else {
                                i = i + 1
                                if i < argc() { width = str_to_int(argv(i)) }
                            }
                            i = i + 1
                        } else {
                            if c1 == 115 {
                                if str_len(a) > 2 {
                                    sep = str_slice(a, 2, str_len(a))
                                } else {
                                    i = i + 1
                                    if i < argc() { sep = argv(i) }
                                }
                                i = i + 1
                            } else {
                                i = i + 1
                            }
                        }
                    }
                }
            } else {
                file = a
                i = i + 1
            }
        } else {
            file = a
            i = i + 1
        }
    }
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let n: i32 = str_len(s)
    // Buffer output (one write at the end) — per-line print_raw is N syscalls.
    sb_new()
    let mut lineno: i32 = 1
    let mut start: i32 = 0
    // Bulk newline scan via str_find_from (strchr — fast on all platforms).
    while true {
        let nl: i32 = str_find_from(s, "\n", start)
        let mut line_end: i32 = n
        if nl >= 0 {
            line_end = nl
        }
        // A line exists at [start, line_end): newline-terminated (even if empty),
        // or trailing content at EOF. A final newline yields no phantom empty line.
        let mut has_line: i32 = 0
        if nl >= 0 {
            has_line = 1
        } else {
            if start < n {
                has_line = 1
            }
        }
        if has_line == 0 {
            break
        }
        let mut nonempty: i32 = 0
        if line_end > start {
            nonempty = 1
        }
        // Number this line? -ba⇒all, -bt(default)⇒non-empty, -bn⇒none.
        let mut numbered: i32 = 0
        if body == 2 {
            numbered = 1
        } else {
            if body == 1 {
                numbered = nonempty
            }
        }
        if numbered == 1 {
            if zeropad == 1 {
                sb_push(pad_zero(lineno, width))
            } else {
                sb_push_i32_pad(lineno, width)
            }
            lineno = lineno + 1
            sb_push(sep)
        } else {
            // Unnumbered line: blank number field (width) + the separator
            // blanked to spaces (seplen) — GNU prints no actual separator
            // for lines it doesn't number.
            let total: i32 = width + str_len(sep)
            let mut w: i32 = 0
            while w < total {
                sb_push(" ")
                w = w + 1
            }
        }
        sb_push_slice(s, start, line_end)
        sb_push("\n")
        if nl < 0 {
            break
        }
        start = nl + 1
    }
    print_raw(sb_str())
    return 0
}
