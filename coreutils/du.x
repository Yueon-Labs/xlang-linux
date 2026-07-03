module main

// du [-s] [-h] [-k] [-b] [dir]... — disk usage (GNU du subset).
//   -s   summary only (one total per dir, no per-subdir breakdown)
//   -h   human-readable (K, M, G)
//   -k    kilobytes (1024-byte blocks)
//   -b    bytes (default)
// Recursive byte count via file_size (stat). Multiple dirs supported.

fn du_dir(dir: String): i32 {
    let n: i32 = dir_count(dir)
    let mut i: i32 = 0
    let mut total: i32 = 0
    while i < n {
        let entry: String = dir_entry(dir, i)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) != 46 {
                let path: String = str_concat(str_concat(dir, "/"), entry)
                total = total + file_size(path)
                if is_dir(path) == 1 {
                    total = total + du_dir(path)
                }
            }
        }
        i = i + 1
    }
    return total
}

fn human_size(bytes: i32): String {
    if bytes >= 1073741824 {
        let whole: i32 = bytes / 1073741824
        let frac: i32 = (bytes % 1073741824) * 10 / 1073741824
        if frac == 0 {
            return str_concat(int_to_str(whole), "G")
        }
        return str_concat(str_concat(str_concat(int_to_str(whole), "."), int_to_str(frac)), "G")
    }
    if bytes >= 1048576 {
        let whole: i32 = bytes / 1048576
        let frac: i32 = (bytes % 1048576) * 10 / 1048576
        if frac == 0 {
            return str_concat(int_to_str(whole), "M")
        }
        return str_concat(str_concat(str_concat(int_to_str(whole), "."), int_to_str(frac)), "M")
    }
    if bytes >= 1024 {
        let whole: i32 = bytes / 1024
        let frac: i32 = (bytes % 1024) * 10 / 1024
        if frac == 0 {
            return str_concat(int_to_str(whole), "K")
        }
        return str_concat(str_concat(str_concat(int_to_str(whole), "."), int_to_str(frac)), "K")
    }
    return str_concat(int_to_str(bytes), "")
}

fn main(): i32 {
    let mut summary: i32 = 0
    let mut human: i32 = 0
    let mut kilo: i32 = 0
    let dirs: Vec<String> = vec_new()
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let mut j: i32 = 1
                while j < str_len(a) {
                    let c: i32 = str_char_at(a, j)
                    if c == 115 { summary = 1 }
                    if c == 98 { summary = 0 }
                    if c == 104 { human = 1 }
                    if c == 107 { kilo = 1 }
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
        dirs.push(".")
    }
    let mut k: i32 = 0
    while k < vec_len(dirs) {
        let d: String = dirs[k]
        let total: i32 = du_dir(d)
        let mut display: i32 = total
        if kilo == 1 {
            display = (total + 1023) / 1024
        }
        if human == 1 {
            print_raw(human_size(total))
        } else {
            print_raw(int_to_str(display))
        }
        print_raw("\t")
        print_raw(d)
        print_raw("\n")
        k = k + 1
    }
    return 0
}
