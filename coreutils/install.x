module main

// install [-m MODE] SRC... DST — copy files with mode (GNU install).
//   -m MODE   set permission mode (e.g., 755)
//   -d        create directories (like mkdir -p)
// Multiple SRC → DST must be a directory. Binary-safe copy (read_rbuf/write_rbuf).

fn copy_binary(src: String, dst: String): i32 {
    let ifd: i32 = open_read(src)
    if ifd < 0 { return 1 }
    let ofd: i32 = open_write(dst)
    if ofd < 0 {
        close_fd(ifd)
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

fn main(): i32 {
    let mut mode_str: String = ""
    let mut make_dirs: i32 = 0
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let c1: i32 = str_char_at(a, 1)
                if c1 == 109 {
                    if str_len(a) > 2 {
                        mode_str = str_slice(a, 2, str_len(a))
                    } else {
                        i = i + 1
                        if i < argc() { mode_str = argv(i) }
                    }
                }
                if c1 == 100 { make_dirs = 1 }
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
        eprint_str("usage: install [-m MODE] [-d] SRC... DST")
        return 1
    }

    if make_dirs == 1 {
        let mut k: i32 = 0
        while k < nf {
            let parts: i32 = str_find(files[k], "/")
            if parts >= 0 {
                let n2: i32 = str_len(files[k])
                let mut pi: i32 = 0
                while pi <= n2 {
                    let mut at_sep: bool = (pi == n2)
                    if pi < n2 {
                        if str_char_at(files[k], pi) == 47 { at_sep = true }
                    }
                    if at_sep {
                        let prefix: String = str_slice(files[k], 0, pi)
                        if str_len(prefix) > 0 {
                            if is_dir(prefix) == 0 {
                                if file_exists(prefix) == 0 {
                                    make_dir(prefix)
                                }
                            }
                        }
                    }
                    pi = pi + 1
                }
            } else {
                if is_dir(files[k]) == 0 {
                    if file_exists(files[k]) == 0 {
                        make_dir(files[k])
                    }
                }
            }
            k = k + 1
        }
        return 0
    }

    if nf == 1 {
        eprint_str("usage: install [-m MODE] SRC DST")
        return 1
    }

    let mut rc: i32 = 0
    if nf == 2 {
        if copy_binary(files[0], files[1]) != 0 { rc = 1 }
        if str_len(mode_str) > 0 {
            chmod(files[1], str_to_int_oct(mode_str))
        }
    } else {
        let dst_dir: String = files[nf - 1]
        if is_dir(dst_dir) == 0 {
            print_str("install: target is not a directory")
            return 1
        }
        let mut k: i32 = 0
        while k < nf - 1 {
            let bn: String = files[k]
            let mut bi: i32 = str_len(bn) - 1
            let mut base: String = bn
            while bi >= 0 {
                if str_char_at(bn, bi) == 47 {
                    base = str_slice(bn, bi + 1, str_len(bn))
                    bi = -1
                } else {
                    bi = bi - 1
                }
            }
            let dst: String = str_concat(str_concat(dst_dir, "/"), base)
            if copy_binary(bn, dst) != 0 { rc = 1 }
            if str_len(mode_str) > 0 {
                chmod(dst, str_to_int_oct(mode_str))
            }
            k = k + 1
        }
    }
    return rc
}
