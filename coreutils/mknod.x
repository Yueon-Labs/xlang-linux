module main

// mknod <name> <type> <major> <minor> — create a special file (device node,
// named pipe, or regular file). Requires root for device nodes.

fn main(): i32 {
    if argc() < 3 {
        eprint_str("usage: mknod <name> <type> [major minor]\n")
        return 1
    }
    let name: String = argv(1)
    let typ: String = argv(2)
    let c: i32 = str_char_at(typ, 0)
    if c == 'p' {
        // FIFO (named pipe)
        let rc: i32 = make_fifo(name)
        if rc != 0 {
            eprint_str("mknod: cannot create '")
            eprint_str(name)
            eprint_str("'\n")
            return 1
        }
        return 0
    }
    if c == 'c' || c == 'b' {
        if argc() < 5 {
            eprint_str("mknod: device nodes require major and minor numbers\n")
            return 1
        }
        let maj: i32 = str_to_int(argv(3))
        let min: i32 = str_to_int(argv(4))
        let mut mode: i32 = 0600
        if c == 'b' { mode = mode | 010666 } else { mode = mode | 020666 }
        let rc: i32 = mknod_dev(name, mode, maj, min)
        if rc != 0 {
            eprint_str("mknod: cannot create device '")
            eprint_str(name)
            eprint_str("' (requires root)\n")
            return 1
        }
        return 0
    }
    eprint_str("mknod: invalid type '")
    eprint_str(typ)
    eprint_str("' (use p, c, or b)\n")
    return 1
}
