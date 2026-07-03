module main

// cksum — POSIX CRC-32 checksum + byte count. Reads stdin or a file and
// prints "crc size filename". GNU-compatible output format.

// POSIX CRC-32 (not the same as zlib CRC-32). Polynomial: 0x04C11DB7,
// reflected input, augmented with length.
fn cksum_crc(data: String): i64 {
    let n: i32 = str_len(data)
    let mut crc: i64 = 0
    let mut i: i32 = 0
    while i < n {
        crc = crc ^ (int_to_i64(data[i]) << 24)
        let mut j: i32 = 0
        while j < 8 {
            if (crc & 0x80000000) != 0 {
                crc = ((crc << 1) ^ 0x04C11DB7) & 0xFFFFFFFF
            } else {
                crc = (crc << 1) & 0xFFFFFFFF
            }
            j += 1
        }
        i += 1
    }
    // Augment with the length (8 bytes worth of zeros, then fold in length)
    let mut len: i64 = int_to_i64(n)
    let mut k: i32 = 0
    while k < 32 {
        if (crc & 0x80000000) != 0 {
            crc = ((crc << 1) ^ 0x04C11DB7) & 0xFFFFFFFF
        } else {
            crc = (crc << 1) & 0xFFFFFFFF
        }
        k += 1
    }
    crc = crc ^ len
    return crc & 0xFFFFFFFF
}

fn main(): i32 {
    let mut file: String = ""
    if argc() >= 2 {
        file = argv(1)
    }
    let mut data: String = ""
    if str_len(file) > 0 {
        data = read_file(file)
    } else {
        data = read_stdin()
    }
    let crc: i64 = cksum_crc(data)
    let size: i32 = str_len(data)
    print_raw(int_to_str(crc))
    print_raw(" ")
    print_raw(int_to_str(size))
    if str_len(file) > 0 {
        print_raw(" ")
        print_raw(file)
    }
    print_raw("\n")
    return 0
}
