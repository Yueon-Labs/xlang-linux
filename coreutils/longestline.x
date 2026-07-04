module main

// longestline [file] — print the length of the longest line (like `wc -L`).
// stdin if no file.
fn main(): i32 {
    let s: String = if argc() >= 2 { read_file(argv(1)) } else { read_stdin() }
    let n: i32 = str_len(s)
    let mut max: i32 = 0
    let mut cur: i32 = 0
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c == 10 {
            if cur > max {
                max = cur
            }
            cur = 0
        } else {
            cur += 1
        }
        i += 1
    }
    if cur > max {
        max = cur
    }
    print_i32(max)
    print_raw("\n")
    return 0
}
