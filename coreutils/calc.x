module main

// calc <expr> — evaluate a floating-point arithmetic expression.
// Supports + - * / ( ) and precedence. Demonstrates xlang's modern features:
// for-in, match, f64, recursion, Vec.
//   calc "1 + 2 * 3"    → 7
//   calc "(1 + 2) * 3"  → 9
//   calc "3.14 * 2"     → 6.28

struct Tok {
    kind: i32     // 0=number, 1=op, 2=lparen, 3=rparen, 4=end
    num: f64
    op: i32
}

// Tokenize the expression string.
fn tokenize(s: String): Vec<Tok> {
    let toks: Vec<Tok> = vec_new()
    let n: i32 = str_len(s)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c == 32 {
            i = i + 1
        } else {
            if c == 40 {
                toks.push(Tok { kind: 2, num: 0.0, op: 0 })
                i = i + 1
            } else {
                if c == 41 {
                    toks.push(Tok { kind: 3, num: 0.0, op: 0 })
                    i = i + 1
                } else {
                    if c == 43 || c == 45 || c == 42 || c == 47 {
                        toks.push(Tok { kind: 1, num: 0.0, op: c })
                        i = i + 1
                    } else {
                        if c >= 48 {
                            if c <= 57 {
                                let mut v: f64 = 0.0
                                while i < n {
                                    let d: i32 = str_char_at(s, i)
                                    if d >= 48 {
                                        if d <= 57 {
                                            v = v * 10.0 + int_to_f64(d - 48)
                                            i = i + 1
                                        } else { break }
                                    } else { break }
                                }
                                if i < n {
                                    if str_char_at(s, i) == 46 {
                                        i = i + 1
                                        let mut frac: f64 = 0.0
                                        let mut div: f64 = 10.0
                                        while i < n {
                                            let d: i32 = str_char_at(s, i)
                                            if d >= 48 {
                                                if d <= 57 {
                                                    frac = frac + int_to_f64(d - 48) / div
                                                    div = div * 10.0
                                                    i = i + 1
                                                } else { break }
                                            } else { break }
                                        }
                                        v = v + frac
                                    }
                                }
                                toks.push(Tok { kind: 0, num: v, op: 0 })
                            } else {
                                i = i + 1
                            }
                        } else {
                            i = i + 1
                        }
                    }
                }
            }
        }
    }
    toks.push(Tok { kind: 4, num: 0.0, op: 0 })
    return toks
}

// Recursive-descent parser. Position tracked in a Vec<i32> (heap, shared).
fn parse_factor(toks: Vec<Tok>, pos: Vec<i32>): f64 {
    let n: i32 = vec_len(toks)
    if pos[0] >= n { return 0.0 }
    let tk: Tok = toks[pos[0]]
    if tk.kind == 0 {
        pos[0] = pos[0] + 1
        return tk.num
    }
    if tk.kind == 2 {
        pos[0] = pos[0] + 1
        let v: f64 = parse_expr(toks, pos)
        if pos[0] < n {
            if toks[pos[0]].kind == 3 {
                pos[0] = pos[0] + 1
            }
        }
        return v
    }
    if tk.kind == 1 {
        if tk.op == 45 {
            pos[0] = pos[0] + 1
            return 0.0 - parse_factor(toks, pos)
        }
    }
    return 0.0
}

fn parse_term(toks: Vec<Tok>, pos: Vec<i32>): f64 {
    let mut v: f64 = parse_factor(toks, pos)
    let n: i32 = vec_len(toks)
    while pos[0] < n {
        let tk: Tok = toks[pos[0]]
        if tk.kind == 1 {
            if tk.op == 42 {
                pos[0] = pos[0] + 1
                v = v * parse_factor(toks, pos)
            } else {
                if tk.op == 47 {
                    pos[0] = pos[0] + 1
                    v = v / parse_factor(toks, pos)
                } else { break }
            }
        } else { break }
    }
    return v
}

fn parse_expr(toks: Vec<Tok>, pos: Vec<i32>): f64 {
    let mut v: f64 = parse_term(toks, pos)
    let n: i32 = vec_len(toks)
    while pos[0] < n {
        let tk: Tok = toks[pos[0]]
        if tk.kind == 1 {
            if tk.op == 43 {
                pos[0] = pos[0] + 1
                v = v + parse_term(toks, pos)
            } else {
                if tk.op == 45 {
                    pos[0] = pos[0] + 1
                    v = v - parse_term(toks, pos)
                } else { break }
            }
        } else { break }
    }
    return v
}

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: calc <expr>")
        return 1
    }
    let toks: Vec<Tok> = tokenize(argv(1))
    let pos: Vec<i32> = vec_new()
    pos.push(0)
    let result: f64 = parse_expr(toks, pos)
    print_raw(float_to_str(result))
    print_raw("\n")
    return 0
}
