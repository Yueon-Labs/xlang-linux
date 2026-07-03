module main

// strings [-n LEN] <file> — find printable strings (default len >= 4) in a
// binary file. Uses read_rbuf (binary-safe, handles NUL bytes) + rbuf_byte_at
// (direct byte access, not strlen-limited). Scans in 64 KB chunks.

fn main(): i32 {
    let mut min_len: i32 = 4
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                if str_char_at(a, 1) == 110 {
                    if str_len(a) > 2 {
                        min_len = str_to_int(str_slice(a, 2, str_len(a)))
                    } else {
                        i = i + 1
                        if i < argc() { min_len = str_to_int(argv(i)) }
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
    if str_len(file) == 0 {
        eprint_str("usage: strings [-n LEN] <file>")
        return 1
    }
    let fd: i32 = open_read(file)
    if fd < 0 {
        print_str("strings: cannot open file")
        return 1
    }
    sb_new()
    let mut run_start: i32 = -1
    while true {
        let n: i32 = read_rbuf(fd)
        if n == 0 { break }
        let mut k: i32 = 0
        while k < n {
            let c: i32 = rbuf_byte_at(k)
            let mut printable: i32 = 0
            if c >= 32 { if c <= 126 { printable = 1 } }
            if printable == 1 {
                if run_start < 0 { run_start = 0 }
                sb_push_char(c)
            } else {
                if str_len(sb_str()) >= min_len {
                    print_raw(sb_str())
                    print_raw("\n")
                }
                sb_new()
                run_start = -1
            }
            k = k + 1
        }
    }
    if str_len(sb_str()) >= min_len {
        print_raw(sb_str())
        print_raw("\n")
    }
    close_fd(fd)
    return 0
}
