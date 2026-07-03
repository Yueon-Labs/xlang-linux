module main

// stat [-c FORMAT] <path> — file statistics (GNU-compatible subset).
// Default output: "File: PATH  Size: N  Type: file|dir"
// -c FORMAT: custom format with GNU specifiers:
//   %n  name (path)    %s  size    %F  file type string
//   %f  raw mode hex   %h  hard links  %u  uid  %g  gid
//   %U  user name      %G  group name  %y  mtime  %a  permissions octal

fn main(): i32 {
    let mut fmt: String = ""
    let mut path: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-c") {
            i = i + 1
            if i < argc() { fmt = argv(i) }
        } else {
            if str_eq(a, "--format") {
                i = i + 1
                if i < argc() { fmt = argv(i) }
            } else {
                if str_len(a) >= 2 {
                    if str_char_at(a, 0) == 45 {
                        if str_char_at(a, 1) == 99 {
                            fmt = str_slice(a, 2, str_len(a))
                        }
                    } else {
                        path = a
                    }
                } else {
                    path = a
                }
            }
        }
        i = i + 1
    }
    if str_len(path) == 0 {
        eprint_str("usage: stat [-c FORMAT] <path>")
        return 1
    }
    if file_exists(path) == 0 {
        eprint_raw("stat: cannot stat '")
        eprint_raw(path)
        eprint_raw("': No such file or directory\n")
        return 1
    }

    let mode: i32 = stat_field(path, 0)
    let nlink: i32 = stat_field(path, 1)
    let uid: i32 = stat_field(path, 2)
    let gid: i32 = stat_field(path, 3)
    let size: i32 = stat_field(path, 4)
    let mtime: i32 = stat_field(path, 5)
    let is_dir: i32 = is_dir(path)
    let mut type_str: String = "regular file"
    if is_dir == 1 { type_str = "directory" }
    let perm_octal: i32 = mode & 4095

    if str_len(fmt) > 0 {
        let fn_: i32 = str_len(fmt)
        let mut k: i32 = 0
        while k < fn_ {
            let c: i32 = str_char_at(fmt, k)
            if c == 37 {
                if k + 1 < fn_ {
                    let spec: i32 = str_char_at(fmt, k + 1)
                    if spec == 110 { print_raw(path) }
                    if spec == 115 { print_raw(int_to_str(size)) }
                    if spec == 70 { print_raw(type_str) }
                    if spec == 104 { print_raw(int_to_str(nlink)) }
                    if spec == 117 { print_raw(int_to_str(uid)) }
                    if spec == 85 {
                        let un: String = uid_to_name(uid)
                        if str_len(un) > 0 { print_raw(un) } else { print_raw(int_to_str(uid)) }
                    }
                    if spec == 103 { print_raw(int_to_str(gid)) }
                    if spec == 71 {
                        let gn: String = gid_to_name(gid)
                        if str_len(gn) > 0 { print_raw(gn) } else { print_raw(int_to_str(gid)) }
                    }
                    if spec == 121 { print_raw(fmt_ctime(mtime)) }
                    if spec == 97 { print_raw(int_to_str(perm_octal)) }
                    if spec == 102 { print_raw(int_to_str(mode)) }
                    if spec == 37 { print_raw("%") }
                    k = k + 1
                }
            } else {
                print_raw(chr(c))
            }
            k = k + 1
        }
        print_raw("\n")
    } else {
        print_raw("  File: ")
        print_raw(path)
        print_raw("\n  Size: ")
        print_raw(int_to_str(size))
        print_raw("\t\tType: ")
        print_raw(type_str)
        print_raw("\n  Links: ")
        print_raw(int_to_str(nlink))
        print_raw("\tUid: ")
        print_raw(int_to_str(uid))
        print_raw("\tGid: ")
        print_raw(int_to_str(gid))
        print_raw("\nModify: ")
        print_raw(fmt_ctime(mtime))
        print_raw("\n")
    }
    return 0
}
