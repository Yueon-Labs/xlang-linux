module main

// unexpand [-a] [-t N] [file] — convert spaces to tabs (GNU unexpand).
//   -a   convert ALL runs of 2+ spaces at tab stops (not just leading)
//   -t N  tab stop width (default 8)
// Default (no -a): only leading whitespace is converted. stdin if no file.

fn main(): i32 {
    let mut tabstop: i32 = 8
    let mut convert_all: i32 = 0
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    let c: i32 = str_char_at(a, j)
                    if c == 97 { convert_all = 1 }
                    if c == 116 {
                        if j + 1 < str_len(a) {
                            tabstop = str_to_int(str_slice(a, j + 1, str_len(a)))
                            j = str_len(a)
                        } else {
                            i = i + 1
                            if i < argc() { tabstop = str_to_int(argv(i)) }
                        }
                    }
                    j = j + 1
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
    if tabstop < 1 { tabstop = 1 }
    let mut s: String = ""
    if str_len(file) > 0 {
        s = read_file(file)
    } else {
        s = read_stdin()
    }
    // Buffer the whole output and write once (per-char print_raw is N mallocs
    // + N syscalls — the fold trap). Output size ~ input size, so safe.
    sb_new()
    let n: i32 = str_len(s)
    let mut k: i32 = 0
    let mut col: i32 = 0
    let mut at_line_start: i32 = 1
    let mut pending_spaces: i32 = 0
    while k < n {
        let c: i32 = str_char_at(s, k)
        if c == 32 {
            pending_spaces = pending_spaces + 1
            col = col + 1
            if col % tabstop == 0 {
                let mut do_convert: i32 = 0
                if convert_all == 1 {
                    do_convert = 1
                } else {
                    if at_line_start == 1 {
                        do_convert = 1
                    }
                }
                if do_convert == 1 {
                    if pending_spaces >= 2 {
                        sb_push_char(9)
                    } else {
                        let mut sp: i32 = 0
                        while sp < pending_spaces {
                            sb_push_char(32)
                            sp = sp + 1
                        }
                    }
                    pending_spaces = 0
                }
            }
        } else {
            let mut sp: i32 = 0
            while sp < pending_spaces {
                sb_push_char(32)
                sp = sp + 1
            }
            pending_spaces = 0
            sb_push_char(c)
            if c == 10 {
                col = 0
                at_line_start = 1
            } else {
                col = col + 1
                at_line_start = 0
            }
        }
        k = k + 1
    }
    let mut sp: i32 = 0
    while sp < pending_spaces {
        sb_push_char(32)
        sp = sp + 1
    }
    print_raw(sb_str())
    return 0
}
