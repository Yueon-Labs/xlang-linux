module main

// expr ARGS... — evaluate expressions (GNU expr compatible).
// Precedence (low→high): |  &  = !=  < <= > >=  + -  * / %  :
// Plus: ( ), integers, string/numeric comparison, regex match `:`
// (anchored, returns match length), and the string functions
// length / substr / index / match. Evaluated via shunting-yard (infix→RPN)
// then an RPN evaluator — both iterative.

fn is_num(s: String): bool {
    let n: i32 = str_len(s)
    if n == 0 { return false }
    let mut i: i32 = 0
    if str_char_at(s, 0) == 45 {
        if n == 1 { return false }
        i = 1
    }
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c < 48 { return false }
        if c > 57 { return false }
        i = i + 1
    }
    return true
}

fn to_int(s: String): i32 {
    if is_num(s) { return str_to_int(s) }
    return 0
}

// Operator precedence (0 = not an operator). All left-associative.
fn prec(op: String): i32 {
    if str_eq(op, "|") { return 1 }
    if str_eq(op, "&") { return 2 }
    if str_eq(op, "=") { return 3 }
    if str_eq(op, "!=") { return 3 }
    if str_eq(op, "<") { return 4 }
    if str_eq(op, "<=") { return 4 }
    if str_eq(op, ">") { return 4 }
    if str_eq(op, ">=") { return 4 }
    if str_eq(op, "+") { return 5 }
    if str_eq(op, "-") { return 5 }
    if str_eq(op, "*") { return 6 }
    if str_eq(op, "/") { return 6 }
    if str_eq(op, "%") { return 6 }
    if str_eq(op, ":") { return 7 }
    return 0
}

// Compare two operand strings; numeric if both are integers, else string.
fn cmp_args(a: String, b: String): i32 {
    if is_num(a) {
        if is_num(b) {
            let va: i32 = str_to_int(a)
            let vb: i32 = str_to_int(b)
            if va < vb { return -1 }
            if va > vb { return 1 }
            return 0
        }
    }
    let c: i32 = str_cmp(a, b)
    return c
}

// index STRING CHARS → 1-indexed position of the first STRING char that
// appears anywhere in CHARS, or 0 if none (GNU index, not substring search).
fn index_fn(s: String, chars: String): i32 {
    let n: i32 = str_len(s)
    let cn: i32 = str_len(chars)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        let mut j: i32 = 0
        while j < cn {
            if str_char_at(chars, j) == c {
                return i + 1
            }
            j = j + 1
        }
        i = i + 1
    }
    return 0
}

// `a : b` — regex match anchored at the start; returns the matched length
// (0 if no match). Uses ERE; close to GNU BRE for common patterns.
fn match_op(a: String, b: String): i32 {
    let start: i32 = regex_find_from(a, b, 0)
    if start != 0 {
        return 0
    }
    return regex_match_len()
}

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: expr <expression>")
        return 2
    }
    // Collect args into a mutable token vector (functions get rewritten in place).
    let toks: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        toks.push(argv(i))
        i = i + 1
    }
    let nt: i32 = vec_len(toks)

    // Pre-process the string functions (length/substr/index/match) into single
    // value tokens. Each consumes a fixed number of following args.
    let simplified: Vec<String> = vec_new()
    let mut p: i32 = 0
    while p < nt {
        let t: String = toks[p]
        if str_eq(t, "length") {
            if p + 1 < nt {
                simplified.push(int_to_str(str_len(toks[p + 1])))
                p = p + 2
            } else {
                p = p + 1
            }
        } else {
            if str_eq(t, "index") {
                if p + 2 < nt {
                    simplified.push(int_to_str(index_fn(toks[p + 1], toks[p + 2])))
                    p = p + 3
                } else {
                    p = p + 1
                }
            } else {
                if str_eq(t, "substr") {
                    if p + 3 < nt {
                        let s: String = toks[p + 1]
                        let pos: i32 = str_to_int(toks[p + 2])
                        let len: i32 = str_to_int(toks[p + 3])
                        let sn: i32 = str_len(s)
                        let mut start: i32 = pos - 1
                        if start < 0 { start = 0 }
                        let mut e: i32 = start + len
                        if e > sn { e = sn }
                        if start > sn { start = sn }
                        simplified.push(str_slice(s, start, e))
                        p = p + 4
                    } else {
                        p = p + 1
                    }
                } else {
                    if str_eq(t, "match") {
                        // match STRING REGEX → like `:`, returns match length.
                        if p + 2 < nt {
                            simplified.push(int_to_str(match_op(toks[p + 1], toks[p + 2])))
                            p = p + 3
                        } else {
                            p = p + 1
                        }
                    } else {
                        simplified.push(t)
                        p = p + 1
                    }
                }
            }
        }
    }

    let sn: i32 = vec_len(simplified)
    // Bare value (no operator) — just print it (GNU expr "foo" → "foo").
    if sn == 1 {
        let out: String = simplified[0]
        print_raw(out)
        print_raw("\n")
        if is_num(out) {
            if str_to_int(out) == 0 { return 1 }
        } else {
            if str_len(out) == 0 { return 1 }
        }
        return 0
    }

    // Shunting-yard: infix → RPN.
    let rpn: Vec<String> = vec_new()
    let ops: Vec<String> = vec_new()
    let mut q: i32 = 0
    while q < sn {
        let tk: String = simplified[q]
        if str_eq(tk, "(") {
            ops.push(tk)
        } else {
            if str_eq(tk, ")") {
                let mut done: i32 = 0
                while vec_len(ops) > 0 {
                    let top: String = ops[vec_len(ops) - 1]
                    if str_eq(top, "(") {
                        ops.pop()
                        done = 1
                        break
                    }
                    rpn.push(top)
                    ops.pop()
                }
                if done == 0 { return 2 }
            } else {
                let pr: i32 = prec(tk)
                if pr > 0 {
                    while vec_len(ops) > 0 {
                        let top: String = ops[vec_len(ops) - 1]
                        if str_eq(top, "(") { break }
                        if prec(top) >= pr {
                            rpn.push(top)
                            ops.pop()
                        } else {
                            break
                        }
                    }
                    ops.push(tk)
                } else {
                    rpn.push(tk)
                }
            }
        }
        q = q + 1
    }
    while vec_len(ops) > 0 {
        let top: String = ops[vec_len(ops) - 1]
        rpn.push(top)
        ops.pop()
    }

    // Evaluate RPN.
    let st: Vec<String> = vec_new()
    let rn: i32 = vec_len(rpn)
    let mut r: i32 = 0
    while r < rn {
        let tk: String = rpn[r]
        let pr: i32 = prec(tk)
        if pr > 0 {
            if vec_len(st) < 2 { return 2 }
            let b: String = st[vec_len(st) - 1]
            st.pop()
            let a: String = st[vec_len(st) - 1]
            st.pop()
            let mut res: String = "0"
            if str_eq(tk, "+") {
                res = int_to_str(to_int(a) + to_int(b))
            }
            if str_eq(tk, "-") {
                res = int_to_str(to_int(a) - to_int(b))
            }
            if str_eq(tk, "*") {
                res = int_to_str(to_int(a) * to_int(b))
            }
            if str_eq(tk, "/") {
                let bv: i32 = to_int(b)
                if bv == 0 {
                    eprint_str("expr: division by zero")
                    return 2
                }
                res = int_to_str(to_int(a) / bv)
            }
            if str_eq(tk, "%") {
                let bv: i32 = to_int(b)
                if bv == 0 {
                    eprint_str("expr: division by zero")
                    return 2
                }
                res = int_to_str(to_int(a) - (to_int(a) / bv) * bv)
            }
            if str_eq(tk, "<") {
                res = int_to_str(if cmp_args(a, b) < 0 { 1 } else { 0 })
            }
            if str_eq(tk, "<=") {
                res = int_to_str(if cmp_args(a, b) <= 0 { 1 } else { 0 })
            }
            if str_eq(tk, ">") {
                res = int_to_str(if cmp_args(a, b) > 0 { 1 } else { 0 })
            }
            if str_eq(tk, ">=") {
                res = int_to_str(if cmp_args(a, b) >= 0 { 1 } else { 0 })
            }
            if str_eq(tk, "=") {
                res = int_to_str(if cmp_args(a, b) == 0 { 1 } else { 0 })
            }
            if str_eq(tk, "!=") {
                res = int_to_str(if cmp_args(a, b) != 0 { 1 } else { 0 })
            }
            if str_eq(tk, ":") {
                res = int_to_str(match_op(a, b))
            }
            if str_eq(tk, "&") {
                // & : if either arg is 0/empty, result is 0; else the first.
                let za: i32 = if is_num(a) { if str_to_int(a) == 0 { 1 } else { 0 } } else { if str_len(a) == 0 { 1 } else { 0 } }
                let zb: i32 = if is_num(b) { if str_to_int(b) == 0 { 1 } else { 0 } } else { if str_len(b) == 0 { 1 } else { 0 } }
                if za == 1 { res = "0" } else { if zb == 1 { res = "0" } else { res = a } }
            }
            if str_eq(tk, "|") {
                // | : if first is non-zero, it; else second.
                let za: i32 = if is_num(a) { if str_to_int(a) == 0 { 1 } else { 0 } } else { if str_len(a) == 0 { 1 } else { 0 } }
                if za == 0 { res = a } else { res = b }
            }
            st.push(res)
        } else {
            st.push(tk)
        }
        r = r + 1
    }

    if vec_len(st) != 1 { return 2 }
    let out: String = st[0]
    print_raw(out)
    print_raw("\n")
    // Exit code: 0 if non-zero/non-empty, 1 if zero/empty, 2 on syntax error.
    if is_num(out) {
        if str_to_int(out) == 0 { return 1 }
    } else {
        if str_len(out) == 0 { return 1 }
    }
    return 0
}
