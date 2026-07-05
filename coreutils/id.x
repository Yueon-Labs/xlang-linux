module main

// id [user] — print user identity (GNU id).
// Without args: prints the REAL uid/gid/groups of the current process.
// With a username arg: prints that user's identity from /etc/passwd + /etc/group.

fn parse_id(s: String): i32 {
    let n: i32 = str_len(s)
    if n == 0 { return -1 }
    let mut i: i32 = 0
    if str_char_at(s, 0) == 45 {
        if n == 1 { return -1 }
        i = 1
    }
    let mut v: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c < 48 { break }
        if c > 57 { break }
        v = v * 10 + (c - 48)
        i = i + 1
    }
    return v
}

fn lookup_name_by_uid(target_uid: i32): String {
    let pw: String = read_file("/etc/passwd")
    let lines: Vec<String> = str_split(str_trim(pw), "\n")
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let parts: Vec<String> = split_on(lines[i], 58)
        if vec_len(parts) >= 3 {
            let uid: i32 = parse_id(parts[2])
            if uid == target_uid {
                return parts[0]
            }
        }
        i = i + 1
    }
    return ""
}

fn lookup_gid_by_name(name: String): i32 {
    let pw: String = read_file("/etc/passwd")
    let lines: Vec<String> = str_split(str_trim(pw), "\n")
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let parts: Vec<String> = split_on(lines[i], 58)
        if vec_len(parts) >= 4 {
            if str_eq(parts[0], name) {
                return parse_id(parts[3])
            }
        }
        i = i + 1
    }
    return -1
}

fn lookup_uid_by_name(name: String): i32 {
    let pw: String = read_file("/etc/passwd")
    let lines: Vec<String> = str_split(str_trim(pw), "\n")
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let parts: Vec<String> = split_on(lines[i], 58)
        if vec_len(parts) >= 3 {
            if str_eq(parts[0], name) {
                return parse_id(parts[2])
            }
        }
        i = i + 1
    }
    return -1
}

fn lookup_group_name(gid: i32): String {
    let gr: String = read_file("/etc/group")
    let lines: Vec<String> = str_split(str_trim(gr), "\n")
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let parts: Vec<String> = split_on(lines[i], 58)
        if vec_len(parts) >= 3 {
            let g: i32 = parse_id(parts[2])
            if g == gid {
                return parts[0]
            }
        }
        i = i + 1
    }
    return ""
}

fn split_on(s: String, delim: i32): Vec<String> {
    let parts: Vec<String> = vec_new()
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i < n {
        if s[i] == delim {
            parts.push(str_slice(s, start, i))
            start = i + 1
        }
        i = i + 1
    }
    parts.push(str_slice(s, start, n))
    return parts
}

fn main(): i32 {
    let mut uid: i32 = getuid()
    let mut gid: i32 = getgid()
    let mut username: String = ""
    let mut want_u: i32 = 0
    let mut want_g: i32 = 0
    let mut want_G: i32 = 0
    let mut want_n: i32 = 0
    let mut name_arg: String = ""

    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if str_char_at(a, 0) == 45 {
            let la: i32 = str_len(a)
            let mut j: i32 = 1
            while j < la {
                let c: i32 = str_char_at(a, j)
                if c == 117 { want_u = 1 }
                if c == 103 { want_g = 1 }
                if c == 71 { want_G = 1 }
                if c == 110 { want_n = 1 }
                if c == 114 { want_u = 0 }
                if c == 122 { want_u = 0 }
                j = j + 1
            }
        } else {
            name_arg = a
        }
        ai = ai + 1
    }

    if str_len(name_arg) > 0 {
        let u: i32 = lookup_uid_by_name(name_arg)
        if u >= 0 {
            uid = u
            username = name_arg
            let g: i32 = lookup_gid_by_name(name_arg)
            if g >= 0 { gid = g }
        } else {
            uid = parse_id(name_arg)
            if uid < 0 { uid = getuid() }
        }
    }

    if str_len(username) == 0 {
        username = lookup_name_by_uid(uid)
    }

    // Resolve the user's group list once (used by -G, -gn, and default).
    // GNU includes the primary gid first, then supplementary groups.
    let gids: Vec<i32> = vec_new()
    let gnames: Vec<String> = vec_new()
    gids.push(gid)
    gnames.push(lookup_group_name(gid))
    let gr: String = read_file("/etc/group")
    let glines: Vec<String> = str_split(str_trim(gr), "\n")
    let gn: i32 = vec_len(glines)
    let mut gi: i32 = 0
    while gi < gn {
        let gparts: Vec<String> = split_on(glines[gi], 58)
        if vec_len(gparts) >= 4 {
            let g_gid: i32 = parse_id(gparts[2])
            let members: String = gparts[3]
            let in_members: bool = str_find(members, username) >= 0
            if in_members {
                if g_gid != gid {
                    gids.push(g_gid)
                    gnames.push(gparts[0])
                }
            }
        }
        gi = gi + 1
    }

    // -u: print only the uid (or username with -n).
    if want_u == 1 {
        if want_n == 1 {
            print_raw(username)
        } else {
            print_raw(int_to_str(uid))
        }
        print_raw("\n")
        return 0
    }
    // -g: print only the primary gid (or group name with -n).
    if want_g == 1 {
        if want_n == 1 {
            print_raw(lookup_group_name(gid))
        } else {
            print_raw(int_to_str(gid))
        }
        print_raw("\n")
        return 0
    }
    // -G: print all gids (or group names with -n), space-separated.
    if want_G == 1 {
        let cnt: i32 = vec_len(gids)
        let mut k: i32 = 0
        sb_new()
        while k < cnt {
            if k > 0 { sb_push(" ") }
            if want_n == 1 {
                sb_push(gnames[k])
            } else {
                sb_push_i32(gids[k])
            }
            k = k + 1
        }
        sb_push("\n")
        print_raw(sb_str())
        return 0
    }

    // Default: full id line.
    sb_new()
    sb_push("uid=")
    sb_push_i32(uid)
    if str_len(username) > 0 {
        sb_push("(")
        sb_push(username)
        sb_push(")")
    }
    sb_push(" gid=")
    sb_push_i32(gid)
    let gname: String = lookup_group_name(gid)
    if str_len(gname) > 0 {
        sb_push("(")
        sb_push(gname)
        sb_push(")")
    }
    let cnt: i32 = vec_len(gids)
    let mut k: i32 = 0
    while k < cnt {
        if k == 0 {
            sb_push(" groups=")
        } else {
            sb_push(",")
        }
        sb_push_i32(gids[k])
        sb_push("(")
        sb_push(gnames[k])
        sb_push(")")
        k = k + 1
    }
    sb_push("\n")
    print_raw(sb_str())
    return 0
}
