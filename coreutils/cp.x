module main

// cp [-r] <src>... <dst> — copy files/directories (mini GNU cp).
//   -r   recursive (copy directories)
// Binary-safe (read_rbuf/write_rbuf — NUL bytes preserved, unlike the old
// read_file/write_file cp). Multiple sources copy into <dst> (must be a dir).

// Path basename (after the last '/').
fn basename(p: String): String {
    let n: i32 = str_len(p)
    let mut i: i32 = n - 1
    while i >= 0 {
        if str_char_at(p, i) == 47 {
            return str_slice(p, i + 1, n)
        }
        i = i - 1
    }
    return p
}

// Binary-safe single-file copy.
fn copy_file(src: String, dst: String): i32 {
    let ifd: i32 = open_read(src)
    if ifd < 0 {
        eprint_str("cp: cannot open source")
        return 1
    }
    let ofd: i32 = open_write(dst)
    if ofd < 0 {
        close_fd(ifd)
        eprint_str("cp: cannot open destination")
        return 1
    }
    while true {
        let n: i32 = read_rbuf(ifd)
        if n == 0 { break }
        write_rbuf(ofd, 0, n)
    }
    close_fd(ifd)
    close_fd(ofd)
    return 0
}

// Recursively copy directory src into dst (dst is created).
fn copy_tree(src: String, dst: String): i32 {
    make_dir(dst)
    let n: i32 = dir_count(src)
    let mut i: i32 = 0
    while i < n {
        let entry: String = dir_entry(src, i)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) != 46 {
                let s: String = str_concat(str_concat(src, "/"), entry)
                let d: String = str_concat(str_concat(dst, "/"), entry)
                if is_dir(s) {
                    copy_tree(s, d)
                } else {
                    copy_file(s, d)
                }
            }
        }
        i = i + 1
    }
    return 0
}

fn main(): i32 {
    let mut recursive: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    if str_char_at(a, j) == 114 { recursive = 1 }
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
    if nf < 2 {
        eprint_str("usage: cp [-r] <src>... <dst>")
        return 1
    }

    // Single source.
    if nf == 2 {
        let src: String = files[0]
        let dst: String = files[1]
        if is_dir(src) {
            if recursive == 1 {
                return copy_tree(src, dst)
            }
            print_str("cp: -r not specified; omitting directory")
            return 1
        }
        return copy_file(src, dst)
    }

    // Multiple sources: <dst> must be a directory; copy each into it.
    let dst: String = files[nf - 1]
    if is_dir(dst) == 0 {
        print_str("cp: target is not a directory")
        return 1
    }
    let mut k: i32 = 0
    while k < nf - 1 {
        let src: String = files[k]
        let target: String = str_concat(str_concat(dst, "/"), basename(src))
        if is_dir(src) {
            if recursive == 1 {
                copy_tree(src, target)
            } else {
                print_str("cp: -r not specified; omitting directory")
            }
        } else {
            copy_file(src, target)
        }
        k = k + 1
    }
    return 0
}
