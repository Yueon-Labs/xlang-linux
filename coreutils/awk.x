module main

// awk [-F sep] 'PROGRAM' [file] — minimal text processor.
// PROGRAM forms:
//   {print ...}            every line
//   PATTERN{print ...}     lines matching PATTERN
//   PATTERN                 lines matching PATTERN (default action: print $0)
// PATTERN: NR==N / NR!=N / NR<N / NR>N / NR<=N / NR>=N  (N a number)
// print items (comma-separated, space-joined): $0  $N  NR  NF  "literal"
// `print` alone prints $0. Field sep: whitespace (default) or -F char.

fn is_digit(c: i32): bool {
    if c < 48 { return false }
    if c > 57 { return false }
    return true
}

fn trim_s(s: String): String {
    let n: i32 = str_len(s)
    let mut a: i32 = 0
    while a < n {
        if str_char_at(s, a) == 32 { a = a + 1 } else { break }
    }
    let mut b: i32 = n
    while b > a {
        if str_char_at(s, b - 1) == 32 { b = b - 1 } else { break }
    }
    return str_slice(s, a, b)
}

fn split_on(s: String, sep: i32): Vec<String> {
    let v: Vec<String> = vec_new()
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i <= n {
        if i == n || str_char_at(s, i) == sep {
            v.push(str_slice(s, start, i))
            start = i + 1
        }
        i = i + 1
    }
    return v
}

fn split_fields(line: String, sep: i32): Vec<String> {
    let v: Vec<String> = vec_new()
    let n: i32 = str_len(line)
    let mut start: i32 = -1
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(line, i)
        let mut is_sep: bool = false
        if sep == 0 {
            is_sep = c == 32 || c == 9
        } else {
            is_sep = c == sep
        }
        if is_sep {
            if start >= 0 {
                v.push(str_slice(line, start, i))
                start = -1
            }
        } else {
            if start < 0 {
                start = i
            }
        }
        i = i + 1
    }
    if start >= 0 {
        v.push(str_slice(line, start, n))
    }
    return v
}

fn eval_item(item: String, line: String, fields: Vec<String>, lineno: i32, nf: i32): String {
    let it: String = trim_s(item)
    if str_eq(it, "$0") { return line }
    if str_eq(it, "NR") { return int_to_str(lineno) }
    if str_eq(it, "NF") { return int_to_str(nf) }
    if str_char_at(it, 0) == 36 {
        let idx: i32 = str_to_int(str_slice(it, 1, str_len(it)))
        if idx >= 1 {
            if idx <= nf { return fields[idx - 1] }
        }
        return ""
    }
    let il: i32 = str_len(it)
    if il >= 2 {
        if str_char_at(it, 0) == 34 && str_char_at(it, il - 1) == 34 {
            return str_slice(it, 1, il - 1)
        }
    }
    return it
}

fn parse_op(pattern: String): i32 {
    let p: i32 = str_find(pattern, "NR")
    let rest: String = str_slice(pattern, p + 2, str_len(pattern))
    let r0: i32 = str_char_at(rest, 0)
    let r1: i32 = str_char_at(rest, 1)
    if r0 == 61 { return 0 }
    if r0 == 33 { return 1 }
    if r0 == 60 {
        if r1 == 61 { return 2 }
        return 3
    }
    if r0 == 62 {
        if r1 == 61 { return 4 }
        return 5
    }
    return 0
}

fn parse_num(pattern: String): i32 {
    let p: i32 = str_find(pattern, "NR")
    let rest: String = trim_s(str_slice(pattern, p + 2, str_len(pattern)))
    let rn: i32 = str_len(rest)
    let mut i: i32 = 0
    while i < rn {
        let c: i32 = str_char_at(rest, i)
        if c == 61 || c == 33 || c == 60 || c == 62 {
            i = i + 1
        } else {
            break
        }
    }
    let mut sign: i32 = 1
    if i < rn {
        if str_char_at(rest, i) == 45 {
            sign = -1
            i = i + 1
        }
    }
    let mut val: i32 = 0
    while i < rn {
        if is_digit(str_char_at(rest, i)) {
            val = val * 10 + (str_char_at(rest, i) - 48)
            i = i + 1
        } else {
            break
        }
    }
    return val * sign
}

fn pattern_matches(op: i32, num: i32, lineno: i32): bool {
    if op == 0 { return lineno == num }
    if op == 1 { return lineno != num }
    if op == 2 { return lineno <= num }
    if op == 3 { return lineno < num }
    if op == 4 { return lineno >= num }
    if op == 5 { return lineno > num }
    return false
}

fn main(): i32 {
    let mut sep: i32 = 0
    let mut prog: String = ""
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_find(a, "-F") == 0 {
            sep = str_char_at(a, 2)
        } else {
            if str_len(prog) == 0 {
                prog = a
            } else {
                file = a
            }
        }
        i = i + 1
    }

    // Extract BEGIN{...} and END{...} blocks (if any), leaving the body rule.
    // Scan ALL {...} blocks; first non-BEGIN/END is the body.
    let mut begin_action: String = ""
    let mut end_action: String = ""
    let mut body_prog: String = prog
    let mut bp: i32 = 0
    let mut found_body: i32 = 0
    while bp < str_len(prog) {
        let brace_at: i32 = str_find_from(prog, "{", bp)
        if brace_at < 0 { break }
        let close_at: i32 = str_find_from(prog, "}", brace_at + 1)
        if close_at < 0 { break }
        let pat_str: String = trim_s(str_slice(prog, bp, brace_at))
        let act_str: String = trim_s(str_slice(prog, brace_at + 1, close_at))
        if str_eq(pat_str, "BEGIN") {
            begin_action = act_str
        } else {
            if str_eq(pat_str, "END") {
                end_action = act_str
            } else {
                if found_body == 0 {
                    body_prog = str_concat(str_concat(pat_str, " {"), str_concat(act_str, "}"))
                    found_body = 1
                }
            }
        }
        bp = close_at + 1
    }

    let pn: i32 = str_len(body_prog)
    let brace: i32 = str_find(body_prog, "{")
    let mut pattern: String = ""
    let mut action: String = "print"
    if brace >= 0 {
        pattern = trim_s(str_slice(body_prog, 0, brace))
        let close: i32 = str_find(body_prog, "}")
        action = trim_s(str_slice(body_prog, brace + 1, close))
    } else {
        pattern = trim_s(body_prog)
    }
    let mut items: Vec<String> = vec_new()
    if str_find(action, "print") == 0 {
        let rest: String = trim_s(str_slice(action, 5, str_len(action)))
        if str_len(rest) > 0 {
            items = split_on(rest, 44)
        }
    }
    let has_pattern: bool = str_len(pattern) > 0
    let mut op: i32 = 0
    if has_pattern {
        op = parse_op(pattern)
    }
    let mut num: i32 = 0
    if has_pattern {
        num = parse_num(pattern)
    }
    let mut is_regex: i32 = 0
    let mut pat_body: String = ""
    if has_pattern {
        let pl: i32 = str_len(pattern)
        if pl >= 2 {
            if str_char_at(pattern, 0) == 47 && str_char_at(pattern, pl - 1) == 47 {
                is_regex = 1
                pat_body = str_slice(pattern, 1, pl - 1)
            }
        }
    }

    // Helper: execute a print action string (e.g. "print \"hello\"" or "print NR").
    let begin_items: Vec<String> = vec_new()
    let end_items: Vec<String> = vec_new()
    if str_len(begin_action) > 0 {
        if str_find(begin_action, "print") == 0 {
            let rest: String = trim_s(str_slice(begin_action, 5, str_len(begin_action)))
            if str_len(rest) > 0 {
                let tmp: Vec<String> = split_on(rest, 44)
                let tn: i32 = vec_len(tmp)
                let mut ti: i32 = 0
                while ti < tn {
                    begin_items.push(tmp[ti])
                    ti = ti + 1
                }
            }
        }
    }
    if str_len(end_action) > 0 {
        if str_find(end_action, "print") == 0 {
            let rest: String = trim_s(str_slice(end_action, 5, str_len(end_action)))
            if str_len(rest) > 0 {
                let tmp: Vec<String> = split_on(rest, 44)
                let tn: i32 = vec_len(tmp)
                let mut ti: i32 = 0
                while ti < tn {
                    end_items.push(tmp[ti])
                    ti = ti + 1
                }
            }
        }
    }

    // Buffer the whole BEGIN/body/END output in one StringBuilder, then a
    // single write — print-actions emit one print_raw per item/line, which on
    // large input is a syscall storm. Output is ~proportional to input.
    sb_new()

    // Execute BEGIN block (lineno=0, no line data).
    if vec_len(begin_items) > 0 {
        let empty_fields: Vec<String> = vec_new()
        let ic: i32 = vec_len(begin_items)
        let mut j: i32 = 0
        while j < ic {
            if j > 0 { sb_push(" ") }
            sb_push(eval_item(begin_items[j], "", empty_fields, 0, 0))
            j = j + 1
        }
        sb_push("\n")
    } else {
        if str_len(begin_action) > 0 {
            if str_find(begin_action, "print") != 0 {
                sb_push(begin_action)
                sb_push("\n")
            }
        }
    }

    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let n: i32 = str_len(s)
    let mut lineno: i32 = 0
    let mut start: i32 = 0
    let mut p: i32 = 0
    while p <= n {
        let at_nl: bool = p < n && str_char_at(s, p) == 10
        let at_end: bool = p == n && start < n
        if !at_nl && !at_end {
            p = p + 1
            continue
        }
        lineno = lineno + 1
        let line: String = str_slice(s, start, p)
        let mut do_act: bool = false
        if !has_pattern {
            do_act = true
        } else {
            if is_regex == 1 {
                if regex_match(line, pat_body) == 1 { do_act = true }
            } else {
                if pattern_matches(op, num, lineno) { do_act = true }
            }
        }
        if do_act {
            let fields: Vec<String> = split_fields(line, sep)
            let nf: i32 = vec_len(fields)
            let ic: i32 = vec_len(items)
            if ic == 0 {
                sb_push(line)
                sb_push("\n")
            } else {
                let mut j: i32 = 0
                while j < ic {
                    if j > 0 {
                        sb_push(" ")
                    }
                    sb_push(eval_item(items[j], line, fields, lineno, nf))
                    j = j + 1
                }
                sb_push("\n")
            }
        }
        start = p + 1
        p = p + 1
    }

    // Execute END block (lineno = final count).
    if vec_len(end_items) > 0 {
        let empty_fields: Vec<String> = vec_new()
        let ic: i32 = vec_len(end_items)
        let mut j: i32 = 0
        while j < ic {
            if j > 0 { sb_push(" ") }
            sb_push(eval_item(end_items[j], "", empty_fields, lineno, 0))
            j = j + 1
        }
        sb_push("\n")
    } else {
        if str_len(end_action) > 0 {
            if str_find(end_action, "print") != 0 {
                sb_push(end_action)
                sb_push("\n")
            }
        }
    }

    print_raw(sb_str())
    return 0
}
