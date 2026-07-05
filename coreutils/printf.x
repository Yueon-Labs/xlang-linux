module main

// printf FORMAT [args...] — formatted output (like GNU printf).
// Spec: %[flags][width][.precision]specifier
//   flags: - (left), 0 (zero-pad), + / space (sign)
//   specifier: d i o u x X s c f  and %%
// Escapes: \n \t \r \\
// Cycles FORMAT through all args (bash behavior).

fn int_to_hex(v: i32, upper: i32): String {
    if v == 0 { return "0" }
    let lower: String = "0123456789abcdef"
    let UPPER: String = "0123456789ABCDEF"
    let digits: String = if upper == 1 { UPPER } else { lower }
    let mut val: i32 = v
    let mut result: String = ""
    while val > 0 {
        let d: i32 = val & 15
        result = str_concat(str_slice(digits, d, d + 1), result)
        val = val >> 4
    }
    return result
}

fn int_to_oct(v: i32): String {
    if v == 0 { return "0" }
    let mut val: i32 = v
    let mut result: String = ""
    while val > 0 {
        result = str_concat(str_slice("01234567", val & 7, (val & 7) + 1), result)
        val = val >> 3
    }
    return result
}

// Right/left-pad s to `width`. left=1 → spaces on right; zero=1 (and not left)
// → '0' on left; else spaces on left.
fn pad_value(s: String, width: i32, left: i32, zero: i32): String {
    let len: i32 = str_len(s)
    if len >= width {
        return s
    }
    let padlen: i32 = width - len
    let mut result: String = s
    let mut k: i32 = 0
    if left == 1 {
        while k < padlen {
            result = str_concat(result, " ")
            k = k + 1
        }
    } else {
        if zero == 1 {
            while k < padlen {
                result = str_concat("0", result)
                k = k + 1
            }
        } else {
            while k < padlen {
                result = str_concat(" ", result)
                k = k + 1
            }
        }
    }
    return result
}

// Does the format contain at least one argument-consuming specifier?
fn has_spec(fmt: String): i32 {
    let n: i32 = str_len(fmt)
    let mut i: i32 = 0
    while i < n {
        if str_char_at(fmt, i) == 37 {
            let mut j: i32 = i + 1
            // skip flags / width / precision
            while j < n {
                let fc: i32 = str_char_at(fmt, j)
                if fc == 45 || fc == 48 || fc == 43 || fc == 32 || fc == 35 {
                    j = j + 1
                } else {
                    break
                }
            }
            while j < n {
                let fc: i32 = str_char_at(fmt, j)
                if fc >= 48 && fc <= 57 {
                    j = j + 1
                } else {
                    break
                }
            }
            if j < n {
                if str_char_at(fmt, j) == 46 {
                    j = j + 1
                    while j < n {
                        let fc: i32 = str_char_at(fmt, j)
                        if fc >= 48 && fc <= 57 {
                            j = j + 1
                        } else {
                            break
                        }
                    }
                }
            }
            if j < n {
                let s: i32 = str_char_at(fmt, j)
                if s == 100 || s == 105 || s == 111 || s == 117 || s == 120 || s == 88 || s == 115 || s == 99 || s == 102 {
                    return 1
                }
            }
        }
        i = i + 1
    }
    return 0
}

fn print_pass(fmt: String, arg_idx: i32): i32 {
    let n: i32 = str_len(fmt)
    let mut i: i32 = 0
    let mut ai: i32 = arg_idx
    sb_new()
    while i < n {
        let c: i32 = str_char_at(fmt, i)
        if c == 92 {
            if i + 1 < n {
                let e: i32 = str_char_at(fmt, i + 1)
                if e == 110 {
                    sb_push_char(10)
                } else {
                    if e == 116 {
                        sb_push_char(9)
                    } else {
                        if e == 114 {
                            sb_push_char(13)
                        } else {
                            sb_push_char(e)
                        }
                    }
                }
                i = i + 2
            } else {
                sb_push_char(92)
                i = i + 1
            }
        } else {
            if c == 37 {
                // Parse %[flags][width][.precision]specifier
                let mut j: i32 = i + 1
                let mut left: i32 = 0
                let mut zero: i32 = 0
                let mut plus: i32 = 0
                let mut space: i32 = 0
                while j < n {
                    let fc: i32 = str_char_at(fmt, j)
                    if fc == 45 {
                        left = 1
                        j = j + 1
                    } else {
                        if fc == 48 {
                            zero = 1
                            j = j + 1
                        } else {
                            if fc == 43 {
                                plus = 1
                                j = j + 1
                            } else {
                                if fc == 32 {
                                    space = 1
                                    j = j + 1
                                } else {
                                    break
                                }
                            }
                        }
                    }
                }
                let mut width: i32 = 0
                while j < n {
                    let wc: i32 = str_char_at(fmt, j)
                    if wc >= 48 && wc <= 57 {
                        width = width * 10 + (wc - 48)
                        j = j + 1
                    } else {
                        break
                    }
                }
                let mut prec: i32 = -1
                if j < n {
                    if str_char_at(fmt, j) == 46 {
                        j = j + 1
                        prec = 0
                        while j < n {
                            let pc: i32 = str_char_at(fmt, j)
                            if pc >= 48 && pc <= 57 {
                                prec = prec * 10 + (pc - 48)
                                j = j + 1
                            } else {
                                break
                            }
                        }
                    }
                }
                if j < n {
                    let spec: i32 = str_char_at(fmt, j)
                    j = j + 1
                    i = j
                    if spec == 37 {
                        sb_push_char(37)
                    } else {
                        if spec == 115 {
                            let mut val: String = ""
                            if ai < argc() {
                                val = argv(ai)
                                ai = ai + 1
                            }
                            if prec >= 0 {
                                if prec < str_len(val) {
                                    val = str_slice(val, 0, prec)
                                }
                            }
                            sb_push(pad_value(val, width, left, 0))
                        } else {
                            if spec == 99 {
                                let mut ch: i32 = 0
                                if ai < argc() {
                                    ch = str_char_at(argv(ai), 0)
                                    ai = ai + 1
                                }
                                let cs: String = chr(ch)
                                sb_push(pad_value(cs, width, left, 0))
                            } else {
                                if spec == 102 {
                                    let mut val: String = "0"
                                    if ai < argc() {
                                        val = argv(ai)
                                        ai = ai + 1
                                    }
                                    let fs: String = float_to_str(str_to_float(val))
                                    sb_push(pad_value(fs, width, left, 0))
                                } else {
                                    // integer specifiers: d i o u x X
                                    let mut val: i32 = 0
                                    if ai < argc() {
                                        val = str_to_int(argv(ai))
                                        ai = ai + 1
                                    }
                                    let mut vs: String = ""
                                    if spec == 120 {
                                        vs = int_to_hex(val, 0)
                                    } else {
                                        if spec == 88 {
                                            vs = int_to_hex(val, 1)
                                        } else {
                                            if spec == 111 {
                                                vs = int_to_oct(val)
                                            } else {
                                                vs = int_to_str(val)
                                            }
                                        }
                                    }
                                    // sign prefix for +/space on non-negative
                                    if val >= 0 {
                                        if plus == 1 {
                                            vs = str_concat("+", vs)
                                        } else {
                                            if space == 1 {
                                                vs = str_concat(" ", vs)
                                            }
                                        }
                                    }
                                    // zero-pad shouldn't pad past a sign
                                    let mut use_zero: i32 = zero
                                    if left == 1 {
                                        use_zero = 0
                                    }
                                    sb_push(pad_value(vs, width, left, use_zero))
                                }
                            }
                        }
                    }
                } else {
                    // trailing % with no specifier
                    sb_push_char(37)
                    i = n
                }
            } else {
                sb_push_char(c)
                i = i + 1
            }
        }
    }
    print_raw(sb_str())
    return ai
}

fn main(): i32 {
    if argc() < 2 {
        return 0
    }
    let fmt: String = argv(1)
    if has_spec(fmt) == 0 {
        print_pass(fmt, argc())
        return 0
    }
    let mut ai: i32 = 2
    while true {
        let prev: i32 = ai
        ai = print_pass(fmt, ai)
        if ai >= argc() {
            break
        }
        if ai == prev {
            break
        }
    }
    return 0
}
