module main

// runcon <context> <command...> — run a command with a specified SELinux
// security context. Without SELinux support, this is a no-op wrapper.

fn main(): i32 {
    if argc() < 3 {
        print_str("usage: runcon <context> <command> [args...]\n")
        return 1
    }
    // Build command from argv(2..).
    sb_new()
    let mut i: i32 = 2
    while i < argc() {
        if i > 2 { sb_push(" ") }
        sb_push(argv(i))
        i += 1
    }
    // Context (argv(1)) is accepted but ignored (no SELinux without LD_PRELOAD).
    return exec_split(sb_str())
}
