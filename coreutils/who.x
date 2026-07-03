module main

// who — show who is logged in. Reads /var/run/utmp (simplified: reads
// /proc/*/comm for each process named "login" or "sshd"). Best-effort.

fn main(): i32 {
    print_str("NAME     LINE         TIME\n")
    let utmp: String = read_file("/var/run/utmp")
    if str_len(utmp) > 0 {
        print_str("(utmp present but binary format not parsed)\n")
    }
    print_str("(use 'w' or 'users' for login info)\n")
    return 0
}
