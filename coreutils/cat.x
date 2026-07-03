module main

// cat [-nbsAET] [file...] — concatenate files to stdout.
//   -n   number all lines (GNU format: %6d + tab)
//   -b   number non-blank lines (overrides -n)
//   -s   squeeze consecutive blank lines into one
//   -A   show tabs as ^I and line ends as $  (= -ET)
//   -E   line end $     -T   tab as ^I
// Multiple files concatenated. No flags = plain print (backward compatible).

fn is_blank(line: String): bool {
    let n: i32 = str_len(line)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(line, i)
        if c != 32 { if c != 9 { return false } }
        i = i + 1
    }
    return true
}

// Right-justify s in a field of width w (leading spaces).
fn pad_num(s: String, w: i32): String {
    let l: i32 = str_len(s)
    if l >= w { return s }
    sb_new()
    let mut i: i32 = 0
    while i < w - l {
        sb_push_char(32)
        i = i + 1
    }
    sb_push(s)
    return sb_str()
}

// Render a line for output: -T => tab→^I.
fn render(line: String, want_t: i32): String {
    if want_t == 0 { return line }
    sb_new()
    let n: i32 = str_len(line)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(line, i)
        if c == 9 {
            sb_push("^I")
        } else {
            sb_push_char(c)
        }
        i = i + 1
    }
    return sb_str()
}

fn main(): i32 {
    let mut want_n: i32 = 0
    let mut want_b: i32 = 0
    let mut want_s: i32 = 0
    let mut want_e: i32 = 0
    let mut want_t: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    let c: i32 = str_char_at(a, j)
                    if c == 110 { want_n = 1 }
                    if c == 98 { want_b = 1 }
                    if c == 115 { want_s = 1 }
                    if c == 65 {
                        want_e = 1
                        want_t = 1
                    }
                    if c == 69 { want_e = 1 }
                    if c == 84 { want_t = 1 }
                    j = j + 1
                }
                i = i + 1
            } else {
                files.push(a)
                i = i + 1
            }
        } else {
            files.push(a)
            i = i + 1
        }
    }

    // Gather content (concatenate files, or stdin).
    let mut text: String = ""
    let nf: i32 = vec_len(files)
    if nf == 0 {
        text = read_stdin()
    } else {
        let mut p: i32 = 0
        while p < nf {
            text = str_concat(text, read_file(files[p]))
            p = p + 1
        }
    }

    let n: i32 = str_len(text)
    // Fast path: no flags → copy the whole input in ONE write. Without this,
    // plain cat still walks every line and print_raw's each (2 syscalls/line),
    // ~3x slower than GNU cat's block read/write.
    let mut plain: i32 = 1
    if want_n == 1 { plain = 0 }
    if want_b == 1 { plain = 0 }
    if want_s == 1 { plain = 0 }
    if want_e == 1 { plain = 0 }
    if want_t == 1 { plain = 0 }
    if plain == 1 {
        print_raw(text)
        return 0
    }
    let mut lineno: i32 = 0
    let mut blineno: i32 = 0
    let mut prev_blank: i32 = 0
    let mut start: i32 = 0
    let mut k: i32 = 0
    while k <= n {
        let is_end: bool = (k == n)
        let mut is_nl: bool = false
        if is_end == false {
            if str_char_at(text, k) == 10 { is_nl = true }
        }
        if is_end || is_nl {
            // Process a line; at EOF only if there's trailing content (a final
            // newline does NOT create a phantom empty line). A \n always bounds a
            // real line — even an empty one (consecutive newlines).
            let mut process: bool = is_nl
            if is_end {
                if start < n { process = true }
            }
            if process {
                let line: String = str_slice(text, start, k)
                let blank: bool = is_blank(line)
                let mut skip: i32 = 0
                if want_s == 1 {
                    if blank {
                        if prev_blank == 1 { skip = 1 }
                    }
                }
                if skip == 0 {
                    if blank { prev_blank = 1 } else { prev_blank = 0 }
                    let mut num: String = ""
                    if want_b == 1 {
                        if blank == false {
                            blineno = blineno + 1
                            num = int_to_str(blineno)
                        }
                    } else {
                        if want_n == 1 {
                            lineno = lineno + 1
                            num = int_to_str(lineno)
                        }
                    }
                    if str_len(num) > 0 {
                        print_raw(pad_num(num, 6))
                        print_raw("\t")
                    }
                    print_raw(render(line, want_t))
                    if want_e == 1 { print_raw("$") }
                    print_raw("\n")
                }
            }
            start = k + 1
        }
        k = k + 1
    }
    return 0
}
