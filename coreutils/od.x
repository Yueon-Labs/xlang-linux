module main

// od [-A RADIX] [-t TYPE] [file] — dump file contents (GNU od subset).
//   -A d|o|x|n   address radix (default o = octal)
//   -t x1|o1|d1|c  output type (default o1 = octal bytes)
// 16 bytes per line. stdin if no file.

fn oct_str(val: i32, width: i32): String {
    let digits: String = "01234567"
    let mut buf: String = ""
    let mut v: i32 = val
    if v == 0 { buf = "0" }
    while v > 0 {
        buf = str_concat(str_slice(digits, v & 7, (v & 7) + 1), buf)
        v = v >> 3
    }
    let mut result: String = ""
    let pad: i32 = width - str_len(buf)
    let mut pi: i32 = 0
    while pi < pad {
        result = str_concat(result, "0")
        pi = pi + 1
    }
    return str_concat(result, buf)
}

fn hex_str(val: i32, width: i32): String {
    let digits: String = "0123456789abcdef"
    let mut buf: String = ""
    let mut v: i32 = val
    if v == 0 { buf = "0" }
    while v > 0 {
        buf = str_concat(str_slice(digits, v & 15, (v & 15) + 1), buf)
        v = v >> 4
    }
    let mut result: String = ""
    let pad: i32 = width - str_len(buf)
    let mut pi: i32 = 0
    while pi < pad {
        result = str_concat(result, "0")
        pi = pi + 1
    }
    return str_concat(result, buf)
}

fn main(): i32 {
    let mut addr_radix: String = "o"
    let mut out_type: String = "o1"
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let c1: i32 = str_char_at(a, 1)
                if c1 == 65 {
                    if str_len(a) > 2 {
                        addr_radix = str_slice(a, 2, str_len(a))
                    } else {
                        i = i + 1
                        if i < argc() { addr_radix = argv(i) }
                    }
                }
                if c1 == 116 {
                    if str_len(a) > 2 {
                        out_type = str_slice(a, 2, str_len(a))
                    } else {
                        i = i + 1
                        if i < argc() { out_type = argv(i) }
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
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let n: i32 = str_len(s)
    let mut pos: i32 = 0
    while pos < n {
        let end: i32 = pos + 16
        let mut actual_end: i32 = end
        if actual_end > n { actual_end = n }
        if str_eq(addr_radix, "n") == 0 {
            if str_eq(addr_radix, "d") {
                print_raw(int_to_str(pos))
            } else {
                if str_eq(addr_radix, "x") {
                    print_raw(hex_str(pos, 7))
                } else {
                    print_raw(oct_str(pos, 7))
                }
            }
            print_raw(" ")
        }
        let mut k: i32 = pos
        while k < actual_end {
            let b: i32 = str_char_at(s, k)
            if str_eq(out_type, "x1") {
                print_raw(" ")
                print_raw(hex_str(b, 2))
            } else {
                if str_eq(out_type, "d1") {
                    let mut dbuf: String = ""
                    let mut dv: i32 = b
                    if dv == 0 { dbuf = "0" }
                    while dv > 0 {
                        let d: i32 = dv % 10
                        dbuf = str_concat(str_slice("0123456789", d, d + 1), dbuf)
                        dv = dv / 10
                    }
                    let mut dpad: i32 = 5 - str_len(dbuf)
                    while dpad > 0 {
                        dbuf = str_concat(" ", dbuf)
                        dpad = dpad - 1
                    }
                    print_raw(dbuf)
                } else {
                    if str_eq(out_type, "c") {
                        if b >= 32 {
                            if b <= 126 {
                                print_raw("  ")
                                print_raw(chr(b))
                            } else {
                                print_raw("  .")
                            }
                        } else {
                            if b == 10 { print_raw(" \\n") }
                            else {
                                if b == 9 { print_raw(" \\t") }
                                else { print_raw("  .") }
                            }
                        }
                        print_raw(" ")
                    } else {
                        print_raw(" ")
                        print_raw(oct_str(b, 3))
                    }
                }
            }
            k = k + 1
        }
        print_raw("\n")
        pos = pos + 16
    }
    return 0
}

