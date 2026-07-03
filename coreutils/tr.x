module main

// tr [-ds] <set1> [set2] [file] — translate, delete, or squeeze characters.
//   -d: delete all chars in set1
//   -s: squeeze repeats (runs of a char in set2 → single char)
// Supports ranges: a-z, A-Z, 0-9, etc.
// Delete mode builds a 256-entry lookup table (O(1) per char).
// Translate mode uses the O(n) str_translate builtin after range expansion.

// Expand ranges (a-z, A-Z, 0-9) in a set string.
fn expand_set(s: String): String {
    let n: i32 = str_len(s)
    sb_new()
    let mut i: i32 = 0
    while i < n {
        if i + 2 < n {
            if str_char_at(s, i + 1) == 45 {
                let lo: i32 = str_char_at(s, i)
                let hi: i32 = str_char_at(s, i + 2)
                if lo < hi {
                    let mut c: i32 = lo
                    while c <= hi {
                        sb_push_char(c)
                        c = c + 1
                    }
                    i = i + 3
                    continue
                }
            }
        }
        sb_push_char(str_char_at(s, i))
        i = i + 1
    }
    return str_slice(sb_str(), 0, str_len(sb_str()))
}

fn main(): i32 {
    let mut s: String = ""
    let mut delete_mode: bool = false
    let mut squeeze_mode: bool = false
    let mut complement: bool = false
    let mut set1: String = ""
    let mut set2: String = ""

    if argc() < 2 {
        print_str("usage: tr [-dsc] <set1> [set2] [file]")
        return 1
    }

    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_char_at(a, 0) == 45 {
            let la: i32 = str_len(a)
            let mut k: i32 = 1
            while k < la {
                let c: i32 = str_char_at(a, k)
                if c == 100 { delete_mode = true }
                if c == 115 { squeeze_mode = true }
                if c == 99 { complement = true }
                k = k + 1
            }
        } else {
            if str_len(set1) == 0 {
                set1 = expand_set(a)
            } else {
                if str_len(set2) == 0 {
                    set2 = expand_set(a)
                } else {
                    s = read_file(a)
                }
            }
        }
        i = i + 1
    }

    if str_len(s) == 0 {
        s = read_stdin()
    }

    if delete_mode {
        // -dc: delete the COMPLEMENT of set1 (keep only set1 chars). -d: delete set1.
        let mut result: String = ""
        if complement {
            result = str_keep(s, set1)
        } else {
            result = str_delete(s, set1)
        }
        if squeeze_mode {
            squeeze(result, set1)
        } else {
            print_raw(result)
        }
    } else {
        if str_len(set2) == 0 {
            set2 = set1
        }
        let mut result: String = ""
        if complement {
            result = str_translate_complement(s, set1, set2)
        } else {
            result = str_translate(s, set1, set2)
        }
        if squeeze_mode {
            squeeze(result, set2)
        } else {
            print_raw(result)
        }
    }
    return 0
}

// Squeeze: collapse runs of chars in squeeze_set to single occurrences.
fn squeeze(text: String, squeeze_set: String): i32 {
    let slen: i32 = str_len(squeeze_set)
    let table: Vec<i32> = vec_new()
    let mut k: i32 = 0
    while k < 256 {
        table.push(0)
        k = k + 1
    }
    let mut j: i32 = 0
    while j < slen {
        table[str_char_at(squeeze_set, j)] = 1
        j = j + 1
    }
    let n: i32 = str_len(text)
    let mut prev: i32 = -1
    sb_new()
    let mut p: i32 = 0
    while p < n {
        let c: i32 = str_char_at(text, p)
        if table[c] == 1 {
            if c != prev {
                sb_push_char(c)
            }
        } else {
            sb_push_char(c)
        }
        prev = c
        p = p + 1
    }
    print_raw(str_slice(sb_str(), 0, str_len(sb_str())))
    return 0
}
