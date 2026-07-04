module main

// showall [file] — display all characters including tabs (^I) and line ends ($).
// Like GNU `cat -A`. stdin if no file.
fn main(): i32 {
    let s: String = if argc() >= 2 { read_file(argv(1)) } else { read_stdin() }
    // cat -A = show tabs (^I) AND line-ends ($). Bulk O(n) via cat_show
    // (was a per-char str_char_at loop — the 5.8x Linux gap vs GNU cat -A).
    print_raw(cat_show(s, 1, 1))
    return 0
}
