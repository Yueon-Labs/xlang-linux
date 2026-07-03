module main

// sum [-r] <file> — BSD-style checksum (16-bit, right-rotated). Default
// algorithm. GNU also supports -s (System V), but -r is the common one.

fn sum_bsd(data: String): i32 {
    let n: i32 = str_len(data)
    let mut s: i32 = 0
    let mut i: i32 = 0
    while i < n {
        s += data[i]
        s = (s & 0xFFFF) + ((s >> 16) & 0xFFFF)
        i += 1
    }
    let r: i32 = ((s & 0xFF) << 8) | ((s >> 8) & 0xFF)
    return r & 0xFFFF
}

fn main(): i32 {
    let mut file: String = ""
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if a == "-r" || a == "-s" {
            // flags accepted but ignored (only -r supported)
        } else {
            file = a
        }
        ai += 1
    }
    let mut data: String = ""
    if str_len(file) > 0 {
        data = read_file(file)
    } else {
        data = read_stdin()
    }
    let s: i32 = sum_bsd(data)
    let blocks: i32 = (str_len(data) + 1023) / 1024
    print_raw(int_to_str(s))
    print_raw(" ")
    print_raw(int_to_str(blocks))
    if str_len(file) > 0 {
        print_raw(" ")
        print_raw(file)
    }
    print_raw("\n")
    return 0
}
