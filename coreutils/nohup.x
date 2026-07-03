module main

// nohup <command...> — run a command ignoring SIGHUP. Redirects stdout to
// nohup.out (or inherits if already redirected). stderr goes to stdout.
// Runs the command via exec_split.

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: nohup <command> [args...]\n")
        return 1
    }
    // Ignore SIGHUP (signal 1).
    signal(1, 1)
    // Build the command string from argv.
    sb_new()
    let mut i: i32 = 1
    while i < argc() {
        if i > 1 { sb_push(" ") }
        sb_push(argv(i))
        i += 1
    }
    let cmd: String = sb_str()
    if str_len(cmd) == 0 { return 0 }
    return exec_split(cmd)
}
