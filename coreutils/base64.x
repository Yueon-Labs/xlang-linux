module main

// base64 [-d] — encode (default) or decode (-d) stdin as base64, like GNU base64.
// Encode: 3 bytes -> 4 alphabet chars via sb_push_char (zero-alloc, O(n)).
// Decode: 4 alphabet chars -> 3 bytes; skips newlines / '=' padding.

fn b64_val(c: i32): i32 {
    let mut v: i32 = -1
    if c >= 65 { if c <= 90 { v = c - 65 } }
    if c >= 97 { if c <= 122 { v = c - 97 + 26 } }
    if c >= 48 { if c <= 57 { v = c - 48 + 52 } }
    if c == 43 { v = 62 }
    if c == 47 { v = 63 }
    return v
}

fn main(): i32 {
    let mut decode: bool = false
    let mut wrap: i32 = 76
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-d") {
            decode = true
            i = i + 1
        } else {
            if str_eq(a, "-w") {
                i = i + 1
                if i < argc() { wrap = str_to_int(argv(i)) }
                i = i + 1
            } else {
                if str_starts_with(a, "-w") {
                    wrap = str_to_int(str_slice(a, 2, str_len(a)))
                    i = i + 1
                } else {
                    if str_char_at(a, 0) != 45 {
                        file = a
                    }
                    i = i + 1
                }
            }
        }
    }
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let n: i32 = str_len(s)
    sb_new()
    if decode {
        let mut i: i32 = 0
        let mut quad: i32 = 0
        let mut acc: i32 = 0
        while i < n {
            let v: i32 = b64_val(str_char_at(s, i))
            if v >= 0 {
                acc = (acc << 6) | v
                quad += 1
                if quad == 4 {
                    sb_push_char(acc >> 16)
                    sb_push_char((acc >> 8) & 255)
                    sb_push_char(acc & 255)
                    quad = 0
                    acc = 0
                }
            }
            i += 1
        }
        if quad == 2 {
            sb_push_char((acc >> 4) & 255)
        }
        if quad == 3 {
            sb_push_char((acc >> 10) & 255)
            sb_push_char((acc >> 2) & 255)
        }
    } else {
        let table: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        let mut i: i32 = 0
        while i < n {
            let b0: i32 = str_char_at(s, i)
            let mut b1: i32 = 0
            let mut b2: i32 = 0
            let have1: bool = i + 1 < n
            let have2: bool = i + 2 < n
            if have1 {
                b1 = str_char_at(s, i + 1)
            }
            if have2 {
                b2 = str_char_at(s, i + 2)
            }
            let idx0: i32 = b0 >> 2
            let idx1: i32 = ((b0 & 3) << 4) | (b1 >> 4)
            let idx2: i32 = ((b1 & 15) << 2) | (b2 >> 6)
            let idx3: i32 = b2 & 63
            sb_push_char(str_char_at(table, idx0))
            sb_push_char(str_char_at(table, idx1))
            if have1 {
                sb_push_char(str_char_at(table, idx2))
            } else {
                sb_push_char(61)
            }
            if have2 {
                sb_push_char(str_char_at(table, idx3))
            } else {
                sb_push_char(61)
            }
            i += 3
        }
    }
    if decode {
        print_raw(sb_str())
    } else {
        // Encode wraps at `wrap` columns (default 76); -w0 disables wrapping.
        // Copy the encoded buffer (sb_str points into it) before reusing sb.
        let enc: String = str_slice(sb_str(), 0, str_len(sb_str()))
        if wrap <= 0 {
            print_raw(enc)
            print_raw("\n")
        } else {
            sb_new()
            let en: i32 = str_len(enc)
            let mut p: i32 = 0
            while p < en {
                let mut e: i32 = p + wrap
                if e > en { e = en }
                sb_push_slice(enc, p, e)
                sb_push("\n")
                p = e
            }
            print_raw(sb_str())
        }
    }
    return 0
}
