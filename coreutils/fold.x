module main

// fold [-w N] [file] — wrap lines at N columns (default 80). GNU -w flag.
fn main(): i32 {
    let mut width: i32 = 80
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
                    if i < argc() {
                        width = str_to_int(argv(i))
                    }
                }
            }
        } else {
            file = a
        }
        i = i + 1
    }
    let mut s: String = ""
    if str_len(file) > 0 {
        s = read_file(file)
    } else {
        s = read_stdin()
    }
    let n: i32 = str_len(s)
    // Buffer the whole output in a StringBuilder and write once. Writing per
    // char (print_raw of a 1-byte str_slice) is N mallocs + N write syscalls —
    // ~10× slower than GNU. The builder amortizes realloc, so this is O(n).
    sb_new()
    let mut col: i32 = 0
    let mut k: i32 = 0
    while k < n {
        let c: i32 = str_char_at(s, k)
        sb_push_char(c)
        if c == 10 {
            col = 0
        } else {
            col = col + 1
            if col >= width {
                let next_is_nl: bool = (k + 1 < n) && (str_char_at(s, k + 1) == 10)
                if !next_is_nl {
                    sb_push_char(10)
                }
                col = 0
            }
        }
        k = k + 1
    }
    print_raw(sb_str())
    return 0
}
