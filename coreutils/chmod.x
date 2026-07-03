module main

// chmod <mode> <file>... — change file permissions (GNU chmod).
//   Octal mode:   chmod 755 file
//   Symbolic:     chmod u+x file    chmod go-w file    chmod a=r file
//   Multiple files supported.
// Uses the chmod builtin (mode, path) for octal. Symbolic mode computes the
// new mode from the current stat.

fn current_mode(path: String): i32 {
    return stat_field(path, 0) & 4095
}

// Apply a symbolic mode clause (e.g. "u+x", "go-w", "a=r") to the current mode.
fn apply_symbolic(cur: i32, clause: String): i32 {
    let n: i32 = str_len(clause)
    let mut who: i32 = 0
    let mut pos: i32 = 0
    // Parse "who" (u/g/o/a)
    while pos < n {
        let c: i32 = str_char_at(clause, pos)
        if c == 117 { who = who | 128 }
        else {
            if c == 103 { who = who | 16 }
            else {
                if c == 111 { who = who | 2 }
                else {
                    if c == 97 { who = 146 }
                    else { break }
                }
            }
        }
        pos = pos + 1
    }
    if who == 0 { who = 146 }
    // Parse op (+/-/=)
    if pos >= n { return cur }
    let op: i32 = str_char_at(clause, pos)
    pos = pos + 1
    // Build permission bits from permission chars
    let mut perm: i32 = 0
    while pos < n {
        let c: i32 = str_char_at(clause, pos)
        if c == 114 { perm = perm | 4 }
        else {
            if c == 119 { perm = perm | 2 }
            else {
                if c == 120 { perm = perm | 1 }
                else { break }
            }
        }
        pos = pos + 1
    }
    // Expand who into the three permission classes
    let mut mask: i32 = 0
    if (who & 128) != 0 { mask = mask | (perm << 6) }
    if (who & 16) != 0 { mask = mask | (perm << 3) }
    if (who & 2) != 0 { mask = mask | perm }
    if op == 43 { return cur | mask }
    if op == 45 { return cur & (~mask) }
    if op == 61 {
        let mut clear: i32 = 0
        if (who & 128) != 0 { clear = clear | 448 }
        if (who & 16) != 0 { clear = clear | 56 }
        if (who & 2) != 0 { clear = clear | 7 }
        return (cur & (~clear)) | mask
    }
    return cur
}

fn main(): i32 {
    if argc() < 3 {
        eprint_str("usage: chmod <mode> <file>...")
        return 1
    }
    let mode_str: String = argv(1)
    let files: Vec<String> = vec_new()
    let mut i: i32 = 2
    while i < argc() {
        files.push(argv(i))
        i = i + 1
    }
    let nf: i32 = vec_len(files)

    // Determine if mode is octal or symbolic.
    let mut is_octal: bool = true
    let mlen: i32 = str_len(mode_str)
    let mut mi: i32 = 0
    while mi < mlen {
        let c: i32 = str_char_at(mode_str, mi)
        if c < 48 { is_octal = false }
        if c > 55 { is_octal = false }
        mi = mi + 1
    }

    let mut rc: i32 = 0
    let mut k: i32 = 0
    while k < nf {
        if is_octal {
            let oct_mode: i32 = str_to_int_oct(mode_str)
            if chmod(files[k], oct_mode) != 0 { rc = 1 }
        } else {
            let cur: i32 = current_mode(files[k])
            let new_mode: i32 = apply_symbolic(cur, mode_str)
            if chmod(files[k], new_mode) != 0 { rc = 1 }
        }
        k = k + 1
    }
    return rc
}
