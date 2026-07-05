module main

// uniq [-c] [-d] [-u] [file] — drop adjacent duplicate lines (GNU uniq).
// -c: prefix each line with its count. -d: only print duplicated lines.
// -u: only print unique lines (count == 1).
//
// Streams over byte ranges in the single buffer s: compares consecutive
// lines via ranges_eq (no per-line str_slice) and emits via sb_push_slice
// (no per-line malloc). The old str_slice-per-line was the 2.1× gap vs GNU.

fn ranges_eq(s: String, a1: i32, b1: i32, a2: i32, b2: i32): i32 {
    let l1: i32 = b1 - a1
    if l1 != b2 - a2 {
        return 0
    }
    let mut k: i32 = 0
    while k < l1 {
        if str_char_at(s, a1 + k) != str_char_at(s, a2 + k) {
            return 0
        }
        k = k + 1
    }
    return 1
}

fn emit(s: String, ls: i32, le: i32, c: i32, want_c: bool, want_d: bool, want_u: bool): i32 {
    if want_d {
        if c > 1 {
            sb_push_slice(s, ls, le)
            sb_push("\n")
        }
    } else {
        if want_u {
            if c == 1 {
                sb_push_slice(s, ls, le)
                sb_push("\n")
            }
        } else {
            if want_c {
                sb_push_i32_pad(c, 7)
                sb_push(" ")
                sb_push_slice(s, ls, le)
                sb_push("\n")
            } else {
                sb_push_slice(s, ls, le)
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
    // Buffer output (one write at the end) — per-line print_raw is N syscalls.
    sb_new()
    let mut prev_start: i32 = 0
    let mut prev_end: i32 = 0
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
        if !have_run {
            prev_start = start
            prev_end = nl
            count = 1
            have_run = true
        } else {
            if ranges_eq(s, start, nl, prev_start, prev_end) == 1 {
                count = count + 1
            } else {
                emit(s, prev_start, prev_end, count, want_c, want_d, want_u)
                prev_start = start
                prev_end = nl
                count = 1
            }
        }
        start = nl + 1
    }
    if have_run {
        emit(s, prev_start, prev_end, count, want_c, want_d, want_u)
    }
    print_raw(sb_str())
    return 0
}
