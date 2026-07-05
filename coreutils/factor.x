module main

// factor <n>... — prime factorization (like GNU factor). Trial division.
// Multiple numbers supported (one per arg). Output is buffered into one
// StringBuilder: sb_push_i32 appends the decimal directly (no int_to_str
// malloc per factor), and the whole run is a single write (no print_raw
// syscall per factor/number). Byte-identical to the old output.

fn factor_one(n: i32): i32 {
    let mut remaining: i32 = n
    let mut d: i32 = 2
    sb_push_i32(n)
    sb_push(":")
    while d * d <= remaining {
        while remaining % d == 0 {
            sb_push(" ")
            sb_push_i32(d)
            remaining = remaining / d
        }
        d = d + 1
    }
    if remaining > 1 {
        sb_push(" ")
        sb_push_i32(remaining)
    }
    sb_push("\n")
    return 0
}

fn main(): i32 {
    sb_new()
    if argc() < 2 {
        let s: String = read_stdin()
        let n: i32 = str_len(s)
        let mut start: i32 = 0
        let mut k: i32 = 0
        while k <= n {
            let mut is_end: bool = (k == n)
            if k < n {
                let c: i32 = str_char_at(s, k)
                if c == 10 || c == 32 { is_end = true }
            }
            if is_end {
                if k > start {
                    factor_one(str_to_int(str_slice(s, start, k)))
                }
                start = k + 1
            }
            k = k + 1
        }
        print_raw(sb_str())
        return 0
    }
    let mut i: i32 = 1
    while i < argc() {
        factor_one(str_to_int(argv(i)))
        i = i + 1
    }
    print_raw(sb_str())
    return 0
}
