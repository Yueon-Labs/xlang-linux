module main

// rm [-rf] <file>... — remove files or directories.
//   -r   recursive (remove directories and their contents)
//   -f   force (ignore nonexistent files, never prompt)
// Multiple files supported.

fn rm_recurse(path: String): i32 {
    if is_dir(path) == 1 {
        let n: i32 = dir_count(path)
        let mut i: i32 = 0
        while i < n {
            let entry: String = dir_entry(path, i)
            if str_len(entry) > 0 {
                if str_eq(entry, ".") == 0 {
                    if str_eq(entry, "..") == 0 {
                        rm_recurse(str_concat(str_concat(path, "/"), entry))
                    }
                }
            }
            i = i + 1
        }
        rmdir(path)
    } else {
        remove_file(path)
    }
    return 0
}

fn main(): i32 {
    let mut recursive: i32 = 0
    let mut force: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    let c: i32 = str_char_at(a, j)
                    if c == 114 { recursive = 1 }
                    if c == 102 { force = 1 }
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
    let nf: i32 = vec_len(files)
    if nf == 0 {
        eprint_str("usage: rm [-rf] <file>...")
        return 1
    }
    let mut rc: i32 = 0
    let mut k: i32 = 0
    while k < nf {
        let f: String = files[k]
        if is_dir(f) == 1 {
            if recursive == 1 {
                rm_recurse(f)
            } else {
                if force == 0 {
                    print_str("rm: refusing to remove directory without -r")
                    rc = 1
                }
            }
        } else {
            if file_exists(f) == 0 {
                if force == 0 {
                    rc = 1
                }
            } else {
                if remove_file(f) != 0 {
                    if force == 0 {
                        rc = 1
                    }
                }
            }
        }
        k = k + 1
    }
    return rc
}
