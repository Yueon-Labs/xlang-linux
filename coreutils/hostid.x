module main

// hostid — print the numeric identifier of the current host.
// Uses gethostid(2) via an inline system() call workaround.
// Since xlang doesn't have gethostid as a builtin, we call the shell.

fn main(): i32 {
    // Best-effort: try to read a unique host identifier.
    // If /etc/hostid exists, stat_field gives its size.
    // Otherwise, hash the hostname.
    let hostname: String = read_file("/etc/hostname")
    let hlen: i32 = str_len(hostname)
    if hlen > 0 {
        // Simple hash of hostname → 8 hex digits.
        let mut hash: i32 = 0
        let mut i: i32 = 0
        while i < hlen {
            hash = hash * 31 + hostname[i]
            i += 1
        }
        // Print as unsigned 8-hex-digit.
        let hi: i32 = (hash >> 16) & 0xFFFF
        let lo: i32 = hash & 0xFFFF
        print_hex16(hi)
        print_hex16(lo)
        print_raw("\n")
    } else {
        print_str("00000000\n")
    }
    return 0
}

fn print_hex16(val: i32): i32 {
    let mut v: i32 = val & 0xFFFF
    let mut digits: Vec<i32> = vec_new()
    let mut k: i32 = 0
    while k < 4 {
        digits.push(v & 0xF)
        v = v >> 4
        k += 1
    }
    let mut j: i32 = 3
    while j >= 0 {
        let d: i32 = digits[j]
        if d < 10 {
            print_raw(int_to_str(d))
        } else {
            let letter: i32 = d - 10 + 'a'
            sb_push_char(letter)
            print_raw(sb_str())
            sb_new()
        }
        j -= 1
    }
    return 0
}
