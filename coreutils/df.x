module main

// df — filesystem disk space usage. Uses statvfs (via a runtime helper).
// Shows size, used, available, use%, mountpoint for each filesystem listed
// in /proc/mounts (simplified: shows the root and /tmp if present).

fn format_size(bytes: i64): String {
    if bytes >= 1073741824 {
        return float_to_str(int_to_f64(bytes) / 1073741824.0) + "G"
    }
    if bytes >= 1048576 {
        return float_to_str(int_to_f64(bytes) / 1048576.0) + "M"
    }
    if bytes >= 1024 {
        return float_to_str(int_to_f64(bytes) / 1024.0) + "K"
    }
    return int_to_str(bytes) + "B"
}

fn main(): i32 {
    print_str("Filesystem        Size   Used  Avail  Use%  Mounted on\n")
    let mounts: String = read_file("/proc/mounts")
    let n: i32 = str_len(mounts)
    let mut start: i32 = 0
    let mut i: i32 = 0
    let mut seen: i32 = 0
    while i < n {
        if mounts[i] == '\n' {
            let line: String = str_slice(mounts, start, i)
            start = i + 1
            // Parse: device mountpoint fstype ...
            let sp1: i32 = str_find(line, " ")
            if sp1 >= 0 {
                let rest: String = str_slice(line, sp1 + 1, str_len(line))
                let sp2: i32 = str_find(rest, " ")
                if sp2 >= 0 {
                    let mp: String = str_slice(rest, 0, sp2)
                    // Only show real filesystems (skip proc, sysfs, etc.)
                    let rest2: String = str_slice(rest, sp2 + 1, str_len(rest))
                    let sp3: i32 = str_find(rest2, " ")
                    if sp3 >= 0 {
                        let fstype: String = str_slice(rest2, 0, sp3)
                        if fstype == "ext4" || fstype == "ext3" || fstype == "ext2" || fstype == "xfs" || fstype == "btrfs" || fstype == "tmpfs" || fstype == "vfat" || fstype == "ntfs" {
                            let info: String = statvfs_info(mp)
                            if str_len(info) > 0 {
                                print_str(info)
                                print_str("  ")
                                print_str(mp)
                                print_str("\n")
                                seen += 1
                            }
                        }
                    }
                }
            }
        }
        i += 1
    }
    if seen == 0 {
        print_str("(no filesystems found)\n")
    }
    return 0
}
