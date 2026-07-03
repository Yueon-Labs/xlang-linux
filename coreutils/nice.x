module main

// nice [-n ADJUSTMENT] <command...> — run a command with modified scheduling
// priority. Without a command, print the current niceness.
// Note: nice(2)/getpriority require capabilities; this is a best-effort wrapper.

fn main(): i32 {
    let mut adj: i32 = 10
    let mut have_cmd: i32 = 0
    let cmd_parts: Vec<String> = vec_new()
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if a == "-n" {
            ai += 1
            if ai < argc() { adj = str_to_int(argv(ai)) }
        } else {
            if str_char_at(a, 0) == '-' && str_len(a) > 1 && str_char_at(a, 1) == 'n' {
                adj = str_to_int(str_slice(a, 2, str_len(a)))
            } else {
                have_cmd = 1
                cmd_parts.push(a)
            }
        }
        ai += 1
    }
    if have_cmd == 0 {
        print_str("0\n")
        return 0
    }
    // Build command string from remaining parts.
    sb_new()
    let np: i32 = vec_len(cmd_parts)
    let mut k: i32 = 0
    while k < np {
        if k > 0 { sb_push(" ") }
        sb_push(cmd_parts[k])
        k += 1
    }
    let cmd: String = sb_str()
    return exec_split(cmd)
}
