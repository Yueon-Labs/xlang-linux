module main

// df [-h] — filesystem disk space usage (GNU df subset).
//   -h   human-readable sizes (K, M, G)
// Reads /proc/mounts, calls statvfs_field for each mountpoint.

fn human_size_kbytes(kb: i32): String {
    if kb >= 1048576 {
        let whole: i32 = kb / 1048576
        let frac: i32 = (kb % 1048576) * 10 / 1048576
        if frac == 0 { return str_concat(int_to_str(whole), ".0G") }
        return str_concat(str_concat(str_concat(int_to_str(whole), "."), int_to_str(frac)), "G")
    }
    if kb >= 1024 {
        let whole: i32 = kb / 1024
        let frac: i32 = (kb % 1024) * 10 / 1024
        if frac == 0 { return str_concat(int_to_str(whole), ".0M") }
        return str_concat(str_concat(str_concat(int_to_str(whole), "."), int_to_str(frac)), "M")
    }
    return str_concat(int_to_str(kb), "K")
}

fn is_real_fs(fstype: String): i32 {
    if fstype == "ext4" { return 1 }
    if fstype == "ext3" { return 1 }
    if fstype == "ext2" { return 1 }
    if fstype == "xfs" { return 1 }
    if fstype == "btrfs" { return 1 }
    if fstype == "tmpfs" { return 1 }
    if fstype == "vfat" { return 1 }
    if fstype == "ntfs" { return 1 }
    if fstype == "overlay" { return 1 }
    if fstype == "squashfs" { return 1 }
    return 0
}

fn main(): i32 {
    let mut want_h: i32 = 0
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_char_at(a, 0) == 45 {
            let mut k: i32 = 1
            while k < str_len(a) {
                if str_char_at(a, k) == 104 { want_h = 1 }
                k = k + 1
            }
        }
        i = i + 1
    }

    let mounts: String = read_file("/proc/mounts")
    let lines: Vec<String> = str_split(str_trim(mounts), "\n")
    let nlines: i32 = vec_len(lines)

    sb_new()
    if want_h == 1 {
        sb_push("Filesystem      Size  Used Avail Use% Mounted on\n")
    } else {
        sb_push("Filesystem     1K-blocks    Used Available Use% Mounted on\n")
    }

    let mut seen: i32 = 0
    let mut li: i32 = 0
    while li < nlines {
        let line: String = lines[li]
        let sp1: i32 = str_find(line, " ")
        if sp1 >= 0 {
            let rest: String = str_slice(line, sp1 + 1, str_len(line))
            let sp2: i32 = str_find(rest, " ")
            if sp2 >= 0 {
                let mp: String = str_slice(rest, 0, sp2)
                let rest2: String = str_slice(rest, sp2 + 1, str_len(rest))
                let sp3: i32 = str_find(rest2, " ")
                if sp3 >= 0 {
                    let fstype: String = str_slice(rest2, 0, sp3)
                    if is_real_fs(fstype) == 1 {
                        let bsize: i32 = statvfs_field(mp, 0)
                        let blocks: i32 = statvfs_field(mp, 2)
                        let bfree: i32 = statvfs_field(mp, 3)
                        if bsize > 0 && blocks > 0 {
                            let frsize: i32 = bsize
                            let frsize_v: i32 = statvfs_field(mp, 1)
                            if frsize_v > 0 { frsize = frsize_v }
                            let kb_total: i32 = blocks * frsize / 1024
                            let kb_free: i32 = bfree * frsize / 1024
                            let kb_used: i32 = kb_total - kb_free
                            let mut pct: i32 = 0
                            if kb_total > 0 {
                                pct = kb_used * 100 / kb_total
                            }
                            if pct > 100 { pct = 100 }
                            if want_h == 1 {
                                sb_push(human_size_kbytes(kb_total))
                                sb_push("  ")
                                sb_push(human_size_kbytes(kb_used))
                                sb_push(" ")
                                sb_push(human_size_kbytes(kb_free))
                                sb_push(" ")
                                sb_push(int_to_str(pct))
                                sb_push("%  ")
                                sb_push(mp)
                                sb_push("\n")
                            } else {
                                sb_push(int_to_str(kb_total))
                                sb_push("  ")
                                sb_push(int_to_str(kb_used))
                                sb_push(" ")
                                sb_push(int_to_str(kb_free))
                                sb_push(" ")
                                sb_push(int_to_str(pct))
                                sb_push("%  ")
                                sb_push(mp)
                                sb_push("\n")
                            }
                            seen = seen + 1
                        }
                    }
                }
            }
        }
        li = li + 1
    }

    if seen == 0 {
        sb_push("(no filesystems found)\n")
    }
    print_raw(sb_str())
    return 0
}
