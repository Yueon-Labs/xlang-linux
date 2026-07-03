module main

// split <file> <lines> — split a file into N-line chunks (like GNU split -l).
// Writes chunks to xsplit_0, xsplit_1, etc. Tracks byte offsets and slices
// each chunk once (O(n) total) instead of accumulating with str_concat.
fn main(): i32 {
    if argc() < 3 {
        eprint_str("usage: split <file> <lines-per-chunk>")
        return 1
    }
    let s: String = read_file(argv(1))
    let lpc: i32 = str_to_int(argv(2))
    let n: i32 = str_len(s)
    let mut fnum: i32 = 0
    let mut lc: i32 = 0
    let mut chunk_start: i32 = 0
    let mut i: i32 = 0
    while i < n {
        if str_char_at(s, i) == 10 {
            lc += 1
            if lc >= lpc {
                write_file(str_concat("xsplit_", int_to_str(fnum)), str_slice(s, chunk_start, i + 1))
                fnum += 1
                lc = 0
                chunk_start = i + 1
            }
        }
        i += 1
    }
    if chunk_start < n {
        write_file(str_concat("xsplit_", int_to_str(fnum)), str_slice(s, chunk_start, n))
        fnum += 1
    }
    print_i32(fnum)
    print_raw(" files written\n")
    return 0
}
