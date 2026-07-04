module main

fn main(): i32 {
    let mut file: String = ""
    if argc() >= 2 {
        file = argv(1)
    }
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    print_raw(sha224_hex(s))
    print_raw("  ")
    if str_len(file) > 0 {
        print_raw(file)
    } else {
        print_raw("-")
    }
    print_raw("\n")
    return 0
}
