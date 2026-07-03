module main

// chgrp <group> <file...> — change file group. Same as chown but only group.
// Reuses the same lookup/chown_file logic.

fn parse_id(s: String): i32 {
    let n: i32 = str_to_int(s)
    if n != 0 || str_eq(s, "0") { return n }
    return -1
}

fn lookup_group(name: String): i32 {
    let id: i32 = parse_id(name)
    if id >= 0 { return id }
    let gr: String = read_file("/etc/group")
    let lines: Vec<String> = vec_new()
    let gn: i32 = str_len(gr)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i < gn {
        if gr[i] == '\n' {
            lines.push(str_slice(gr, start, i))
            start = i + 1
        }
        i += 1
    }
    if start < gn { lines.push(str_slice(gr, start, gn)) }
    let ln: i32 = vec_len(lines)
    let mut li: i32 = 0
    while li < ln {
        let line: String = lines[li]
        let colon: i32 = str_find(line, ":")
        if colon >= 0 {
            let gname: String = str_slice(line, 0, colon)
            if str_eq(gname, name) {
                let rest: String = str_slice(line, colon + 1, str_len(line))
                let colon2: i32 = str_find(rest, ":")
                if colon2 >= 0 { return str_to_int(str_slice(rest, colon2 + 1, str_len(rest))) }
            }
        }
        li += 1
    }
    return -1
}

fn main(): i32 {
    if argc() < 3 {
        print_str("usage: chgrp <group> <file...>\n")
        return 1
    }
    let gname: String = argv(1)
    let gid: i32 = lookup_group(gname)
    if gid < 0 {
        print_str("chgrp: invalid group: ")
        print_str(gname)
        print_str("\n")
        return 1
    }
    let mut fail: i32 = 0
    let mut ai: i32 = 2
    while ai < argc() {
        let path: String = argv(ai)
        let rc: i32 = chgrp_file(path, gid)
        if rc != 0 {
            print_str("chgrp: cannot access '")
            print_str(path)
            print_str("'\n")
            fail = 1
        }
        ai += 1
    }
    return fail
}
