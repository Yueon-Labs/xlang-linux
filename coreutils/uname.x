module main

// uname [-a] [-s] [-n] [-r] [-v] [-m] — print system info.
// Default: -s (kernel name). -a: all. Reads /proc; -m via uname(2).

fn strip_nl(s: String): String {
    let n: i32 = str_len(s)
    let mut e: i32 = n
    if n > 0 {
        if str_char_at(s, n - 1) == 10 {
            e = n - 1
        }
    }
    return str_slice(s, 0, e)
}

fn main(): i32 {
    let mut want_s: i32 = 0
    let mut want_n: i32 = 0
    let mut want_r: i32 = 0
    let mut want_v: i32 = 0
    let mut want_m: i32 = 0
    let mut want_a: i32 = 0
    let mut any: i32 = 0
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-a") {
            want_a = 1
            any = 1
        }
        if str_eq(a, "-s") {
            want_s = 1
            any = 1
        }
        if str_eq(a, "-n") {
            want_n = 1
            any = 1
        }
        if str_eq(a, "-r") {
            want_r = 1
            any = 1
        }
        if str_eq(a, "-v") {
            want_v = 1
            any = 1
        }
        if str_eq(a, "-m") {
            want_m = 1
            any = 1
        }
        i = i + 1
    }
    if any == 0 {
        want_s = 1
    }
    if want_a == 1 {
        want_s = 1
        want_n = 1
        want_r = 1
        want_v = 1
        want_m = 1
    }
    let sysname: String = strip_nl(read_file("/proc/sys/kernel/ostype"))
    let nodename: String = strip_nl(read_file("/proc/sys/kernel/hostname"))
    let release: String = strip_nl(read_file("/proc/sys/kernel/osrelease"))
    let version: String = strip_nl(read_file("/proc/sys/kernel/version"))
    let machine: String = uname_machine()
    sb_new()
    let mut first: i32 = 1
    if want_s == 1 {
        if first == 0 { sb_push(" ") }
        sb_push(sysname)
        first = 0
    }
    if want_n == 1 {
        if first == 0 { sb_push(" ") }
        sb_push(nodename)
        first = 0
    }
    if want_r == 1 {
        if first == 0 { sb_push(" ") }
        sb_push(release)
        first = 0
    }
    if want_v == 1 {
        if first == 0 { sb_push(" ") }
        sb_push(version)
        first = 0
    }
    if want_m == 1 {
        if first == 0 { sb_push(" ") }
        sb_push(machine)
        first = 0
    }
    print_raw(sb_str())
    print_raw("\n")
    return 0
}
