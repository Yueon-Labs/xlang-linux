module main

// whoami — print current username (from getuid → /etc/passwd lookup).
// Falls back to $USER/$LOGNAME env vars if /etc/passwd lookup fails.

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

fn main(): i32 {
    let uid: i32 = getuid()
    let pw: String = read_file("/etc/passwd")
    let lines: Vec<String> = str_split(str_trim(pw), "\n")
    let n: i32 = vec_len(lines)
    let mut i: i32 = 0
    while i < n {
        let parts: Vec<String> = split_colon(lines[i])
        if vec_len(parts) >= 3 {
            if parse_id(parts[2]) == uid {
                print_raw(parts[0])
                print_raw("\n")
                return 0
            }
        }
        i = i + 1
    }
    let mut user: String = getenv("USER")
    if str_len(user) == 0 {
        user = getenv("LOGNAME")
    }
    print_raw(user)
    print_raw("\n")
    return 0
}
