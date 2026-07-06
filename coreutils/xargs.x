module main

// xargs [-n N] [-0] <command> [args...] — read whitespace-separated tokens
// from stdin, run <command> with them appended (PATH-based exec).
//   -n N   at most N args per invocation (runs the command multiple times)
//   -0     NUL-delimited tokens (for `find -print0`)
// Default: one invocation with all tokens. Runs via fork + exec_split + wait.


fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: xargs [-n N] [-0] <command> [args...]")
        return 1
    }
    let mut n_max: i32 = 0
    let mut null_delim: i32 = 0
    let base: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-n") {
            i = i + 1
            if i < argc() { n_max = str_to_int(argv(i)) }
            i = i + 1
        } else {
            if str_starts_with(a, "-n") {
                n_max = str_to_int(str_slice(a, 2, str_len(a)))
                i = i + 1
            } else {
                if str_eq(a, "-0") {
                    null_delim = 1
                    i = i + 1
                } else {
                    if str_eq(a, "--") {
                        i = i + 1
                        while i < argc() {
                            base.push(argv(i))
                            i = i + 1
                        }
                    } else {
                        base.push(a)
                        i = i + 1
                    }
                }
            }
        }
    }

    // Base command string (command + initial args), space-joined for exec_split.
    sb_new()
    let mut bi: i32 = 0
    while bi < vec_len(base) {
        if bi > 0 { sb_push(" ") }
        sb_push(base[bi])
        bi = bi + 1
    }
    let base_cmd: String = str_slice(sb_str(), 0, str_len(sb_str()))

    // Tokenize stdin on whitespace (or NUL with -0).
    let text: String = read_stdin()
    let n: i32 = str_len(text)
    let tokens: Vec<String> = vec_new()
    let mut start: i32 = -1
    let mut k: i32 = 0
    while k <= n {
        let mut sep: bool = (k == n)
        if k < n {
            let c: i32 = str_char_at(text, k)
            if null_delim == 1 {
                if c == 0 { sep = true }
            } else {
                if c == 10 || c == 32 || c == 9 || c == 13 { sep = true }
            }
        }
        if sep {
            if start >= 0 {
                tokens.push(str_slice(text, start, k))
                start = -1
            }
        } else {
            if start < 0 { start = k }
        }
        k = k + 1
    }

    let nt: i32 = vec_len(tokens)
    if nt == 0 {
        if vec_len(base) > 0 {
            return exec_split(base_cmd)
        }
        return 0
    }

    let chunk: i32 = if n_max > 0 { n_max } else { nt }
    let mut idx: i32 = 0
    while idx < nt {
        sb_new()
        if str_len(base_cmd) > 0 {
            sb_push(base_cmd)
        }
        let mut j: i32 = idx
        let mut e: i32 = idx + chunk
        if e > nt { e = nt }
        while j < e {
            if str_len(base_cmd) > 0 || j > idx {
                sb_push(" ")
            }
            sb_push(tokens[j])
            j = j + 1
        }
        let cmd: String = sb_str()
        let pid: i32 = fork()
        if pid == 0 {
            exec_split(cmd)
            exit(127)
        } else {
            if pid > 0 {
                wait_child()
            }
        }
        idx = idx + chunk
    }
    return 0
}
