module main

// pinky — lightweight finger. With a username arg: show /etc/passwd info.
// Without args: header only.

struct PasswdEntry {
    name: String
    uid: String
    gid: String
    gecos: String
    home: String
    shell: String
}

fn parse_passwd_line(line: String): PasswdEntry {
    let c1: i32 = str_find(line, ":")
    let nm: String = str_slice(line, 0, c1)
    let rest1: String = str_slice(line, c1 + 1, str_len(line))
    let c2: i32 = str_find(rest1, ":")
    let rest2: String = str_slice(rest1, c2 + 1, str_len(rest1))
    let c3: i32 = str_find(rest2, ":")
    let uid: String = str_slice(rest2, 0, c3)
    let rest3: String = str_slice(rest2, c3 + 1, str_len(rest2))
    let c4: i32 = str_find(rest3, ":")
    let gid: String = str_slice(rest3, 0, c4)
    let rest4: String = str_slice(rest3, c4 + 1, str_len(rest3))
    let c5: i32 = str_find(rest4, ":")
    let gecos: String = str_slice(rest4, 0, c5)
    let rest5: String = str_slice(rest4, c5 + 1, str_len(rest4))
    let c6: i32 = str_find(rest5, ":")
    let home: String = str_slice(rest5, 0, c6)
    let shell: String = str_slice(rest5, c6 + 1, str_len(rest5))
    return PasswdEntry { name: nm, uid: uid, gid: gid, gecos: gecos, home: home, shell: shell }
}

fn show_user_info(name: String): i32 {
    let pw: String = read_file("/etc/passwd")
    let n: i32 = str_len(pw)
    let mut start: i32 = 0
    let mut i: i32 = 0
    let mut found: i32 = 0
    while i <= n {
        if i == n || pw[i] == '\n' {
            let line: String = str_slice(pw, start, i)
            start = i + 1
            if str_len(line) > 0 {
                let entry: PasswdEntry = parse_passwd_line(line)
                if str_eq(entry.name, name) {
                    print_str("Login name: ")
                    print_str(entry.name)
                    print_str("  UID: ")
                    print_str(entry.uid)
                    print_str("\n")
                    if str_len(entry.gecos) > 0 {
                        print_str("In real life: ")
                        print_str(entry.gecos)
                        print_str("\n")
                    }
                    print_str("Directory: ")
                    print_str(entry.home)
                    print_str("  Shell: ")
                    print_str(entry.shell)
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
            eprint_str("pinky: user '")
            eprint_str(name)
            eprint_str("' not found\n")
            return 1
        }
    } else {
        print_str("Login    Name\n")
        print_str("(use 'pinky <username>' for user info)\n")
    }
    return 0
}
