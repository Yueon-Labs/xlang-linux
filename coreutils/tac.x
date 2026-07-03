module main

// tac [file] — print lines in reverse order (like GNU tac). stdin if no file.
fn main(): i32 {
    let mut s: String = ""
    if argc() >= 2 {
        s = read_file(argv(1))
    } else {
        s = read_stdin()
    }
    let n: i32 = str_len(s)
    let lines: Vec<String> = vec_new()
    let mut start: i32 = 0
    // Bulk newline scan via str_find_from (strchr — fast on all platforms).
    while true {
        let nl: i32 = str_find_from(s, "\n", start)
        if nl < 0 {
            if start < n {
                lines.push(str_slice(s, start, n))
            }
            break
        }
        lines.push(str_slice(s, start, nl))
        start = nl + 1
    }
    let count: i32 = vec_len(lines)
    // Buffer output (one write) — per-line print_raw is N syscalls.
    sb_new()
    let mut k: i32 = count - 1
    while k >= 0 {
        sb_push(lines[k])
        sb_push("\n")
        k -= 1
    }
    print_raw(sb_str())
    return 0
}
