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
    // cat -A = show tabs (^I) AND line-ends ($). Bulk O(n) via cat_show
    // (was a per-char str_char_at loop — the 5.8x Linux gap vs GNU cat -A).
    print_raw(cat_show(s, 1, 1))
    return 0
}
