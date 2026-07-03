module main

// groups [user] — print group names for the current (or named) user.
// Reads /etc/group: finds groups where the user is in the member list,
// plus the group matching the user's primary gid from /etc/passwd.

fn parse_id(s: String): i32 {
    let n: i32 = str_len(s)
    if n == 0 { return -1 }
    let mut v: i32 = 0
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c < 48 { break }
        if c > 57 { break }
        v = v * 10 + (c - 48)
        i = i + 1
    }
    return v
}

fn split_colon(s: String): Vec<String> {
    let parts: Vec<String> = vec_new()
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i < n {
        if str_char_at(s, i) == 58 {
            parts.push(str_slice(s, start, i))
            start = i + 1
        }
        i = i + 1
    }
    parts.push(str_slice(s, start, n))
    return parts
}

fn lookup_primary_gid(name: String): i32 {
    let pw: String = read_file("/etc/passwd")
    let lines: Vec<String> = str_split(str_trim(pw), "\n")
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let parts: Vec<String> = split_colon(lines[i])
        if vec_len(parts) >= 4 {
            if str_eq(parts[0], name) {
                return parse_id(parts[3])
            }
        }
        i = i + 1
    }
    return -1
}

fn main(): i32 {
    let uid: i32 = getuid()
    let mut username: String = ""

    if argc() >= 2 {
        username = argv(1)
    }

    if str_len(username) == 0 {
        let pw: String = read_file("/etc/passwd")
        let lines: Vec<String> = str_split(str_trim(pw), "\n")
        let n: i32 = vec_len(lines)
        let mut i: i32 = 0
        while i < n {
            let parts: Vec<String> = split_colon(lines[i])
            if vec_len(parts) >= 3 {
                if parse_id(parts[2]) == uid {
                    username = parts[0]
                    break
                }
            }
            i = i + 1
        }
    }

    if str_len(username) == 0 {
        username = getenv("USER")
    }

    let primary_gid: i32 = lookup_primary_gid(username)

    let gr: String = read_file("/etc/group")
    let glines: Vec<String> = str_split(str_trim(gr), "\n")
    let gn: i32 = vec_len(glines)

    sb_new()
    let mut first: i32 = 1
    let mut gi: i32 = 0
    while gi < gn {
        let gparts: Vec<String> = split_colon(glines[gi])
        if vec_len(gparts) >= 3 {
            let g_gid: i32 = parse_id(gparts[2])
            let members: String = ""
            if vec_len(gparts) >= 4 {
                members = gparts[3]
            }
            let is_primary: bool = g_gid == primary_gid
            let in_members: bool = str_len(members) > 0 && str_find(members, username) >= 0
            if is_primary || in_members {
                if first == 0 {
                    sb_push(" ")
                }
                sb_push(gparts[0])
                first = 0
            }
        }
        gi = gi + 1
    }
    sb_push("\n")
    print_raw(sb_str())
    return 0
}
