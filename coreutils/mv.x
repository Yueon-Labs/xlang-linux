module main

// mv [-f] <src>... <dst> — move/rename files or directories.
//   Multiple sources → <dst> must be a directory; each is moved into it.
//   Single source into an existing directory → moved into it (dst/name).
// Uses rename(2) — atomic, binary-safe, works across files and directories.
// -f (force) is accepted and is the default behavior.

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

fn main(): i32 {
    let files: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                // Ignore flags (-f, -v, etc.) — force is the default.
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
        eprint_str("usage: mv [-f] <src>... <dst>")
        return 1
    }

    // Single source.
    if nf == 2 {
        let src: String = files[0]
        let dst: String = files[1]
        if is_dir(dst) == 1 {
            let target: String = str_concat(str_concat(dst, "/"), basename(src))
            return rename_file(src, target)
        }
        return rename_file(src, dst)
    }

    // Multiple sources: <dst> must be a directory.
    let dst: String = files[nf - 1]
    if is_dir(dst) == 0 {
        print_str("mv: target is not a directory")
        return 1
    }
    let mut rc: i32 = 0
    let mut k: i32 = 0
    while k < nf - 1 {
        let src: String = files[k]
        let target: String = str_concat(str_concat(dst, "/"), basename(src))
        if rename_file(src, target) != 0 {
            rc = 1
        }
        k = k + 1
    }
    return rc
}
