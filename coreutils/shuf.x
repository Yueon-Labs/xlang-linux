module main

// shuf [-i LO-HI] [-e ARG...] [-n N] [file] — randomly permute (GNU shuf).
//   -i LO-HI   shuffle the integers LO..HI (inclusive)
//   -e ARG...  shuffle the given arguments
//   -n N       output at most N lines
//   -r         with -n N: sample N times WITH replacement
// Default: shuffle stdin/file lines. Fisher-Yates.


fn main(): i32 {
    random_seed()
    let mut limit: i32 = 0
    let mut want_i: i32 = 0
    let mut want_e: i32 = 0
    let mut want_r: i32 = 0
    let mut lo: i32 = 0
    let mut hi: i32 = 0
    let mut file: String = ""
    let items: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-n") {
            i = i + 1
            if i < argc() { limit = str_to_int(argv(i)) }
            i = i + 1
        } else {
            if str_starts_with(a, "-n") {
                limit = str_to_int(str_slice(a, 2, str_len(a)))
                i = i + 1
            } else {
                if str_eq(a, "-r") {
                    want_r = 1
                    i = i + 1
                } else {
                    if str_eq(a, "-i") {
                        want_i = 1
                        i = i + 1
                        if i < argc() {
                            let spec: String = argv(i)
                            let dash: i32 = str_find(spec, "-")
                            if dash > 0 {
                                lo = str_to_int(str_slice(spec, 0, dash))
                                hi = str_to_int(str_slice(spec, dash + 1, str_len(spec)))
                            }
                        }
                        i = i + 1
                    } else {
                        if str_starts_with(a, "-i") {
                            want_i = 1
                            let spec: String = str_slice(a, 2, str_len(a))
                            let dash: i32 = str_find(spec, "-")
                            if dash > 0 {
                                lo = str_to_int(str_slice(spec, 0, dash))
                                hi = str_to_int(str_slice(spec, dash + 1, str_len(spec)))
                            }
                            i = i + 1
                        } else {
                            if str_eq(a, "-e") {
                                want_e = 1
                                i = i + 1
                                while i < argc() {
                                    items.push(argv(i))
                                    i = i + 1
                                }
                            } else {
                                if str_len(a) >= 1 {
                                    if str_char_at(a, 0) != 45 {
                                        file = a
                                    }
                                }
                                i = i + 1
                            }
                        }
                    }
                }
            }
        }
    }

    // Build the item list: -i range, -e args, or stdin/file lines.
    if want_i == 1 {
        let mut v: i32 = lo
        while v <= hi {
            items.push(int_to_str(v))
            v = v + 1
        }
    } else {
        if want_e == 0 {
            let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
            let lines: Vec<String> = str_split(str_trim(s), "\n")
            let nl: i32 = vec_len(lines)
            let mut k: i32 = 0
            while k < nl {
                items.push(lines[k])
                k = k + 1
            }
        }
    }

    let n: i32 = vec_len(items)
    if n == 0 {
        return 0
    }

    // -r: sample `limit` times with replacement.
    if want_r == 1 {
        if limit <= 0 {
            limit = n
        }
        let mut r: i32 = 0
        while r < limit {
            let j: i32 = random_int(n)
            print_raw(items[j])
            print_raw("\n")
            r = r + 1
        }
        return 0
    }

    // Fisher-Yates shuffle.
    let mut i2: i32 = n - 1
    while i2 > 0 {
        let j: i32 = random_int(i2 + 1)
        let tmp: String = items[i2]
        items[i2] = items[j]
        items[j] = tmp
        i2 = i2 - 1
    }

    if limit == 0 {
        limit = n
    }
    let mut k2: i32 = 0
    while k2 < limit {
        if k2 >= n {
            break
        }
        print_raw(items[k2])
        print_raw("\n")
        k2 = k2 + 1
    }
    return 0
}
