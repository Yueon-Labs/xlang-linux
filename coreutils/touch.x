module main

// touch [-c] <file>... — update file timestamps (GNU touch).
//   -c   do not create if the file doesn't exist (no error)
// Creates empty files if missing, updates mtime if existing (without truncating).
// Multiple files supported. Uses open_append + close (creates without truncating).

fn main(): i32 {
    let mut no_create: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    if str_char_at(a, j) == 99 { no_create = 1 }
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
        eprint_str("usage: touch [-c] <file>...")
        return 1
    }
    let mut rc: i32 = 0
    let mut k: i32 = 0
    while k < nf {
        let f: String = files[k]
        if no_create == 1 {
            if file_exists(f) == 0 {
                k = k + 1
                continue
            }
        }
        let fd: i32 = open_append(f)
        if fd < 0 {
            rc = 1
        } else {
            close_fd(fd)
        }
        k = k + 1
    }
    return rc
}
