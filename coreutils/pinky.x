module main

// pinky — lightweight finger. With a username arg: show /etc/passwd info.
// Without args: placeholder (can't parse utmp).

fn show_user_info(name: String): i32 {
    let pw: String = read_file("/etc/passwd")
    let n: i32 = str_len(pw)
    let mut start: i32 = 0
    let mut i: i32 = 0
    let mut found: i32 = 0
    while i <= n {
        let at_end: bool = (i == n) || (pw[i] == '\n')
        if at_end {
            let line: String = str_slice(pw, start, i)
            start = i + 1
            let colon1: i32 = str_find(line, ":")
            if colon1 >= 0 {
                let uname: String = str_slice(line, 0, colon1)
                if str_eq(uname, name) {
                    // Parse passwd fields: name:x:uid:gid:gecos:home:shell
                    let rest: String = str_slice(line, colon1 + 1, str_len(line))
                    let c2: i32 = str_find(rest, ":")
                    let after_uid: String = str_slice(rest, c2 + 1, str_len(rest))
                    let c3: i32 = str_find(after_uid, ":")
                    let uid_str: String = str_slice(after_uid, 0, c3)
                    let after_gid: String = str_slice(after_uid, c3 + 1, str_len(after_uid))
                    let c4: i32 = str_find(after_gid, ":")
                    let gecos: String = str_slice(after_gid, 0, c4)
                    let after_gecos: String = str_slice(after_gid, c4 + 1, str_len(after_gecos))
                    let c5: i32 = str_find(after_gecos, ":")
                    let home: String = str_slice(after_gecos, 0, c5)
                    let shell: String = str_slice(after_gecos, c5 + 1, str_len(after_gecos))
                    print_str("Login name: ")
                    print_str(uname)
                    print_str("  UID: ")
                    print_str(uid_str)
                    print_str("\n")
                    if str_len(gecos) > 0 {
                        print_str("In real life: ")
                        print_str(gecos)
                        print_str("\n")
                    }
                    print_str("Directory: ")
                    print_str(home)
                    print_str("  Shell: ")
                    print_str(shell)
                    print_str("\n")
                    found = 1
                }
            }
        }
        i += 1
    }
    return found
}

fn main(): i32 {
    if argc() >= 2 {
        let name: String = argv(1)
        if show_user_info(name) == 0 {
            print_str("pinky: user '")
            print_str(name)
            print_str("' not found\n")
            return 1
        }
    } else {
        print_str("Login    Name\n")
        print_str("(use 'pinky <username>' for user info)\n")
    }
    return 0
}
