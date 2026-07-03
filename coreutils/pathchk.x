module main

// pathchk [OPTION]... PATH...
//
// Check each PATH for portability/usability problems. Exit status is 0 if
// every path is acceptable, 1 if any has a problem. A faithful subset of GNU
// pathchk.
//
// Options:
//   (none)          check current-system limits: empty name, component
//                   length > 255 (NAME_MAX), total length > 4095 (PATH_MAX)
//   -p              also reject non-portable characters (anything outside
//                   [A-Za-z0-9._-/]) and components longer than 255
//   -P              also reject empty names and components beginning with '-'
//   --portability   equivalent to -p -P
//
// Diagnostics go to stdout (GNU writes them to stderr); on success pathchk
// is silent, matching GNU.

fn is_portable(c: i32): i32 {
    if c >= 48 && c <= 57 {
        return 1
    }
    if c >= 65 && c <= 90 {
        return 1
    }
    if c >= 97 && c <= 122 {
        return 1
    }
    if c == 46 {
        return 1
    }
    if c == 95 {
        return 1
    }
    if c == 45 {
        return 1
    }
    if c == 47 {
        return 1
    }
    return 0
}

fn main(): i32 {
    let mut portable: i32 = 0
    let mut lead_dash: i32 = 0
    let mut opts_done: i32 = 0
    let paths: Vec<String> = vec_new()

    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if opts_done == 1 {
            paths.push(a)
        } else if str_eq(a, "--") {
            opts_done = 1
        } else if str_eq(a, "-p") {
            portable = 1
        } else if str_eq(a, "-P") {
            lead_dash = 1
        } else if str_eq(a, "--portability") {
            portable = 1
            lead_dash = 1
        } else {
            paths.push(a)
        }
        i = i + 1
    }

    let mut rc: i32 = 0
    let np: i32 = vec_len(paths)
    let mut pi: i32 = 0
    while pi < np {
        let p: String = paths[pi]
        let mut reason: String = ""
        let plen: i32 = str_len(p)

        if plen == 0 {
            reason = "empty file name"
        } else {
            // Portable-character check (whole path; '/' is portable).
            if portable == 1 {
                let mut k: i32 = 0
                while k < plen && str_len(reason) == 0 {
                    if is_portable(str_char_at(p, k)) == 0 {
                        reason = "nonportable character"
                    }
                    k = k + 1
                }
            }
            // Per-component checks: leading dash (-P) and length (NAME_MAX).
            let mut cstart: i32 = 0
            let mut k: i32 = 0
            while k <= plen && str_len(reason) == 0 {
                let at_end: bool = k == plen
                let at_sep: bool = k < plen && str_char_at(p, k) == 47
                if at_sep || at_end {
                    let clen: i32 = k - cstart
                    if clen > 0 {
                        if lead_dash == 1 && str_char_at(p, cstart) == 45 {
                            reason = "leading '-' in component"
                        }
                        if clen > 255 {
                            reason = "limit of 255"
                        }
                    }
                    cstart = k + 1
                }
                k = k + 1
            }
            // Total length (PATH_MAX).
            if plen > 4095 {
                reason = "limit of 4095"
            }
        }

        if str_len(reason) > 0 {
            print_raw("pathchk: ")
            print_raw(p)
            print_raw(": ")
            print_raw(reason)
            print_raw("\n")
            rc = 1
        }
        pi = pi + 1
    }
    return rc
}
