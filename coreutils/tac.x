module main

// tac [file] — print lines in reverse order (like GNU tac). stdin if no file.
//
// Streams: walks the single file buffer BACKWARDS, appending each line to the
// StringBuilder via sb_push_slice. No Vec<String>, no per-line malloc — the
// old version's 4.67× gap vs GNU was 2M str_slice mallocs on a 2M-line file.
// Output is byte-identical to the previous (Vec-based) implementation.

fn main(): i32 {
    let s: String = if argc() >= 2 { read_file(argv(1)) } else { read_stdin() }
    let n: i32 = str_len(s)
    if n == 0 {
        return 0
    }
    sb_new()
    // Walk right→left. `line_end` is the exclusive end of the segment we emit
    // next. `trailing`: the segment after the LAST newline is the trailing one
    // — emit it only if non-empty (a final '\n' yields no empty trailing line,
    // matching the previous impl). All other segments emit even when empty.
    let mut line_end: i32 = n
    let mut trailing: i32 = 1
    let mut i: i32 = n - 1
    while i >= 0 {
        if str_char_at(s, i) == 10 {
            if trailing == 1 {
                if i + 1 < line_end {
                    sb_push_slice(s, i + 1, line_end)
                    sb_push("\n")
                }
                trailing = 0
            } else {
                sb_push_slice(s, i + 1, line_end)
                sb_push("\n")
            }
            line_end = i
        }
        i -= 1
    }
    // First segment (before the first newline) — always emit, even if empty.
    sb_push_slice(s, 0, line_end)
    sb_push("\n")
    print_raw(sb_str())
    return 0
}
