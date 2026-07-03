module main

// chown [-R] <owner>[:<group>] <file...> — change file owner and group.
// Uses chown(2). Owner/group can be names (resolved via /etc/passwd and
// /etc/group) or numeric IDs.

fn parse_id(s: String): i32 {
    // Try numeric first.
    let n: i32 = str_to_int(s)
    if n != 0 || str_eq(s, "0") { return n }
    return -1
}

fn lookup_user(name: String): i32 {
    let id: i32 = parse_id(name)
    if id >= 0 { return id }
    // Look up in /etc/passwd
    let pw: String = read_file("/etc/passwd")
    let lines: Vec<String> = split_lines(pw)
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let line: String = lines[i]
        let parts: Vec<String> = split_char(line, ':')
        if vec_len(parts) >= 3 {
            if str_eq(parts[0], name) { return str_to_int(parts[2]) }
        }
        i += 1
    }
    return -1
}

fn lookup_group(name: String): i32 {
    let id: i32 = parse_id(name)
    if id >= 0 { return id }
    let gr: String = read_file("/etc/group")
    let lines: Vec<String> = split_lines(gr)
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let line: String = lines[i]
        let parts: Vec<String> = split_char(line, ':')
        if vec_len(parts) >= 3 {
            if str_eq(parts[0], name) { return str_to_int(parts[2]) }
        }
        i += 1
    }
    return -1
}

fn split_lines(s: String): Vec<String> {
    let lines: Vec<String> = vec_new()
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i < n {
        if s[i] == '\n' {
            lines.push(str_slice(s, start, i))
            start = i + 1
        }
        i += 1
    }
    if start < n { lines.push(str_slice(s, start, n)) }
    return lines
}

fn split_char(s: String, delim: i32): Vec<String> {
    let parts: Vec<String> = vec_new()
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i < n {
        if s[i] == delim {
            parts.push(str_slice(s, start, i))
            start = i + 1
        }
        i += 1
    }
    parts.push(str_slice(s, start, n))
    return parts
}

fn main(): i32 {
    let mut recursive: i32 = 0
    let mut owner_spec: String = ""
    let files: Vec<String> = vec_new()
    let mut have_owner: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if a == "-R" {
            recursive = 1
        } else {
            if have_owner == 0 {
                owner_spec = a
                have_owner = 1
            } else {
                files.push(a)
            }
        }
        ai += 1
    }
    if have_owner == 0 || vec_len(files) == 0 {
        print_str("usage: chown [-R] <owner>[:<group>] <file...>\n")
        return 1
    }
    let colon: i32 = str_find(owner_spec, ":")
    let mut uid: i32 = -1
    let mut gid: i32 = -1
    if colon >= 0 {
        let uname: String = str_slice(owner_spec, 0, colon)
        let gname: String = str_slice(owner_spec, colon + 1, str_len(owner_spec))
        if str_len(uname) > 0 { uid = lookup_user(uname) }
        if str_len(gname) > 0 { gid = lookup_group(gname) }
    } else {
        uid = lookup_user(owner_spec)
    }
    let mut fail: i32 = 0
    let nf: i32 = vec_len(files)
    let mut fi: i32 = 0
    while fi < nf {
        let path: String = files[fi]
        let rc: i32 = chown_file(path, uid, gid)
        if rc != 0 {
            print_str("chown: cannot access '")
            print_str(path)
            print_str("'\n")
            fail = 1
        }
        fi += 1
    }
    return fail
}
