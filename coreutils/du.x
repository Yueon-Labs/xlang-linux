module main

// du [-s] [-h] [-k] [-b] [dir]... — disk usage (GNU du).
//   -s   summary only (one total per arg; no subdir breakdown)
//   -h   human-readable (K, M, G)
//   -k    kilobytes (1024-byte blocks) [default unit]
//   -b    apparent size in bytes (st_size, not disk blocks)
// Default: disk usage in 1K-blocks; without -s, lists each subdir too.

// Field 6 = st_blocks (512-byte units, for disk usage); 4 = st_size (apparent).

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
    return int_to_str(bytes)
}

fn print_line(dir: String, total: i32, use_blocks: i32, human: i32): i32 {
    if use_blocks == 1 {
        let kbytes: i32 = total / 2
        if human == 1 {
            print_raw(human_size(kbytes * 1024))
        } else {
            print_raw(int_to_str(kbytes))
        }
    } else {
        print_raw(int_to_str(total))
    }
    print_raw("\t")
    print_raw(dir)
    print_raw("\n")
    return 0
}

// Walk dir; return total. For non-summary (summary=0), print each subdir
// post-order (children before parent, like GNU).
fn du_walk(dir: String, use_blocks: i32, summary: i32, human: i32): i32 {
    let fld: i32 = if use_blocks == 1 { 6 } else { 4 }
    let mut total: i32 = stat_field(dir, fld)
    if total < 0 { total = 0 }
    let n: i32 = dir_count(dir)
    let mut i: i32 = 0
    while i < n {
        let entry: String = dir_entry(dir, i)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) != 46 {
                let path: String = str_concat(str_concat(dir, "/"), entry)
                if is_dir(path) == 1 {
                    let sub: i32 = du_walk(path, use_blocks, summary, human)
                    total = total + sub
                    if summary == 0 {
                        print_line(path, sub, use_blocks, human)
                    }
                } else {
                    let v: i32 = stat_field(path, fld)
                    if v > 0 { total = total + v }
                }
            }
        }
        i = i + 1
    }
    return total
}

fn main(): i32 {
    let mut summary: i32 = 0
    let mut human: i32 = 0
    let mut bytes_mode: i32 = 0
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
                    if c == 98 { bytes_mode = 1 }
                    if c == 104 { human = 1 }
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
    let use_blocks: i32 = if bytes_mode == 1 { 0 } else { 1 }
    let nd: i32 = vec_len(dirs)
    if nd == 0 {
        dirs.push(".")
    }
    let mut k: i32 = 0
    while k < vec_len(dirs) {
        let d: String = dirs[k]
        let total: i32 = du_walk(d, use_blocks, summary, human)
        print_line(d, total, use_blocks, human)
        k = k + 1
    }
    return 0
}
