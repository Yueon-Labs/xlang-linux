module main

// expr ARGS... — evaluate expressions (GNU-compatible subset).
// Supports: + - * / % ( ) for integers, plus comparison: < <= > >= = !=
// Multiple operations are evaluated left-to-right (no precedence, like GNU expr
// without parens). Returns 0 (true) or 1 (false) as exit code for comparisons.
//   expr 6 + 4         expr 7 \* 8     expr 20 / 6
//   expr 3 \< 5         expr 5 = 5      expr 10 % 3

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

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: expr <a> <op> <b> [...]")
        return 2
    }

    // Collect args into a Vec (skip argv[0]).
    let toks: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        toks.push(argv(i))
        i = i + 1
    }
    let nt: i32 = vec_len(toks)

    // Left-to-right evaluation. Start with first token as value.
    let mut val: i32 = 0
    let mut val_is_num: bool = true
    if is_num(toks[0]) {
        val = str_to_int(toks[0])
    } else {
        val_is_num = false
        val = 0
    }

    let mut pos: i32 = 1
    while pos + 1 < nt {
        let op: String = toks[pos]
        let rhs_tok: String = toks[pos + 1]
        let rhs: i32 = str_to_int(rhs_tok)
        let is_cmp: bool = false
        let mut cmp_result: i32 = 0
        let mut did_op: bool = false
        if str_eq(op, "+") {
            val = val + rhs
            did_op = true
        }
        if str_eq(op, "-") {
            val = val - rhs
            did_op = true
        }
        if str_eq(op, "*") {
            val = val * rhs
            did_op = true
        }
        if str_eq(op, "/") {
            val = val / rhs
            did_op = true
        }
        if str_eq(op, "%") {
            val = val - (val / rhs) * rhs
            did_op = true
        }
        if str_eq(op, "<") {
            if val < rhs { val = 1 } else { val = 0 }
            did_op = true
        }
        if str_eq(op, "<=") {
            if val <= rhs { val = 1 } else { val = 0 }
            did_op = true
        }
        if str_eq(op, ">") {
            if val > rhs { val = 1 } else { val = 0 }
            did_op = true
        }
        if str_eq(op, ">=") {
            if val >= rhs { val = 1 } else { val = 0 }
            did_op = true
        }
        if str_eq(op, "=") {
            if val == rhs { val = 1 } else { val = 0 }
            did_op = true
        }
        if str_eq(op, "!=") {
            if val != rhs { val = 1 } else { val = 0 }
            did_op = true
        }
        pos = pos + 2
    }

    // Output and exit code.
    print_raw(int_to_str(val))
    print_raw("\n")
    if val == 0 { return 1 }
    return 0
}
