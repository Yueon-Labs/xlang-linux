module main

// dd — pure-xlang block copy/convert (mini GNU dd).
//
//   dd [if=<file>] [of=<file>] [bs=<n>] [count=<n>] [skip=<n>] [seek=<n>]
//
// Copies if -> of in up-to-64 KB chunks (read_rbuf/write_rbuf, binary-safe —
// NUL bytes preserved). bs is the offset/count unit: skip/seek advance by
// skip*bs / seek*bs bytes (via lseek), and count limits the number of read
// chunks. Defaults: if=stdin, of=stdout, bs=512, count=unlimited, skip=0,
// seek=0. Output is created/truncated (O_CREAT|O_TRUNC).
//
// Simplifications vs GNU: reads in up-to-64 KB chunks (not exactly bs), no
// conv= (notrunc/etc.), no stats line (no stderr builtin). Core if/of/bs/count/
// skip/seek works and is binary-safe.

fn main(): i32 {
    let mut infile: String = ""
    let mut outfile: String = ""
    let mut bs: i32 = 512
    let mut count: i32 = -1
    let mut skip: i32 = 0
    let mut seekn: i32 = 0

    let mut i: i32 = 1
    while i < argc() {
        let arg: String = argv(i)
        let eq: i32 = str_find(arg, "=")
        if eq >= 0 {
            let name: String = str_slice(arg, 0, eq)
            let val: String = str_slice(arg, eq + 1, str_len(arg))
            if str_eq(name, "if") { infile = val }
            if str_eq(name, "of") { outfile = val }
            if str_eq(name, "bs") { bs = str_to_int(val) }
            if str_eq(name, "count") { count = str_to_int(val) }
            if str_eq(name, "skip") { skip = str_to_int(val) }
            if str_eq(name, "seek") { seekn = str_to_int(val) }
        }
        i = i + 1
    }

    // Open input (stdin if no if=).
    let mut ifd: i32 = 0
    if str_len(infile) > 0 {
        ifd = open_read(infile)
        if ifd < 0 {
            eprint_str("dd: cannot open input")
            return 1
        }
    }
    // Open output (stdout if no of=), create/truncate.
    let mut ofd: i32 = 1
    if str_len(outfile) > 0 {
        ofd = open_write(outfile)
        if ofd < 0 {
            eprint_str("dd: cannot open output")
            return 1
        }
    }

    // skip blocks on input, seek blocks on output (only on seekable files).
    if skip > 0 {
        if str_len(infile) > 0 { seek(ifd, skip * bs) }
    }
    if seekn > 0 {
        if str_len(outfile) > 0 { seek(ofd, seekn * bs) }
    }

    // Copy loop: read up to 64 KB, write it, until EOF or count blocks read.
    let mut total: i32 = 0
    let mut blocks: i32 = 0
    while true {
        if count >= 0 {
            if blocks >= count { break }
        }
        let n: i32 = read_rbuf(ifd)
        if n == 0 { break }
        write_rbuf(ofd, 0, n)
        total = total + n
        blocks = blocks + 1
    }

    if str_len(infile) > 0 { close_fd(ifd) }
    if str_len(outfile) > 0 { close_fd(ofd) }
    return 0
}
