module main

// timeout <duration_s> <command...> — run <command>, kill it if it runs longer
// than <duration_s> seconds (mini GNU timeout).
//
// Model: fork the command; fork a timer child that sleeps <duration>, then
// SIGTERM the command (and SIGKILL after a 1s grace). The parent waits
// specifically for the command (wait_pid_status), then kills+reaps the timer.
// Returns the command's exit status (128+signo if it was killed by the timer,
// shell convention). Requires xlang wait_pid_status builtin.

fn main(): i32 {
    if argc() < 3 {
        eprint_str("usage: timeout <duration_s> <command...>")
        return 1
    }
    let duration: i32 = str_to_int(argv(1))

    // Build the command string from argv(2..).
    sb_new()
    let mut i: i32 = 2
    while i < argc() {
        if i > 2 { sb_push(" ") }
        sb_push(argv(i))
        i = i + 1
    }
    let cmd: String = sb_str()

    // Child that runs the command.
    let cmdpid: i32 = fork()
    if cmdpid == 0 {
        exec_split(cmd)
        print_str("timeout: failed to exec")
        return 127
    }
    if cmdpid < 0 {
        print_str("timeout: fork failed")
        return 1
    }

    // Timer child: sleep, then escalate SIGTERM -> SIGKILL.
    let timerpid: i32 = fork()
    if timerpid == 0 {
        sleep_sec(duration)
        kill(cmdpid, 15)
        sleep_sec(1)
        kill(cmdpid, 9)
        return 0
    }

    // Parent: wait for the command (it exits normally or when the timer kills
    // it), then clean up the timer.
    let status: i32 = wait_pid_status(cmdpid)
    kill(timerpid, 9)
    wait_pid_status(timerpid)
    return status
}
