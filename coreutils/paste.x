module main

// paste [-d DELIMS] [-s] <file>... — merge lines from files (GNU paste).
//   -d DELIMS   column delimiters (cycled, default \t)
//   -s          serial: each file → one line
// Multiple files supported. Vec<Vec<String>> not supported, so uses a flat
// approach: all lines concatenated, with per-file start/count arrays.


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
    let nf: i32 = vec_len(files)
    if nf == 0 {
        eprint_str("usage: paste [-d DELIMS] [-s] <file>...")
        return 1
    }

    // Flat storage: all_lines has all lines from all files concatenated.
    // file_start[f] = index in all_lines where file f's lines begin.
    // file_count[f] = number of lines in file f.
    let all_lines: Vec<String> = vec_new()
    let file_start: Vec<i32> = vec_new()
    let file_count: Vec<i32> = vec_new()
    let mut fi: i32 = 0
    while fi < nf {
        let lines: Vec<String> = str_split(str_trim(read_file(files[fi])), "
")
        let ln: i32 = vec_len(lines)
        file_start.push(vec_len(all_lines))
        file_count.push(ln)
        let mut k: i32 = 0
        while k < ln {
            all_lines.push(lines[k])
            k = k + 1
        }
        fi = fi + 1
    }

    let dn: i32 = str_len(delims)

    if serial == 1 {
        let mut f: i32 = 0
        while f < nf {
            let ln: i32 = file_count[f]
            let base: i32 = file_start[f]
            let mut k: i32 = 0
            while k < ln {
                if k > 0 {
                    let dc: i32 = str_char_at(delims, (k - 1) % dn)
                    print_raw(chr(dc))
                }
                print_raw(all_lines[base + k])
                k = k + 1
            }
            print_raw("\n")
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
                    let dc: i32 = str_char_at(delims, (col - 1) % dn)
                    print_raw(chr(dc))
                }
                if row < file_count[col] {
                    print_raw(all_lines[file_start[col] + row])
                }
                col = col + 1
            }
            print_raw("\n")
            row = row + 1
        }
    }
    return 0
}
