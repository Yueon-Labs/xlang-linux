module main

// ps [-e] [-o FMT] — list running processes by reading /proc/[pid].
//   -e        all processes (default)
//   -o FMT    comma-separated output fields: pid,ppid,user,stat,time,comm,args
// Default: "  PID TTY      STAT   TIME COMMAND" (close to `ps -e`).
// Reads /proc/[pid]/stat for ppid/state/utime/stime, /proc/[pid]/comm for name,
// /proc/[pid]/cmdline for full command line.

fn read_stat_field(stat_line: String, field: i32): String {
    // /proc/[pid]/stat fields are space-separated, but field 2 (comm) is in
    // parentheses and can contain spaces. Extract by counting fields.
    let n: i32 = str_len(stat_line)
    let mut start: i32 = 0
    let mut i: i32 = 0
    let mut field_num: i32 = 1
    let in_parens: bool = false
    let mut paren_depth: i32 = 0
    while i < n {
        let c: i32 = str_char_at(stat_line, i)
        if c == 40 { paren_depth = paren_depth + 1 }
        if c == 41 {
            if paren_depth > 0 { paren_depth = paren_depth - 1 }
        }
        if c == 32 {
            if paren_depth == 0 {
                if field_num == field {
                    return str_slice(stat_line, start, i)
                }
                field_num = field_num + 1
                start = i + 1
            }
        }
        i = i + 1
    }
    if field_num == field {
        return str_slice(stat_line, start, n)
    }
    return ""
}

fn parse_int(s: String): i32 {
    let n: i32 = str_len(s)
    let mut v: i32 = 0
    let mut i: i32 = 0
    let mut neg: i32 = 0
    if n > 0 {
        if str_char_at(s, 0) == 45 { neg = 1 }
        if str_char_at(s, 0) == 45 { i = 1 }
    }
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c < 48 { break }
        if c > 57 { break }
        v = v * 10 + (c - 48)
        i = i + 1
    }
    if neg == 1 { v = -v }
    return v
}

fn strip_trailing_nl(s: String): String {
    let n: i32 = str_len(s)
    if n == 0 { return s }
    if str_char_at(s, n - 1) == 10 { return str_slice(s, 0, n - 1) }
    return s
}

fn main(): i32 {
    let mut want_full: i32 = 0
    let mut fmt: String = ""
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if a == "-e" || a == "-A" {
            want_full = 1
        } else if a == "-f" {
            want_full = 1
        } else if a == "-o" {
            ai = ai + 1
            if ai < argc() { fmt = argv(ai) }
        } else if str_starts_with(a, "-o") {
            fmt = str_slice(a, 2, str_len(a))
        }
        ai = ai + 1
    }

    sb_new()

    if str_len(fmt) > 0 {
        let fields: Vec<String> = str_split(fmt, ",")
        let nf: i32 = vec_len(fields)
        let mut fi: i32 = 0
        while fi < nf {
            if fi > 0 { sb_push(" ") }
            sb_push(fields[fi])
            fi = fi + 1
        }
        sb_push("\n")
    } else {
        sb_push("  PID TTY          STAT   TIME COMMAND\n")
    }

    let n: i32 = dir_count("/proc")
    let mut i: i32 = 0
    while i < n {
        let entry: String = dir_entry("/proc", i)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) >= 48 {
                if str_char_at(entry, 0) <= 57 {
                    let base: String = str_concat("/proc/", entry)
                    let stat_line: String = strip_trailing_nl(read_file(str_concat(base, "/stat")))
                    let comm: String = strip_trailing_nl(read_file(str_concat(base, "/comm")))

                    if str_len(fmt) > 0 {
                        let fields: Vec<String> = str_split(fmt, ",")
                        let nf: i32 = vec_len(fields)
                        let ppid: String = read_stat_field(stat_line, 4)
                        let state: String = read_stat_field(stat_line, 3)
                        let utime_s: String = read_stat_field(stat_line, 14)
                        let stime_s: String = read_stat_field(stat_line, 15)
                        let uid_val: i32 = stat_field(str_concat(base, "/"), 2)
                        let mut uid_s: String = uid_to_name(uid_val)
                        if str_len(uid_s) == 0 { uid_s = int_to_str(uid_val) }
                        let utime: i32 = parse_int(utime_s)
                        let stime: i32 = parse_int(stime_s)
                        let total_jiffies: i32 = utime + stime
                        let secs: i32 = total_jiffies / 100
                        let mut time_str: String = str_concat(int_to_str(secs / 60), ":")
                        let rem: i32 = secs % 60
                        if rem < 10 {
                            time_str = str_concat(time_str, str_concat("0", int_to_str(rem)))
                        } else {
                            time_str = str_concat(time_str, int_to_str(rem))
                        }

                        let mut fi: i32 = 0
                        while fi < nf {
                            if fi > 0 { sb_push(" ") }
                            let f: String = fields[fi]
                            if f == "pid" { sb_push(entry) }
                            if f == "ppid" { sb_push(ppid) }
                            if f == "user" || f == "euser" || f == "uname" { sb_push(uid_s) }
                            if f == "stat" || f == "state" { sb_push(state) }
                            if f == "time" || f == "etimes" { sb_push(time_str) }
                            if f == "comm" { sb_push(comm) }
                            if f == "args" || f == "command" || f == "cmd" {
                                let cmdline: String = read_file(str_concat(base, "/cmdline"))
                                let cn: i32 = str_len(cmdline)
                                if cn > 0 {
                                    let mut ci: i32 = 0
                                    while ci < cn {
                                        if cmdline[ci] == 0 { sb_push(" ") } else { sb_push_char(cmdline[ci]) }
                                        ci = ci + 1
                                    }
                                } else {
                                    sb_push(comm)
                                }
                            }
                            fi = fi + 1
                        }
                        sb_push("\n")
                    } else {
                        let state: String = read_stat_field(stat_line, 3)
                        let utime_s: String = read_stat_field(stat_line, 14)
                        let stime_s: String = read_stat_field(stat_line, 15)
                        let utime: i32 = parse_int(utime_s)
                        let stime: i32 = parse_int(stime_s)
                        let secs: i32 = (utime + stime) / 100
                        let mm: i32 = secs / 60
                        let ss: i32 = secs % 60
                        let mut time_str: String = str_concat(int_to_str(mm), ":")
                        if ss < 10 {
                            time_str = str_concat(time_str, str_concat("0", int_to_str(ss)))
                        } else {
                            time_str = str_concat(time_str, int_to_str(ss))
                        }
                        sb_push(entry)
                        sb_push(" ?        ")
                        sb_push(state)
                        sb_push("   ")
                        sb_push(time_str)
                        sb_push(" ")
                        if want_full == 1 {
                            let cmdline: String = read_file(str_concat(base, "/cmdline"))
                            let cn: i32 = str_len(cmdline)
                            if cn > 0 {
                                let mut ci: i32 = 0
                                while ci < cn {
                                    if cmdline[ci] == 0 { sb_push(" ") } else { sb_push_char(cmdline[ci]) }
                                    ci = ci + 1
                                }
                            } else {
                                sb_push(comm)
                            }
                        } else {
                            sb_push(comm)
                        }
                        sb_push("\n")
                    }
                }
            }
        }
        i = i + 1
    }

    print_raw(sb_str())
    return 0
}
