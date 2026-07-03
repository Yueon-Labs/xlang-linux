module main

// seq — print numbers. Integer and float modes.
//   seq LAST                     → 1 2 ... LAST
//   seq FIRST LAST              → FIRST ... LAST
//   seq FIRST STEP LAST         → with custom step
// Float mode auto-detected when any arg contains '.'. Uses f64 throughout.
// Handles positive and negative steps (countdown).

fn has_dot(s: String): bool {
    let n: i32 = str_len(s)
    let mut i: i32 = 0
    while i < n {
        if str_char_at(s, i) == 46 { return true }
        i = i + 1
    }
    return false
}

fn main(): i32 {
    let mut want_w: i32 = 0
    let mut any_float: i32 = 0
    let pos: Vec<String> = vec_new()
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if a == "-w" {
            want_w = 1
        } else {
            pos.push(a)
            if has_dot(a) { any_float = 1 }
        }
        ai = ai + 1
    }
    let np: i32 = vec_len(pos)
    if np == 0 {
        print_str("usage: seq [-w] <last> | <first> <last> | <first> <step> <last>")
        return 1
    }

    if any_float == 1 {
        let mut first: f64 = 1.0
        let mut step: f64 = 1.0
        let mut last: f64 = 0.0
        if np == 1 {
            last = str_to_float(pos[0])
        } else {
            if np == 2 {
                first = str_to_float(pos[0])
                last = str_to_float(pos[1])
            } else {
                first = str_to_float(pos[0])
                step = str_to_float(pos[1])
                last = str_to_float(pos[2])
            }
        }
        if step == 0.0 {
            print_str("seq: step cannot be zero")
            return 1
        }
        let mut i: f64 = first
        let mut cnt: i32 = 0
        sb_new()
        if step > 0.0 {
            while i <= last {
                sb_push(float_to_str(i))
                sb_push("\n")
                cnt = cnt + 1
                if cnt >= 16384 {
                    print_raw(sb_str())
                    sb_new()
                    cnt = 0
                }
                i = i + step
            }
        } else {
            while i >= last {
                sb_push(float_to_str(i))
                sb_push("\n")
                cnt = cnt + 1
                if cnt >= 16384 {
                    print_raw(sb_str())
                    sb_new()
                    cnt = 0
                }
                i = i + step
            }
        }
        print_raw(sb_str())
    } else {
        let mut first: i32 = 1
        let mut step: i32 = 1
        let mut last: i32 = 0
        if np == 1 {
            last = str_to_int(pos[0])
        } else {
            if np == 2 {
                first = str_to_int(pos[0])
                last = str_to_int(pos[1])
            } else {
                first = str_to_int(pos[0])
                step = str_to_int(pos[1])
                last = str_to_int(pos[2])
            }
        }
        if step == 0 {
            print_str("seq: step cannot be zero")
            return 1
        }
        let mut width: i32 = 0
        if want_w == 1 {
            let wf: i32 = str_len(int_to_str(first))
            let wl: i32 = str_len(int_to_str(last))
            width = wf
            if wl > width { width = wl }
        }
        let mut i: i32 = first
        let mut cnt: i32 = 0
        sb_new()
        if step > 0 {
            while i <= last {
                if want_w == 1 {
                    sb_push(pad_zero(i, width))
                } else {
                    sb_push(int_to_str(i))
                }
                sb_push("\n")
                cnt = cnt + 1
                if cnt >= 16384 {
                    print_raw(sb_str())
                    sb_new()
                    cnt = 0
                }
                i = i + step
            }
        } else {
            while i >= last {
                if want_w == 1 {
                    sb_push(pad_zero(i, width))
                } else {
                    sb_push(int_to_str(i))
                }
                sb_push("\n")
                cnt = cnt + 1
                if cnt >= 16384 {
                    print_raw(sb_str())
                    sb_new()
                    cnt = 0
                }
                i = i + step
            }
        }
        print_raw(sb_str())
    }
    return 0
}
