module main

// patch [-p N] < patchfile — apply a unified diff to the target file named
// in the --- header. In-place (overwrites). Basic unified-diff support:
// --- / +++ / @@ -start,count +start,count @@@ / context (space) / -removed /
// +added / "\ No newline at end of file". No fuzzy matching (exact @@ positions).
// -p N strips N leading path components from the --- filename.

fn main(): i32 {
    let mut strip: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if str_starts_with(a, "-p") {
            strip = str_to_int(str_slice(a, 2, str_len(a)))
        }
        ai = ai + 1
    }

    let patch: String = read_stdin()
    let plines: Vec<String> = str_split(str_trim(patch), "\n")
    let np: i32 = vec_len(plines)

    // Find the target filename from --- header.
    let mut target: String = ""
    let mut found: i32 = 0
    let mut pi: i32 = 0
    while pi < np {
        let pl: String = plines[pi]
        if str_starts_with(pl, "--- ") {
            let rest: String = str_slice(pl, 4, str_len(pl))
            // Strip everything after a tab (timestamp).
            let tab: i32 = str_find(rest, "\t")
            let mut fname: String = rest
            if tab >= 0 {
                fname = str_slice(rest, 0, tab)
            }
            // Strip /dev/null or a/ prefix.
            if str_starts_with(fname, "a/") {
                fname = str_slice(fname, 2, str_len(fname))
            }
            // -p N: strip N path components.
            let mut s: i32 = 0
            while s < strip {
                let sl: i32 = str_find(fname, "/")
                if sl >= 0 {
                    fname = str_slice(fname, sl + 1, str_len(fname))
                }
                s = s + 1
            }
            if str_eq(fname, "/dev/null") == 0 {
                target = fname
                found = 1
            }
            break
        }
        pi = pi + 1
    }

    if found == 0 {
        eprint_str("patch: no --- header found\n")
        return 1
    }

    // Read target file into lines.
    let content: String = read_file(target)
    let target_lines: Vec<String> = str_split(str_trim(content), "\n")
    let nt: i32 = vec_len(target_lines)

    // Apply hunks.
    sb_new()
    let mut tidx: i32 = 0
    let mut pi2: i32 = 0
    while pi2 < np {
        let pl: String = plines[pi2]
        if str_starts_with(pl, "@@") {
            // Parse old start: "@@ -N,..."
            let at: i32 = str_find(pl, "@@ -")
            if at < 0 {
                pi2 = pi2 + 1
                continue
            }
            let mut p: i32 = at + 4
            let mut old_start: i32 = 0
            while p < str_len(pl) {
                let c: i32 = str_char_at(pl, p)
                if c >= 48 {
                    if c <= 57 {
                        old_start = old_start * 10 + (c - 48)
                    }
                }
                if c == 44 { break }
                if c == 32 { break }
                p = p + 1
            }
            if old_start < 1 {
                old_start = 1
            }
            // Copy target lines before this hunk.
            while tidx < old_start - 1 {
                if tidx < nt {
                    sb_push(target_lines[tidx])
                    sb_push("\n")
                }
                tidx = tidx + 1
            }
        } else {
            if str_starts_with(pl, "--- ") == 0 {
                if str_starts_with(pl, "+++ ") == 0 {
                    if str_starts_with(pl, "\\ ") == 0 {
                        if str_starts_with(pl, "diff --git") == 0 {
                            if str_starts_with(pl, "index ") == 0 {
                                if str_len(pl) > 0 {
                                    let c0: i32 = str_char_at(pl, 0)
                                    if c0 == 43 {
                                        // '+' added
                                        sb_push(str_slice(pl, 1, str_len(pl)))
                                        sb_push("\n")
                                    } else {
                                        if c0 == 45 {
                                            // '-' removed: skip target line
                                            tidx = tidx + 1
                                        } else {
                                            if c0 == 32 {
                                                // ' ' context: copy from target
                                                if tidx < nt {
                                                    sb_push(target_lines[tidx])
                                                    sb_push("\n")
                                                }
                                                tidx = tidx + 1
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        pi2 = pi2 + 1
    }
    // Copy remaining target lines.
    while tidx < nt {
        sb_push(target_lines[tidx])
        sb_push("\n")
        tidx = tidx + 1
    }

    write_file(target, sb_str())
    print_raw(target)
    print_raw("\n")
    return 0
}
