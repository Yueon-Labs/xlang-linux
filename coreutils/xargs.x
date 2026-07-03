module main

// xargs <command> [initial-args...] — read whitespace-separated tokens from
// stdin, append them as arguments to <command>, and run it. The classic
// pipeline tool: find . -name "*.x" | xargs grep foo
// Runs the command via exec_split (PATH-based). Replaces the process on success.

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: xargs <command> [args...]")
        return 1
    }
    // Build the command: initial args from argv, then stdin tokens appended.
    sb_new()
    let mut i: i32 = 1
    while i < argc() {
        if i > 1 { sb_push(" ") }
        sb_push(argv(i))
        i = i + 1
    }
    // Read stdin, split on whitespace/newlines, append each token.
    let text: String = read_stdin()
    let n: i32 = str_len(text)
    let mut k: i32 = 0
    let mut word_start: i32 = -1
    while k <= n {
        let mut is_sep: bool = (k == n)
        if k < n {
            let c: i32 = str_char_at(text, k)
            if c == 10 || c == 32 || c == 9 || c == 13 { is_sep = true }
        }
        if is_sep {
            if word_start >= 0 {
                sb_push(" ")
                sb_push(str_slice(text, word_start, k))
                word_start = -1
            }
        } else {
            if word_start < 0 { word_start = k }
        }
        k = k + 1
    }
    let cmd: String = sb_str()
    if str_len(cmd) == 0 { return 0 }
    return exec_split(cmd)
}
