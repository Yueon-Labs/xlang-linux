module main

// hostid — print the numeric identifier of the current host.
// Uses gethostid(2).

fn main(): i32 {
    let id: i32 = stat_field("/etc/hostid", 4)
    if id >= 0 {
        print_raw(int_to_hex(id))
    } else {
        print_str("00000000")
    }
    print_raw("\n")
    return 0
}
