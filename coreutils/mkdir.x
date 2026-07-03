module main

// mkdir [-p] <dir>... — create directories.
//   -p   create parent directories as needed; no error if a dir already exists.
// Multiple dirs supported.

// Create path and all its parents (no error on existing dirs).
fn mkdir_p(path: String): i32 {
    let n: i32 = str_len(path)
    let mut i: i32 = 0
    while i <= n {
        let mut at_sep: bool = (i == n)
        if i < n {
            if str_char_at(path, i) == 47 { at_sep = true }
        }
        if at_sep {
            let prefix: String = str_slice(path, 0, i)
            if str_len(prefix) > 0 {
                if is_dir(prefix) == 0 {
                    if file_exists(prefix) == 0 {
                        make_dir(prefix)
                    }
                }
            }
        }
        i = i + 1
    }
    return 0
}

fn main(): i32 {
    let mut parents: i32 = 0
    let dirs: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    if str_char_at(a, j) == 112 { parents = 1 }
                    j = j + 1
                }
                i = i + 1
            } else {
                dirs.push(a)
                i = i + 1
            }
        } else {
            dirs.push(a)
            i = i + 1
        }
    }
    let nd: i32 = vec_len(dirs)
    if nd == 0 {
        eprint_str("usage: mkdir [-p] <dir>...")
        return 1
    }
    let mut rc: i32 = 0
    let mut k: i32 = 0
    while k < nd {
        if parents == 1 {
            mkdir_p(dirs[k])
        } else {
            if make_dir(dirs[k]) != 0 {
                rc = 1
            }
        }
        k = k + 1
    }
    return rc
}
