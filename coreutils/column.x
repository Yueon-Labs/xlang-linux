module main

// column [-t] — columnate input. With -t, produce a table: pad each column
// to (max field width + 2), left-justified. Fields split on whitespace.

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

fn main(): i32 {
    let mut want_t: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        if argv(ai) == "-t" { want_t = 1 }
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
        let fields: Vec<String> = split_fields(lines[r])
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
        let fields: Vec<String> = split_fields(lines[r])
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
