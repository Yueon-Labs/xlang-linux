module main

// sort [-r] [-n] [-u] [-k F[,F]] [-t DELIM] [file] — sort lines.
//   -r reverse, -n numeric, -u unique (suppress duplicates)
//   -k F[,F]  sort by field F (1-indexed) through F2 (default: end of line)
//   -t DELIM  field delimiter (default: whitespace runs)
// Bottom-up merge sort: O(n log n), stable.

fn cmp3(a: String, b: String, numeric: bool, fold: bool): i32 {
    if numeric {
        let va: i32 = str_to_int(a)
        let vb: i32 = str_to_int(b)
        if va != vb {
            if va < vb {
                return -1
            }
            return 1
        }
        // numeric tie: fall through to full-line comparison (GNU last-resort
        // tiebreak; GNU sort is not stable unless -s is given).
    }
    let mut c: i32 = 0
    if fold {
        // -f folds case for the comparison AND the last-resort tiebreak, so
        // folded-equal lines (e.g. "Banana"/"banana") stay in input order
        // (stable) — matching GNU sort -f.
        c = str_cmp(str_lower(a), str_lower(b))
    } else {
        c = str_cmp(a, b)
    }
    if c < 0 {
        return -1
    }
    if c > 0 {
        return 1
    }
    return 0
}

fn merge_sort(lines: Vec<String>, tmp: Vec<String>, count: i32, reverse: bool, numeric: bool, fold: bool): i32 {
    let mut width: i32 = 1
    while width < count {
        let mut i: i32 = 0
        while i < count {
            let lo: i32 = i
            let mut mid: i32 = i + width
            if mid > count {
                mid = count
            }
            let mut hi: i32 = i + 2 * width
            if hi > count {
                hi = count
            }
            let mut a: i32 = lo
            let mut b: i32 = mid
            let mut t: i32 = lo
            while a < mid {
                if b < hi {
                    let c: i32 = cmp3(lines[a], lines[b], numeric, fold)
                    let mut take_a: bool = false
                    if reverse {
                        if c >= 0 {
                            take_a = true
                        }
                    } else {
                        if c <= 0 {
                            take_a = true
                        }
                    }
                    if take_a {
                        tmp[t] = lines[a]
                        a = a + 1
                    } else {
                        tmp[t] = lines[b]
                        b = b + 1
                    }
                    t = t + 1
                } else {
                    tmp[t] = lines[a]
                    a = a + 1
                    t = t + 1
                }
            }
            while b < hi {
                tmp[t] = lines[b]
                b = b + 1
                t = t + 1
            }
            i = i + 2 * width
        }
        let mut c2: i32 = 0
        while c2 < count {
            lines[c2] = tmp[c2]
            c2 = c2 + 1
        }
        width = width * 2
    }
    return 0
}

// Extract a sort key (fields field_lo through field_hi, 1-indexed) from a line.
// use_ws=1 → whitespace-delimited fields; use_ws=0 → single-char delim.
fn extract_key(line: String, field_lo: i32, field_hi: i32, use_ws: i32, delim: i32): String {
    let n: i32 = str_len(line)
    let mut field: i32 = 1
    let mut i: i32 = 0
    if use_ws == 1 {
        while i < n {
            let c: i32 = str_char_at(line, i)
            if c == 32 || c == 9 {
                i = i + 1
            } else {
                break
            }
        }
    }
    let mut key_start: i32 = n
    let mut key_end: i32 = n
    while field <= field_hi && i <= n {
        if field >= field_lo {
            if key_start == n {
                key_start = i
            }
        }
        while i < n {
            let c: i32 = str_char_at(line, i)
            if use_ws == 1 {
                if c == 32 || c == 9 { break }
            } else {
                if c == delim { break }
            }
            i = i + 1
        }
        if field >= field_lo {
            key_end = i
        }
        if use_ws == 1 {
            while i < n {
                let c: i32 = str_char_at(line, i)
                if c == 32 || c == 9 {
                    i = i + 1
                } else {
                    break
                }
            }
        } else {
            if i < n {
                i = i + 1
            }
        }
        field = field + 1
    }
    if key_start >= key_end {
        return ""
    }
    return str_slice(line, key_start, key_end)
}

fn main(): i32 {
    let mut reverse: bool = false
    let mut numeric: bool = false
    let mut unique: bool = false
    let mut fold: bool = false
    let mut file: String = ""
    let key_los: Vec<i32> = vec_new()
    let key_his: Vec<i32> = vec_new()
    let mut use_ws: i32 = 1
    let mut delim: i32 = 32
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-k") {
            if i + 1 < argc() {
                let spec: String = argv(i + 1)
                let comma: i32 = str_find(spec, ",")
                if comma < 0 {
                    key_los.push(str_to_int(spec))
                    key_his.push(0)
                } else {
                    key_los.push(str_to_int(str_slice(spec, 0, comma)))
                    key_his.push(str_to_int(str_slice(spec, comma + 1, str_len(spec))))
                }
                i = i + 1
            }
        } else if str_starts_with(a, "-k") {
            let spec: String = str_slice(a, 2, str_len(a))
            let comma: i32 = str_find(spec, ",")
            if comma < 0 {
                key_los.push(str_to_int(spec))
                key_his.push(0)
            } else {
                key_los.push(str_to_int(str_slice(spec, 0, comma)))
                key_his.push(str_to_int(str_slice(spec, comma + 1, str_len(spec))))
            }
        } else if str_eq(a, "-t") {
            if i + 1 < argc() {
                delim = str_char_at(argv(i + 1), 0)
                use_ws = 0
                i = i + 1
            }
        } else if str_starts_with(a, "-t") {
            delim = str_char_at(a, 2)
            use_ws = 0
        } else if str_char_at(a, 0) == 45 {
            let la: i32 = str_len(a)
            let mut k: i32 = 1
            while k < la {
                let c: i32 = str_char_at(a, k)
                if c == 114 {
                    reverse = true
                }
                if c == 110 {
                    numeric = true
                }
                if c == 117 {
                    unique = true
                }
                if c == 102 {
                    fold = true
                }
                k = k + 1
            }
        } else {
            file = a
        }
        i = i + 1
    }
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let lines: Vec<String> = vec_new()
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut k: i32 = 0
    while k < n {
        if str_char_at(s, k) == 10 {
            lines.push(str_slice(s, start, k))
            start = k + 1
        }
        k = k + 1
    }
    if start < n {
        lines.push(str_slice(s, start, n))
    }
    let count: i32 = vec_len(lines)
    // For -k: Schwartzian transform — prepend key(s) + double separator, sort, strip.
    let nkeys: i32 = vec_len(key_los)
    let mut sort_lines: Vec<String> = vec_new()
    let mut has_sep: i32 = 0
    if nkeys > 0 {
        let dsep: String = str_concat(chr(1), chr(1))
        let ssep: String = chr(1)
        has_sep = 1
        let mut idx: i32 = 0
        while idx < count {
            let mut khi0: i32 = key_his[0]
            if khi0 < key_los[0] {
                khi0 = key_los[0]
            }
            let mut aug: String = extract_key(lines[idx], key_los[0], khi0, use_ws, delim)
            let mut ki: i32 = 1
            while ki < nkeys {
                aug = str_concat(aug, ssep)
                let mut khii: i32 = key_his[ki]
                if khii < key_los[ki] {
                    khii = key_los[ki]
                }
                aug = str_concat(aug, extract_key(lines[idx], key_los[ki], khii, use_ws, delim))
                ki = ki + 1
            }
            aug = str_concat(aug, dsep)
            aug = str_concat(aug, lines[idx])
            sort_lines.push(aug)
            idx = idx + 1
        }
    } else {
        sort_lines = lines
    }
    if count > 0 {
        let tmp: Vec<String> = vec_new()
        let mut z: i32 = 0
        while z < count {
            tmp.push("")
            z = z + 1
        }
        merge_sort(sort_lines, tmp, count, reverse, numeric, fold)
    }
    // Buffer output (one write) — per-line print_raw is N syscalls.
    sb_new()
    let sep_str: String = str_concat(chr(1), chr(1))
    let mut j: i32 = 0
    while j < count {
        if unique {
            if j > 0 {
                if has_sep == 1 {
                    let cur_k: i32 = str_find(sort_lines[j], sep_str)
                    let prev_k: i32 = str_find(sort_lines[j - 1], sep_str)
                    let ck: String = str_slice(sort_lines[j], 0, cur_k)
                    let pk: String = str_slice(sort_lines[j - 1], 0, prev_k)
                    let mut same: bool = false
                    if fold {
                        same = str_eq(str_lower(ck), str_lower(pk))
                    } else {
                        same = str_eq(ck, pk)
                    }
                    if same {
                        j = j + 1
                        continue
                    }
                } else {
                    let mut same: bool = false
                    if fold {
                        same = str_eq(str_lower(sort_lines[j]), str_lower(sort_lines[j - 1]))
                    } else {
                        same = str_eq(sort_lines[j], sort_lines[j - 1])
                    }
                    if same {
                        j = j + 1
                        continue
                    }
                }
            }
        }
        if has_sep == 1 {
            let sp: i32 = str_find(sort_lines[j], sep_str)
            if sp >= 0 {
                sb_push(str_slice(sort_lines[j], sp + 2, str_len(sort_lines[j])))
            } else {
                sb_push(sort_lines[j])
            }
        } else {
            sb_push(sort_lines[j])
        }
        sb_push("\n")
        j = j + 1
    }
    print_raw(sb_str())
    return 0
}
