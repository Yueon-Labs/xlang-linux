module main

// join [-1 F1] [-2 F2] [-t SEP] [-a 1|2] FILE1 FILE2
// Relational join of two line-sorted files on a key field (GNU join subset).
// Both files MUST be sorted on their join field. Default: join on field 1 of
// each, whitespace-separated fields, output "key <file1 rest> <file2 rest>".
//   -1 F   join field of FILE1 (1-indexed)
//   -2 F   join field of FILE2
//   -t C   single-char field separator (default: whitespace runs)
//   -a 1|-a 2   also emit unpairable lines from that file

fn split_lines(s: String): Vec<String> {
    let lines: Vec<String> = vec_new()
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i < n {
        if str_char_at(s, i) == 10 {
            lines.push(str_slice(s, start, i))
            start = i + 1
        }
        i += 1
    }
    if start < n {
        lines.push(str_slice(s, start, n))
    }
    return lines
}

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

// 1-indexed field access; "" if out of range.
fn field_at(fields: Vec<String>, idx: i32): String {
    let nf: i32 = vec_len(fields)
    if idx < 1 { return "" }
    if idx > nf { return "" }
    return fields[idx - 1]
}

// Emit a joined row: key, then FILE1's non-join fields, then FILE2's, separated
// by sep.
fn emit_join(key: String, f1: Vec<String>, jf1: i32, f2: Vec<String>, jf2: i32, sep: String): i32 {
    sb_new()
    sb_push(key)
    let n1: i32 = vec_len(f1)
    let mut k: i32 = 1
    while k <= n1 {
        if k != jf1 {
            sb_push(sep)
            sb_push(f1[k - 1])
        }
        k += 1
    }
    let n2: i32 = vec_len(f2)
    let mut m: i32 = 1
    while m <= n2 {
        if m != jf2 {
            sb_push(sep)
            sb_push(f2[m - 1])
        }
        m += 1
    }
    sb_push("\n")
    print_raw(sb_str())
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
        print_str("usage: join [-1 F1] [-2 F2] [-t SEP] [-a 1|2] file1 file2")
        return 1
    }
    // Output separator: the -t char, or a space for the default whitespace mode.
    let mut sep: String = " "
    if use_ws == 0 {
        sep = chr(sep_char)
    }
    let lines1: Vec<String> = split_lines(read_file(fa))
    let lines2: Vec<String> = split_lines(read_file(fb))
    let n1: i32 = vec_len(lines1)
    let n2: i32 = vec_len(lines2)
    let mut i: i32 = 0
    let mut j: i32 = 0
    while i < n1 && j < n2 {
        let f1: Vec<String> = split_fields(lines1[i], sep_char, use_ws)
        let f2: Vec<String> = split_fields(lines2[j], sep_char, use_ws)
        let k1: String = field_at(f1, jf1)
        let k2: String = field_at(f2, jf2)
        if k1 == k2 {
            // Equal keys: GNU join is a cross-product over the consecutive
            // runs of equal keys in each file (1-to-many / many-to-many).
            let mut i_end: i32 = i
            while i_end < n1 {
                let g: Vec<String> = split_fields(lines1[i_end], sep_char, use_ws)
                if field_at(g, jf1) == k1 { i_end += 1 } else { break }
            }
            let mut j_end: i32 = j
            while j_end < n2 {
                let g: Vec<String> = split_fields(lines2[j_end], sep_char, use_ws)
                if field_at(g, jf2) == k2 { j_end += 1 } else { break }
            }
            let mut gi: i32 = i
            while gi < i_end {
                let f1g: Vec<String> = split_fields(lines1[gi], sep_char, use_ws)
                let mut gj: i32 = j
                while gj < j_end {
                    let f2g: Vec<String> = split_fields(lines2[gj], sep_char, use_ws)
                    emit_join(k1, f1g, jf1, f2g, jf2, sep)
                    gj += 1
                }
                gi += 1
            }
            i = i_end
            j = j_end
        } else if k1 < k2 {
            if a1 == 1 {
                print_raw(lines1[i])
                print_raw("\n")
            }
            i += 1
        } else {
            if a2 == 1 {
                print_raw(lines2[j])
                print_raw("\n")
            }
            j += 1
        }
    }
    if a1 == 1 {
        while i < n1 {
            print_raw(lines1[i])
            print_raw("\n")
            i += 1
        }
    }
    if a2 == 1 {
        while j < n2 {
            print_raw(lines2[j])
            print_raw("\n")
            j += 1
        }
    }
    return 0
}
