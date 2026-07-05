module main

// fold [-w N] [-s] [file] — wrap lines at N columns (default 80).
//   -w N   column width
//   -s     break at the last blank within the width (not mid-word)
// Operates per input line; preserves line terminators.


fn main(): i32 {
    let mut width: i32 = 80
    let mut want_s: i32 = 0
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        let c0: i32 = str_char_at(a, 0)
        if c0 == 45 {
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
                want_s = 1
            }
        } else {
            file = a
        }
        i = i + 1
    }
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let n: i32 = str_len(s)
    if width < 1 { width = 1 }
    sb_new()
    let mut lstart: i32 = 0
    let mut k: i32 = 0
    while k <= n {
        let at_nl: bool = k < n && str_char_at(s, k) == 10
        let at_end: bool = k == n && lstart < n
        if at_nl || at_end {
            let line_end: i32 = k
            let mut seg: i32 = lstart
            while seg < line_end {
                let mut send: i32 = seg + width
                if send > line_end { send = line_end }
                let mut broke_s: i32 = 0
                if want_s == 1 && send < line_end {
                    let mut ls: i32 = -1
                    let mut q: i32 = send - 1
                    while q >= seg {
                        let ch: i32 = str_char_at(s, q)
                        if ch == 32 || ch == 9 {
                            ls = q
                            break
                        }
                        q = q - 1
                    }
                    if ls >= seg {
                        sb_push_slice(s, seg, ls + 1)
                        seg = ls + 1
                        broke_s = 1
                    }
                }
                if broke_s == 0 {
                    sb_push_slice(s, seg, send)
                    seg = send
                }
                if seg < line_end {
                    sb_push_char(10)
                }
            }
            if at_nl {
                sb_push_char(10)
            }
            lstart = k + 1
        }
        k = k + 1
    }
    print_raw(sb_str())
    return 0
}
