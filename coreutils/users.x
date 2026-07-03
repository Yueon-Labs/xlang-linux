module main

// users — print space-separated list of logged-in users (from utmp).

fn main(): i32 {
    let data: String = read_utmp()
    if str_len(data) == 0 {
        return 0
    }
    let lines: Vec<String> = str_split(str_trim(data), "\n")
    let n: i32 = vec_len(lines)
    sb_new()
    let mut first: i32 = 1
    let mut i: i32 = 0
    while i < n {
        let line: String = lines[i]
        let t1: i32 = str_find(line, "\t")
        if t1 >= 0 {
            let user: String = str_slice(line, 0, t1)
            if str_len(user) > 0 {
                if first == 0 { sb_push(" ") }
                sb_push(user)
                first = 0
            }
        }
        i = i + 1
    }
    if first == 0 { sb_push("\n") }
    print_raw(sb_str())
    return 0
}
