module main

// stdbuf -o{0,L,S} -i{0,L,S} -e{0,S} <command...> — run a command with
// modified stdio buffering. Without LD_PRELOAD we can't actually change a
// child's buffering, so this is a wrapper that flushes our own buffers
// and execs the command. Best-effort compatibility.

fn main(): i32 {
    if argc() < 2 {
        print_str("usage: stdbuf [-o0|-oL|-oS] ... <command>\n")
        return 1
    }
    let cmd_parts: Vec<String> = vec_new()
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if str_char_at(a, 0) == '-' && str_len(a) >= 2 {
            // Accept and ignore buffering options (-o0, -oL, -oS, -i0, -e0, etc.)
        } else {
            cmd_parts.push(a)
        }
        ai += 1
    }
    if cmd_parts.len() == 0 {
        print_str("stdbuf: no command given\n")
        return 1
    }
    // Flush stdout, then exec the command.
    print_raw("")
    sb_new()
    let mut k: i32 = 0
    while k < cmd_parts.len() {
        if k > 0 { sb_push(" ") }
        sb_push(cmd_parts[k])
        k += 1
    }
    return exec_split(sb_str())
}
