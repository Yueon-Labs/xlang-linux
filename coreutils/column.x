module main

// column [-t] [-s SEP] — columnate input. With -t, produce a table: pad each
// column to (max field width + 2), left-justified. Fields split on whitespace
// by default, or on any character in SEP when -s is given (GNU column -t -s).

fn split_fields(line: String): Vec<String> {
    let fields: Vec<String> = vec_new()
    let n: i32 = str_len(line)
    let mut i: i32 = 0
    while i < n {
        while i < n {
            let c: i32 = str_char_at(line, i)
            if c == ' ' || c == '\t' {
                i += 1
            } else {
                break
            }
        }
        if i >= n { break }
        let start: i32 = i
        while i < n {
            let c: i32 = str_char_at(line, i)
            if c == ' ' || c == '\t' { break }
            i += 1
        }
        fields.push(str_slice(line, start, i))
    }
    return fields
}

// Split on any character in SEP (each occurrence delimits a field, no run-skip
// — so "a,,c" with sep "," yields ["a", "", "c"], matching GNU column -s).
fn split_fields_sep(line: String, sep: String): Vec<String> {
    let fields: Vec<String> = vec_new()
    let n: i32 = str_len(line)
    let ns: i32 = str_len(sep)
    let mut start: i32 = 0
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(line, i)
        let mut in_sep: bool = false
        let mut j: i32 = 0
        while j < ns {
            if str_char_at(sep, j) == c { in_sep = true }
            j += 1
        }
        if in_sep {
            fields.push(str_slice(line, start, i))
            start = i + 1
        }
        i += 1
    }
    fields.push(str_slice(line, start, n))
    return fields
}

// Pick the splitter: -s SEP if given, else whitespace.
fn split_for(line: String, have_sep: i32, sep: String): Vec<String> {
    if have_sep == 1 { return split_fields_sep(line, sep) }
    return split_fields(line)
}

fn main(): i32 {
    let mut want_t: i32 = 0
    let mut sep: String = ""
    let mut have_sep: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if a == "-t" {
            want_t = 1
        } else if a == "-s" {
            if ai + 1 < argc() {
                sep = argv(ai + 1)
                have_sep = 1
                ai += 1
            }
        } else if str_starts_with(a, "-s") {
            sep = str_slice(a, 2, str_len(a))
            have_sep = 1
        }
        ai += 1
    }
    if want_t == 0 {
        print_raw(read_stdin())
        return 0
    }

    // Read all lines (re-split each for width computation and output, to avoid
    // nested Vec<Vec<String>> which the lexer can't parse: `>>` is right-shift).
    let input: String = read_stdin()
    let n: i32 = str_len(input)
    let lines: Vec<String> = vec_new()
    let mut start: i32 = 0
    let mut k: i32 = 0
    while k < n {
        if str_char_at(input, k) == '\n' {
            lines.push(str_slice(input, start, k))
            start = k + 1
        }
        k += 1
    }
    if start < n {
        lines.push(str_slice(input, start, n))
    }

    let nrows: i32 = vec_len(lines)
    let mut ncols: i32 = 0
    // First pass: compute column widths.
    let colwidths: Vec<i32> = vec_new()
    let mut r: i32 = 0
    while r < nrows {
        let fields: Vec<String> = split_for(lines[r], have_sep, sep)
        let nf: i32 = vec_len(fields)
        if nf > ncols { ncols = nf }
        let mut c: i32 = 0
        while c < nf {
            let w: i32 = str_len(fields[c])
            if c >= vec_len(colwidths) {
                colwidths.push(w)
            } else {
                if w > colwidths[c] { colwidths[c] = w }
            }
            c += 1
        }
        r += 1
    }
    if ncols == 0 { return 0 }

    // Second pass: output padded.
    r = 0
    while r < nrows {
        let fields: Vec<String> = split_for(lines[r], have_sep, sep)
        let nf: i32 = vec_len(fields)
        let mut c: i32 = 0
        while c < ncols {
            if c < nf {
                let field: String = fields[c]
                print_raw(field)
                if c < ncols - 1 {
                    let target: i32 = colwidths[c] + 2
                    let mut p: i32 = str_len(field)
                    while p < target {
                        print_raw(" ")
                        p += 1
                    }
                }
            } else {
                if c < ncols - 1 {
                    let target: i32 = colwidths[c] + 2
                    let mut p: i32 = 0
                    while p < target {
                        print_raw(" ")
                        p += 1
                    }
                }
            }
            c += 1
        }
        print_raw("\n")
        r += 1
    }
    return 0
}
