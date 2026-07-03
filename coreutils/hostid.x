module main

// hostid — print the numeric identifier of the current host.
// Uses gethostid(2).

fn main(): i32 {
    let id: i32 = get_hostid()
    print_raw(int_to_hex_pad8(id))
    print_raw("\n")
    return 0
}
