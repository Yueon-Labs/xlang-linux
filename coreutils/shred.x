module main

// shred [-n N] [-u] [-z] <file...> — overwrite a file to make its data
// unrecoverable, then optionally remove it. Not cryptographically secure
// (no entropy source), but demonstrates the overwrite pattern.
//   -n N : number of overwrite passes (default 3)
//   -u   : remove the file after overwriting
//   -z   : final pass writes zeros (to mask the shredding)

fn shred_file(path: String, passes: i32, do_unlink: i32, do_zero: i32): i32 {
    let data: String = read_file(path)
    let size: i32 = str_len(data)
    if size == 0 { return 0 }
    let mut pass: i32 = 0
    while pass < passes {
        sb_new()
        let mut k: i32 = 0
        while k < size {
            let byte_val: i32 = ((k * 31 + pass * 17) % 251) + 1
            sb_push_char(byte_val)
            k += 1
        }
        write_file(path, sb_str())
        pass += 1
    }
    if do_zero == 1 {
        sb_new()
        let mut k: i32 = 0
        while k < size {
            sb_push_char(0)
            k += 1
        }
        write_file(path, sb_str())
    }
    if do_unlink == 1 {
        remove_file(path)
    }
    return 0
}

fn main(): i32 {
    let mut passes: i32 = 3
    let mut do_unlink: i32 = 0
    let mut do_zero: i32 = 0
    let files: Vec<String> = vec_new()
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if str_char_at(a, 0) == '-' && str_len(a) > 1 {
            let mut j: i32 = 1
            let la: i32 = str_len(a)
            while j < la {
                let c: i32 = str_char_at(a, j)
                if c == 'u' { do_unlink = 1 }
                if c == 'z' { do_zero = 1 }
                if c == 'n' {
                    let rest: String = str_slice(a, j + 1, la)
                    if str_len(rest) > 0 { passes = str_to_int(rest) }
                    j = la
                }
                j += 1
            }
        } else {
            files.push(a)
        }
        ai += 1
    }
    if vec_len(files) == 0 {
        print_str("usage: shred [-n N] [-u] [-z] <file...>\n")
        return 1
    }
    let nf: i32 = vec_len(files)
    let mut fi: i32 = 0
    while fi < nf {
        shred_file(files[fi], passes, do_unlink, do_zero)
        fi += 1
    }
    return 0
}
