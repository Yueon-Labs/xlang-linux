module main

// ls [-l] [-a] [-R] [path...]
//   -l   long format: MODE NLINK USER GROUP SIZE DATE NAME
//   -a   all entries (including dotfiles; "." and "..")
//   -R   recursively list subdirectories
// Sorted. Defaults to ".". -l uses stat_field (mode/nlink/uid/gid/size/mtime)
// + fmt_ctime + uid_to_name/gid_to_name for real user/group names.

// Build a 10-char permission string "drwxr-xr-x" from mode bits.
// Octal-as-decimal: S_IFDIR=16384, S_IFLNK=40960; perms owner r/w/x=256/128/64,
// group 32/16/8, other 4/2/1.
fn perm_string(mode: i32): String {
    sb_new()
    if (mode & 16384) != 0 { sb_push("d") } else {
        if (mode & 40960) != 0 { sb_push("l") } else { sb_push("-") }
    }
    if (mode & 256) != 0 { sb_push("r") } else { sb_push("-") }
    if (mode & 128) != 0 { sb_push("w") } else { sb_push("-") }
    if (mode & 64) != 0 { sb_push("x") } else { sb_push("-") }
    if (mode & 32) != 0 { sb_push("r") } else { sb_push("-") }
    if (mode & 16) != 0 { sb_push("w") } else { sb_push("-") }
    if (mode & 8) != 0 { sb_push("x") } else { sb_push("-") }
    if (mode & 4) != 0 { sb_push("r") } else { sb_push("-") }
    if (mode & 2) != 0 { sb_push("w") } else { sb_push("-") }
    if (mode & 1) != 0 { sb_push("x") } else { sb_push("-") }
    return sb_str()
}

// Selection sort a Vec<String> of length n in place.
fn sort_vec(v: Vec<String>, n: i32): i32 {
    let mut i: i32 = 0
    while i < n {
        let mut mn: i32 = i
        let mut j: i32 = i + 1
        while j < n {
            if str_cmp(v[j], v[mn]) < 0 { mn = j }
            j = j + 1
        }
        if mn != i {
            let tmp: String = v[i]
            v[i] = v[mn]
            v[mn] = tmp
        }
        i = i + 1
    }
    return 0
}

// Print one entry, long or short.
fn print_entry(path: String, name: String, want_l: i32): i32 {
    if want_l == 0 {
        print_raw(name)
        print_raw("\n")
        return 0
    }
    let mode: i32 = stat_field(path, 0)
    let nlink: i32 = stat_field(path, 1)
    let uid: i32 = stat_field(path, 2)
    let gid: i32 = stat_field(path, 3)
    let size: i32 = stat_field(path, 4)
    let mt: i32 = stat_field(path, 5)
    print_raw(perm_string(mode))
    print_raw(" ")
    print_raw(int_to_str(nlink))
    print_raw(" ")
    print_raw(int_to_str(uid))
    print_raw(" ")
    let uname: String = uid_to_name(uid)
    if str_len(uname) > 0 {
        print_raw(uname)
    } else {
        print_raw(int_to_str(gid))
    }
    print_raw(" ")
    let gname: String = gid_to_name(gid)
    if str_len(gname) > 0 {
        print_raw(gname)
    } else {
        print_raw(int_to_str(gid))
    }
    print_raw(" ")
    print_raw(int_to_str(size))
    print_raw(" ")
    print_raw(fmt_ctime(mt))
    print_raw(" ")
    print_raw(name)
    print_raw("\n")
    return 0
}

// List one directory: collect entries (sorted, dotfiles per -a), print them,
// and (if -R) recurse into subdirectories.
fn list_dir(path: String, want_l: i32, want_a: i32, want_r: i32): i32 {
    let names: Vec<String> = vec_new()
    let dirs: Vec<String> = vec_new()
    let n: i32 = dir_count(path)
    let mut i: i32 = 0
    while i < n {
        let e: String = dir_entry(path, i)
        if str_len(e) > 0 {
            let keep: i32 = 1
            let mut k: i32 = keep
            if want_a == 0 {
                if str_char_at(e, 0) == 46 { k = 0 }
            }
            if k == 1 {
                names.push(e)
            }
        }
        i = i + 1
    }
    let nn: i32 = vec_len(names)
    sort_vec(names, nn)

    // Print entries.
    let mut p: i32 = 0
    while p < nn {
        let nm: String = names[p]
        let full: String = str_concat(str_concat(path, "/"), nm)
        print_entry(full, nm, want_l)
        if is_dir(full) {
            if str_eq(nm, ".") == 0 {
                if str_eq(nm, "..") == 0 {
                    dirs.push(full)
                }
            }
        }
        p = p + 1
    }

    // Recurse.
    if want_r == 1 {
        let dn: i32 = vec_len(dirs)
        let mut d: i32 = 0
        while d < dn {
            let sub: String = dirs[d]
            print_raw("\n")
            print_raw(sub)
            print_raw(":\n")
            list_dir(sub, want_l, want_a, want_r)
            d = d + 1
        }
    }
    return 0
}

fn main(): i32 {
    let mut want_l: i32 = 0
    let mut want_a: i32 = 0
    let mut want_r: i32 = 0
    let paths: Vec<String> = vec_new()

    let mut i: i32 = 1
    while i < argc() {
        let arg: String = argv(i)
        if str_len(arg) >= 2 {
            if str_char_at(arg, 0) == 45 {
                let mut ci: i32 = 1
                while ci < str_len(arg) {
                    let f: i32 = str_char_at(arg, ci)
                    if f == 108 { want_l = 1 }
                    if f == 97 { want_a = 1 }
                    if f == 82 { want_r = 1 }
                    ci = ci + 1
                }
                i = i + 1
            } else {
                paths.push(arg)
                i = i + 1
            }
        } else {
            paths.push(arg)
            i = i + 1
        }
    }
    if vec_len(paths) == 0 {
        paths.push(".")
    }

    let np: i32 = vec_len(paths)
    let use_header: i32 = 1
    let mut header: i32 = 0
    if np > 1 { header = 1 }
    if want_r == 1 { header = 1 }

    let mut k: i32 = 0
    while k < np {
        let p: String = paths[k]
        if header == 1 {
            if k > 0 { print_raw("\n") }
            print_raw(p)
            print_raw(":\n")
        }
        if is_dir(p) {
            list_dir(p, want_l, want_a, want_r)
        } else {
            print_entry(p, p, want_l)
        }
        k = k + 1
    }
    return 0
}
