module main

// join [-1 F1] [-2 F2] [-t SEP] [-a 1|2] FILE1 FILE2
// Relational join of two line-sorted files on a key field (GNU join subset).
// Both files MUST be sorted on their join field. Default: join on field 1 of
// each, whitespace-separated fields, output "key <file1 rest> <file2 rest>".
//   -1 F   join field of FILE1 (1-indexed)
//   -2 F   join field of FILE2
//   -t C   single-char field separator (default: whitespace runs)
//   -a 1|-a 2   also emit unpairable lines from that file
//
// All lines are split into fields ONCE at load time, stored in flat arrays
// (fields / fstart / fcount) — the merge reads pre-split fields instead of
// re-splitting each line up to 3× (key compare + run-find + cross-product
// emit). -a prints the original raw line, so the line text is kept too.


// Split a line into fields by a separator. use_ws=1 → runs of space/tab;
// else split on the single sep_char.
fn split_fields(line: String, sep_char: i32, use_ws: i32): Vec<String> {
    let fields: Vec<String> = vec_new()
    let n: i32 = str_len(line)
    let mut i: i32 = 0
    while i < n {
        // skip separators
        while i < n {
            let c: i32 = str_char_at(line, i)
            if use_ws == 1 {
                if c == 32 || c == 9 { i += 1 } else { break }
            } else {
                if c == sep_char { i += 1 } else { break }
            }
        }
        if i >= n { break }
        let start: i32 = i
        while i < n {
            let c: i32 = str_char_at(line, i)
            if use_ws == 1 {
                if c == 32 || c == 9 { break }
            } else {
                if c == sep_char { break }
            }
            i += 1
        }
        fields.push(str_slice(line, start, i))
    }
    return fields
}

// 1-indexed field access into a flat field array; "" if out of range.
// `start` is where the line's fields begin, `count` how many it has.
fn flat_field(all: Vec<String>, start: i32, count: i32, idx: i32): String {
    if idx < 1 { return "" }
    if idx > count { return "" }
    return all[start + idx - 1]
}

// Append a joined row to the shared output StringBuilder: key, then FILE1's
// non-join fields, then FILE2's, separated by sep. Fields come from the flat
// pre-split arrays (start1/count1, start2/count2). Caller owns sb_new/print.
fn emit_join(key: String, all1: Vec<String>, start1: i32, count1: i32, jf1: i32, all2: Vec<String>, start2: i32, count2: i32, jf2: i32, sep: String): i32 {
    sb_push(key)
    let mut k: i32 = 1
    while k <= count1 {
        if k != jf1 {
            sb_push(sep)
            sb_push(all1[start1 + k - 1])
        }
        k += 1
    }
    let mut m: i32 = 1
    while m <= count2 {
        if m != jf2 {
            sb_push(sep)
            sb_push(all2[start2 + m - 1])
        }
        m += 1
    }
    sb_push("\n")
    return 0
}

fn main(): i32 {
    let mut jf1: i32 = 1
    let mut jf2: i32 = 1
    let mut use_ws: i32 = 1
    let mut sep_char: i32 = 32
    let mut a1: i32 = 0
    let mut a2: i32 = 0
    let mut fa: String = ""
    let mut fb: String = ""
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if a == "-1" {
            if ai + 1 < argc() { jf1 = str_to_int(argv(ai + 1)) }
            ai += 2
        } else if a == "-2" {
            if ai + 1 < argc() { jf2 = str_to_int(argv(ai + 1)) }
            ai += 2
        } else if a == "-t" {
            if ai + 1 < argc() {
                sep_char = str_char_at(argv(ai + 1), 0)
                use_ws = 0
            }
            ai += 2
        } else if a == "-a" {
            if ai + 1 < argc() {
                if argv(ai + 1) == "1" { a1 = 1 }
                if argv(ai + 1) == "2" { a2 = 1 }
            }
            ai += 2
        } else {
            if str_len(fa) == 0 {
                fa = a
            } else {
                fb = a
            }
            ai += 1
        }
    }
    if str_len(fa) == 0 || str_len(fb) == 0 {
        eprint_str("usage: join [-1 F1] [-2 F2] [-t SEP] [-a 1|2] file1 file2")
        return 1
    }
    // Output separator: the -t char, or a space for the default whitespace mode.
    let mut sep: String = " "
    if use_ws == 0 {
        sep = chr(sep_char)
    }
    // Raw lines (kept for -a, which prints them verbatim).
    let lines1: Vec<String> = str_split(str_trim(read_file(fa)), "
")
    let lines2: Vec<String> = str_split(str_trim(read_file(fb)), "
")
    let n1: i32 = vec_len(lines1)
    let n2: i32 = vec_len(lines2)

    // Pre-split every line's fields ONCE into flat arrays. fstart[k]/fcount[k]
    // locate line k's fields within the flat `fields` vector — the merge reads
    // these instead of re-splitting each line 3× (key / run-find / emit).
    let fields1: Vec<String> = vec_new()
    let fstart1: Vec<i32> = vec_new()
    let fcount1: Vec<i32> = vec_new()
    let fields2: Vec<String> = vec_new()
    let fstart2: Vec<i32> = vec_new()
    let fcount2: Vec<i32> = vec_new()
    let mut li: i32 = 0
    while li < n1 {
        fstart1.push(vec_len(fields1))
        let lf: Vec<String> = split_fields(lines1[li], sep_char, use_ws)
        let nf: i32 = vec_len(lf)
        let mut kk: i32 = 0
        while kk < nf {
            fields1.push(lf[kk])
            kk += 1
        }
        fcount1.push(nf)
        li += 1
    }
    li = 0
    while li < n2 {
        fstart2.push(vec_len(fields2))
        let lf: Vec<String> = split_fields(lines2[li], sep_char, use_ws)
        let nf: i32 = vec_len(lf)
        let mut kk: i32 = 0
        while kk < nf {
            fields2.push(lf[kk])
            kk += 1
        }
        fcount2.push(nf)
        li += 1
    }

    let mut i: i32 = 0
    let mut j: i32 = 0
    // One output buffer for the whole join (emit_join appends into it); a
    // single write at the end instead of a per-row malloc + syscall.
    sb_new()
    while i < n1 && j < n2 {
        let k1: String = flat_field(fields1, fstart1[i], fcount1[i], jf1)
        let k2: String = flat_field(fields2, fstart2[j], fcount2[j], jf2)
        if k1 == k2 {
            // Equal keys: GNU join is a cross-product over the consecutive
            // runs of equal keys in each file (1-to-many / many-to-many).
            let mut i_end: i32 = i
            while i_end < n1 {
                if flat_field(fields1, fstart1[i_end], fcount1[i_end], jf1) == k1 { i_end += 1 } else { break }
            }
            let mut j_end: i32 = j
            while j_end < n2 {
                if flat_field(fields2, fstart2[j_end], fcount2[j_end], jf2) == k2 { j_end += 1 } else { break }
            }
            let mut gi: i32 = i
            while gi < i_end {
                let mut gj: i32 = j
                while gj < j_end {
                    emit_join(k1, fields1, fstart1[gi], fcount1[gi], jf1, fields2, fstart2[gj], fcount2[gj], jf2, sep)
                    gj += 1
                }
                gi += 1
            }
            i = i_end
            j = j_end
        } else if k1 < k2 {
            if a1 == 1 {
                sb_push(lines1[i])
                sb_push("\n")
            }
            i += 1
        } else {
            if a2 == 1 {
                sb_push(lines2[j])
                sb_push("\n")
            }
            j += 1
        }
    }
    if a1 == 1 {
        while i < n1 {
            sb_push(lines1[i])
            sb_push("\n")
            i += 1
        }
    }
    if a2 == 1 {
        while j < n2 {
            sb_push(lines2[j])
            sb_push("\n")
            j += 1
        }
    }
    print_raw(sb_str())
    return 0
}
