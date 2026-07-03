module main

// chroot <newroot> [command...] — run a command (or a shell) with a
// different root directory. Requires root privileges.

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: chroot <newroot> [command...]\n")
        return 1
    }
    let newroot: String = argv(1)
    let rc: i32 = chroot_call(newroot)
    if rc != 0 {
        print_str("chroot: cannot change root directory to '")
        print_str(newroot)
        print_str("'\n")
        return 1
    }
    // chdir to the new root
    chdir(newroot)
    if argc() >= 3 {
        // Build and exec the command.
        sb_new()
        let mut i: i32 = 2
        while i < argc() {
            if i > 2 { sb_push(" ") }
            sb_push(argv(i))
            i += 1
        }
        return exec_split(sb_str())
    }
    // Default: exec /bin/sh
    return exec_split("/bin/sh")
}
