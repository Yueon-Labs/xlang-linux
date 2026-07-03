module main

// cate [file] — display $ at end of each line (like `cat -E`). stdin if no file.
fn main(): i32 {
    let mut s: String = ""
    if argc() >= 2 {
        s = read_file(argv(1))
    } else {
        s = read_stdin()
    }
    // Buffer the whole output and write once. Per-char print_raw is N mallocs
    // + N write syscalls (the same trap fold had); the builder is amortized O(n).
    sb_new()
    let n: i32 = str_len(s)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c == 10 {
            sb_push("$\n")
        } else {
            sb_push_char(c)
        }
        i += 1
    }
    print_raw(sb_str())
    return 0
}
