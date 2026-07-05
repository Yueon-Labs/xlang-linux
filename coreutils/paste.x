module main

// paste [-d DELIMS] [-s] <file>... — merge lines from files (GNU paste).
//   -d DELIMS   column delimiters (cycled, default \t)
//   -s          serial: each file → one line
// Reads stdin when no file is given; "-" means stdin.
//
// Each file's raw text is kept once (no per-line str_slice malloc). A pair of
// flat (start,end) byte-offset arrays records every line; cells are emitted
// directly via sb_push_slice into one growing output buffer, flushed once.
// Line segmentation matches GNU: split on '\n', and drop a single trailing
// empty segment only when the file ends with a newline (so "a\n" is one line,
// "a\n\n" is two ["a",""], and an empty file is zero lines).

fn main(): i32 {
    let mut delims: String = "\t"
    let mut serial: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let c1: i32 = str_char_at(a, 1)
                if c1 == 100 {
                    if str_len(a) > 2 {
                        delims = str_slice(a, 2, str_len(a))
                    } else {
                        i = i + 1
                        if i < argc() { delims = argv(i) }
                    }
                }
                if c1 == 115 { serial = 1 }
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
    // GNU paste reads stdin when no file is given (and treats "-" as stdin).
    if vec_len(files) == 0 {
        files.push("-")
    }
    let nf: i32 = vec_len(files)

    // Per-file raw text + flat line (start,end) offset arrays. No str_slice
    // per line — just two i32 arrays and the single raw buffer per file.
    let raws: Vec<String> = vec_new()
    let lstart: Vec<i32> = vec_new()
    let lend: Vec<i32> = vec_new()
    let file_start: Vec<i32> = vec_new()
    let file_count: Vec<i32> = vec_new()
    let mut fi: i32 = 0
    while fi < nf {
        let raw: String = if files[fi] == "-" { read_stdin() } else { read_file(files[fi]) }
        raws.push(raw)
        file_start.push(vec_len(lstart))
        let rn: i32 = str_len(raw)
        let mut cnt: i32 = 0
        if rn > 0 {
            let mut s: i32 = 0
            let mut k: i32 = 0
            while k < rn {
                if str_char_at(raw, k) == 10 {
                    lstart.push(s)
                    lend.push(k)
                    cnt = cnt + 1
                    s = k + 1
                }
                k = k + 1
            }
            // Trailing segment after the last newline — emit only if there is
            // content (a final newline yields no phantom empty line; matches GNU).
            if s < rn {
                lstart.push(s)
                lend.push(rn)
                cnt = cnt + 1
            }
        }
        file_count.push(cnt)
        fi = fi + 1
    }

    let dn: i32 = str_len(delims)
    sb_new()

    if serial == 1 {
        let mut f: i32 = 0
        while f < nf {
            let ln: i32 = file_count[f]
            let base: i32 = file_start[f]
            let raw: String = raws[f]
            let mut r: i32 = 0
            while r < ln {
                if r > 0 {
                    if dn == 1 {
                        sb_push(delims)
                    } else {
                        sb_push(chr(str_char_at(delims, (r - 1) % dn)))
                    }
                }
                sb_push_slice(raw, lstart[base + r], lend[base + r])
                r = r + 1
            }
            sb_push("\n")
            f = f + 1
        }
    } else {
        let mut max_lines: i32 = 0
        let mut f: i32 = 0
        while f < nf {
            if file_count[f] > max_lines { max_lines = file_count[f] }
            f = f + 1
        }
        let mut row: i32 = 0
        while row < max_lines {
            let mut col: i32 = 0
            while col < nf {
                if col > 0 {
                    if dn == 1 {
                        sb_push(delims)
                    } else {
                        sb_push(chr(str_char_at(delims, (col - 1) % dn)))
                    }
                }
                if row < file_count[col] {
                    let base: i32 = file_start[col]
                    sb_push_slice(raws[col], lstart[base + row], lend[base + row])
                }
                col = col + 1
            }
            sb_push("\n")
            row = row + 1
        }
    }
    print_raw(sb_str())
    return 0
}
