module main

// comm [-123] <file1> <file2> — compare two sorted files line by line (GNU comm).
// Column 1: lines only in file1. Column 2: only in file2. Column 3: in both.
// -1 suppress col 1, -2 suppress col 2, -3 suppress col 3.

fn main(): i32 {
    let mut suppress1: i32 = 0
    let mut suppress2: i32 = 0
    let mut suppress3: i32 = 0
    let mut fa: String = ""
    let mut fb: String = ""
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut k: i32 = 1
                while k < str_len(a) {
                    let c: i32 = str_char_at(a, k)
                    if c == 49 { suppress1 = 1 }
                    if c == 50 { suppress2 = 1 }
                    if c == 51 { suppress3 = 1 }
                    k = k + 1
                }
                ai = ai + 1
            } else {
                if str_len(fa) == 0 {
                    fa = a
                } else {
                    fb = a
                }
                ai = ai + 1
            }
        } else {
            if str_len(fa) == 0 {
                fa = a
            } else {
                fb = a
            }
            ai = ai + 1
        }
    }
    if str_len(fb) == 0 {
        eprint_str("usage: comm [-123] <file1> <file2>")
        return 1
    }
    let ra: String = str_trim(read_file(fa))
    let rb: String = str_trim(read_file(fb))
    let a: Vec<String> = str_split(ra, "\n")
    let b: Vec<String> = str_split(rb, "\n")
    let an: i32 = vec_len(a)
    let bn: i32 = vec_len(b)
    let mut i: i32 = 0
    let mut j: i32 = 0
    while i < an || j < bn {
        if i >= an {
            if suppress2 == 0 {
                if suppress1 == 0 { print_raw("\t") }
                print_raw(b[j])
                print_raw("\n")
            }
            j = j + 1
        } else {
            if j >= bn {
                if suppress1 == 0 {
                    print_raw(a[i])
                    print_raw("\n")
                }
                i = i + 1
            } else {
                let cmp: i32 = str_cmp(a[i], b[j])
                if cmp < 0 {
                    if suppress1 == 0 {
                        print_raw(a[i])
                        print_raw("\n")
                    }
                    i = i + 1
                } else {
                    if cmp > 0 {
                        if suppress2 == 0 {
                            if suppress1 == 0 { print_raw("\t") }
                            print_raw(b[j])
                            print_raw("\n")
                        }
                        j = j + 1
                    } else {
                        if suppress3 == 0 {
                            if suppress1 == 0 { print_raw("\t") }
                            if suppress2 == 0 { print_raw("\t") }
                            print_raw(a[i])
                            print_raw("\n")
                        }
                        i = i + 1
                        j = j + 1
                    }
                }
            }
        }
    }
    return 0
}
