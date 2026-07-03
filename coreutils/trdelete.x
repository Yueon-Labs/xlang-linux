module main

// trdelete <chars> — remove all chars in the set from stdin (like `tr -d`).
// Builds a 256-entry lookup table (O(1) per char) and emits via sb_push_char.
fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: trdelete <chars>")
        return 1
    }
    let chars: String = argv(1)
    let table: Vec<i32> = vec_new()
    let mut k: i32 = 0
    while k < 256 {
        table.push(0)
        k += 1
    }
    let cn: i32 = str_len(chars)
    let mut j: i32 = 0
    while j < cn {
        table[str_char_at(chars, j)] = 1
        j += 1
    }
    let s: String = read_stdin()
    let n: i32 = str_len(s)
    let mut i: i32 = 0
    sb_new()
    while i < n {
        let c: i32 = str_char_at(s, i)
        if table[c] == 0 {
            sb_push_char(c)
        }
        i += 1
    }
    print_raw(sb_str())
    return 0
}
