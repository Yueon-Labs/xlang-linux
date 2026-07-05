module main

// split [-l LINES] [-b BYTES] [-a N] [-d] [INPUT [PREFIX]]
// Split INPUT into chunks. Default: 1000 lines/file, prefix "x", 2-letter
// alphabetic suffixes (aa, ab, ..., az, ba, ...).
//   -l N   N lines per file
//   -b N   N bytes per file (k/M/G/t suffixes ×1024)
//   -a N   suffix length (default 2)
//   -d     numeric suffixes (00, 01, ...)
// INPUT "-" or absent → stdin.


fn suffix_for(fnum: i32, len: i32, numeric: i32): String {
    let letters: String = "abcdefghijklmnopqrstuvwxyz"
    let mut tmp: Vec<i32> = vec_new()
    let mut v: i32 = fnum
    if v == 0 { tmp.push(0) }
    while v > 0 {
        if numeric == 1 {
            tmp.push(v % 10)
            v = v / 10
        } else {
            tmp.push(v % 26)
            v = v / 26
        }
    }
    let cnt: i32 = vec_len(tmp)
    let mut s: String = ""
    let mut pad: i32 = len - cnt
    while pad > 0 {
        if numeric == 1 {
            s = str_concat(s, "0")
        } else {
            s = str_concat(s, "a")
        }
        pad = pad - 1
    }
    let mut i: i32 = cnt - 1
    while i >= 0 {
        let d: i32 = tmp[i]
        if numeric == 1 {
            s = str_concat(s, str_slice("0123456789", d, d + 1))
        } else {
            s = str_concat(s, str_slice(letters, d, d + 1))
        }
        i = i - 1
    }
    return s
}

fn main(): i32 {
    let mut lines_per: i32 = 1000
    let mut bytes_per: i32 = 0
    let mut suffix_len: i32 = 2
    let mut numeric: i32 = 0
    let mut input: String = ""
    let mut prefix: String = "x"
    let mut have_prefix: i32 = 0
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if a == "-l" {
            i = i + 1
            if i < argc() { lines_per = str_to_int(argv(i)) }
            i = i + 1
        } else {
            if str_starts_with(a, "-l") {
                lines_per = str_to_int(str_slice(a, 2, str_len(a)))
                i = i + 1
            } else {
                if a == "-b" {
                    i = i + 1
                    if i < argc() { bytes_per = parse_bytes(argv(i)) }
                    i = i + 1
                } else {
                    if str_starts_with(a, "-b") {
                        bytes_per = parse_bytes(str_slice(a, 2, str_len(a)))
                        i = i + 1
                    } else {
                        if a == "-a" {
                            i = i + 1
                            if i < argc() { suffix_len = str_to_int(argv(i)) }
                            i = i + 1
                        } else {
                            if str_starts_with(a, "-a") {
                                suffix_len = str_to_int(str_slice(a, 2, str_len(a)))
                                i = i + 1
                            } else {
                                if a == "-d" {
                                    numeric = 1
                                    i = i + 1
                                } else {
                                    if have_prefix == 0 {
                                        if input == "" {
                                            input = a
                                        } else {
                                            prefix = a
                                            have_prefix = 1
                                        }
                                    }
                                    i = i + 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if suffix_len < 1 { suffix_len = 1 }
    let s: String = if str_len(input) > 0 && input != "-" { read_file(input) } else { read_stdin() }
    let n: i32 = str_len(s)
    let mut fnum: i32 = 0
    if bytes_per > 0 {
        // Byte mode.
        let mut cs: i32 = 0
        let mut k: i32 = 0
        while k < n {
            if k - cs + 1 >= bytes_per {
                write_file(str_concat(prefix, suffix_for(fnum, suffix_len, numeric)), str_slice(s, cs, k + 1))
                fnum = fnum + 1
                cs = k + 1
            }
            k = k + 1
        }
        if cs < n {
            write_file(str_concat(prefix, suffix_for(fnum, suffix_len, numeric)), str_slice(s, cs, n))
        }
    } else {
        // Line mode.
        if lines_per < 1 { lines_per = 1 }
        let mut lc: i32 = 0
        let mut cs: i32 = 0
        let mut k: i32 = 0
        while k < n {
            if str_char_at(s, k) == 10 {
                lc = lc + 1
                if lc >= lines_per {
                    write_file(str_concat(prefix, suffix_for(fnum, suffix_len, numeric)), str_slice(s, cs, k + 1))
                    fnum = fnum + 1
                    lc = 0
                    cs = k + 1
                }
            }
            k = k + 1
        }
        if cs < n {
            write_file(str_concat(prefix, suffix_for(fnum, suffix_len, numeric)), str_slice(s, cs, n))
        }
    }
    return 0
}

fn parse_bytes(spec: String): i32 {
    let n: i32 = str_len(spec)
    if n == 0 { return 0 }
    let last: i32 = str_char_at(spec, n - 1)
    let num: i32 = str_to_int(spec)
    if last == 107 { return num * 1024 }
    if last == 75 { return num * 1000 }
    if last == 109 { return num * 1024 * 1024 }
    if last == 77 { return num * 1000 * 1000 }
    if last == 103 { return num * 1024 * 1024 * 1024 }
    if last == 71 { return num * 1000 * 1000 * 1000 }
    return num
}
