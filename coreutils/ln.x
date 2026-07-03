module main

// ln [-s] <target> <link> — create links (GNU ln).
//   -s   symbolic link (default; also supports hard links)
// Without -s: hard link (link builtin). With -s: symlink.
// Multiple targets into a directory supported.

fn basename(path: String): String {
    let n: i32 = str_len(path)
    let mut i: i32 = n - 1
    while i >= 0 {
        if str_char_at(path, i) == 47 {
            return str_slice(path, i + 1, n)
        }
        i = i - 1
    }
    return path
}

fn main(): i32 {
    let mut sym: i32 = 1
    let targets: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    if str_char_at(a, j) == 115 { sym = 1 }
                    j = j + 1
                }
                i = i + 1
            } else {
                targets.push(a)
                i = i + 1
            }
        } else {
            targets.push(a)
            i = i + 1
        }
    }
    let nt: i32 = vec_len(targets)
    if nt < 2 {
        eprint_str("usage: ln [-s] <target> <link>")
        return 1
    }

    if nt == 2 {
        if sym == 1 {
            return symlink(targets[0], targets[1])
        }
        return link(targets[0], targets[1])
    }

    let dst_dir: String = targets[nt - 1]
    if is_dir(dst_dir) == 0 {
        print_str("ln: target is not a directory")
        return 1
    }
    let mut rc: i32 = 0
    let mut k: i32 = 0
    while k < nt - 1 {
        let src: String = targets[k]
        let dst: String = str_concat(str_concat(dst_dir, "/"), basename(src))
        if sym == 1 {
            if symlink(src, dst) != 0 { rc = 1 }
        } else {
            if link(src, dst) != 0 { rc = 1 }
        }
        k = k + 1
    }
    return rc
}
