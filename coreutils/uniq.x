module main

// uniq [-c] [-d] [-u] [file] — drop adjacent duplicate lines (GNU uniq).
// -c: prefix each line with its count. -d: only print duplicated lines.
// -u: only print unique lines (count == 1).
fn emit(line: String, c: i32, want_c: bool, want_d: bool, want_u: bool): i32 {
    if want_d {
        if c > 1 {
            sb_push(line)
            sb_push("\n")
        }
    } else {
        if want_u {
            if c == 1 {
                sb_push(line)
                sb_push("\n")
            }
        } else {
            if want_c {
                sb_push(pad_int(c, 7))
                sb_push(" ")
                sb_push(line)
                sb_push("\n")
            } else {
                sb_push(line)
                sb_push("\n")
            }
        }
    }
    return 0
}

fn main(): i32 {
    let mut want_c: bool = false
    let mut want_d: bool = false
    let mut want_u: bool = false
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_char_at(a, 0) == 45 {
            let la: i32 = str_len(a)
            let mut k: i32 = 1
            while k < la {
                let c: i32 = str_char_at(a, k)
                if c == 99 { want_c = true }
                if c == 100 { want_d = true }
                if c == 117 { want_u = true }
                k = k + 1
            }
        } else {
            file = a
        }
        i = i + 1
    }
    let mut s: String = ""
    if str_len(file) > 0 {
        s = read_file(file)
    } else {
        s = read_stdin()
    }
    let n: i32 = str_len(s)
    // Buffer output (one write at the end) — per-line print_raw is N syscalls.
    sb_new()
    let mut prev: String = ""
    let mut count: i32 = 0
    let mut have_run: bool = false
    let mut start: i32 = 0
    // Bulk newline scan via str_find_from (strchr for 1-char needle — fast on
    // all platforms) instead of the per-char str_char_at loop.
    while true {
        let nl: i32 = str_find_from(s, "\n", start)
        if nl < 0 {
            break
        }
        let line: String = str_slice(s, start, nl)
        if !have_run {
            prev = line
            count = 1
            have_run = true
        } else {
            if str_eq(line, prev) {
                count = count + 1
            } else {
                emit(prev, count, want_c, want_d, want_u)
                prev = line
                count = 1
            }
        }
        start = nl + 1
    }
    if have_run {
        emit(prev, count, want_c, want_d, want_u)
    }
    print_raw(sb_str())
    return 0
}
