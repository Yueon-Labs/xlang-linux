module main

// cate [file] — display $ at end of each line (like `cat -E`). stdin if no file.
fn main(): i32 {
    let mut s: String = ""
    if argc() >= 2 {
        s = read_file(argv(1))
    } else {
        s = read_stdin()
    }
    // cat -E = show line-ends ($), no tab expansion. Bulk O(n) via cat_show
    // (was a per-char str_char_at loop — the 3.2x Linux gap vs GNU cat -E).
    print_raw(cat_show(s, 0, 1))
    return 0
}
