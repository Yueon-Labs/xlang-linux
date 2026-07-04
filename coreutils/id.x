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

    if argc() >= 2 {
        let arg: String = argv(1)
        let u: i32 = lookup_uid_by_name(arg)
        if u >= 0 {
            uid = u
            username = arg
            let g: i32 = lookup_gid_by_name(arg)
            if g >= 0 { gid = g }
        } else {
            uid = parse_id(arg)
            if uid < 0 { uid = getuid() }
        }
    }

    if str_len(username) == 0 {
        username = lookup_name_by_uid(uid)
    }

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

    let gr: String = read_file("/etc/group")
    let glines: Vec<String> = str_split(str_trim(gr), "\n")
    let gn: i32 = vec_len(glines)
    let mut found_groups: i32 = 0
    let mut gi: i32 = 0
    while gi < gn {
        let gparts: Vec<String> = split_on(glines[gi], 58)
        if vec_len(gparts) >= 4 {
            let g_gid: i32 = parse_id(gparts[2])
            let members: String = gparts[3]
            let in_members: bool = str_find(members, username) >= 0
            let is_primary: bool = g_gid == gid
            if in_members || is_primary {
                if g_gid != gid || in_members {
                    if found_groups == 0 {
                        sb_push(" groups=")
                    } else {
                        sb_push(",")
                    }
                    sb_push_i32(g_gid)
                    sb_push("(")
                    sb_push(gparts[0])
                    sb_push(")")
                    found_groups = found_groups + 1
                }
            }
        }
        gi = gi + 1
    }
    sb_push("\n")
    print_raw(sb_str())
    return 0
}
