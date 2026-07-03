module main

// showall [file] — display all characters including tabs (^I) and line ends ($).
// Like GNU `cat -A`. stdin if no file.
fn main(): i32 {
    let mut s: String = ""
    if argc() >= 2 {
        s = read_file(argv(1))
    } else {
        s = read_stdin()
    }
    // Buffer the whole output and write once (per-char print_raw is N mallocs
    // + N syscalls — the fold trap).
    sb_new()
    let n: i32 = str_len(s)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c == 9 {
            sb_push("^I")
        } else {
            if c == 10 {
                sb_push("$\n")
            } else {
                sb_push_char(c)
            }
        }
        i += 1
    }
    print_raw(sb_str())
    return 0
}
