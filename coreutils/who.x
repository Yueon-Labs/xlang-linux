module main

// who — show who is logged in (GNU who format).
// Reads USER_PROCESS entries from utmp via read_utmp builtin.

fn format_time(epoch: i32): String {
    return time_format_utc("%b %e %H:%M", epoch)
}

fn main(): i32 {
    let data: String = read_utmp()
    if str_len(data) == 0 {
        return 0
    }
    let lines: Vec<String> = str_split(str_trim(data), "\n")
    let n: i32 = vec_len(lines)
    sb_new()
    let mut i: i32 = 0
    while i < n {
        let line: String = lines[i]
        let t1: i32 = str_find(line, "\t")
        if t1 >= 0 {
            let user: String = str_slice(line, 0, t1)
            let rest: String = str_slice(line, t1 + 1, str_len(line))
            let t2: i32 = str_find(rest, "\t")
            if t2 >= 0 {
                let tty: String = str_slice(rest, 0, t2)
                let time_s: String = str_slice(rest, t2 + 1, str_len(rest))
                let epoch: i32 = str_to_int(time_s)
                let when: String = format_time(epoch)
                sb_push(user)
                sb_push(" ")
                sb_push(tty)
                sb_push("  ")
                sb_push(when)
                sb_push("\n")
            }
        }
        i = i + 1
    }
    print_raw(sb_str())
    return 0
}
