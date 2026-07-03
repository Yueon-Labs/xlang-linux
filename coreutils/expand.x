module main

// expand [-t N] [file] — convert tabs to spaces (GNU expand).
//   -t N   tab stop width (default 8)
// stdin if no file.
fn main(): i32 {
    let mut tabstop: i32 = 8
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let c1: i32 = str_char_at(a, 1)
                if c1 == 116 {
                    if str_len(a) > 2 {
                        tabstop = str_to_int(str_slice(a, 2, str_len(a)))
                    } else {
                        i = i + 1
                        if i < argc() { tabstop = str_to_int(argv(i)) }
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
    while k < n {
        let c: i32 = str_char_at(s, k)
        if c == 9 {
            let spaces: i32 = tabstop - (col % tabstop)
            let mut j: i32 = 0
            while j < spaces {
                sb_push_char(32)
                j = j + 1
            }
            col = col + spaces
        } else {
            sb_push_char(c)
            if c == 10 {
                col = 0
            } else {
                col = col + 1
            }
        }
        k = k + 1
    }
    print_raw(sb_str())
    return 0
}

