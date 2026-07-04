module main

// base32 [-d] — encode (default) or decode (-d) stdin as base32 (RFC 4648),
// like GNU base32. Alphabet A-Z2-7. Encode: 5 bytes -> 8 chars. Decode:
// 8 chars -> 5 bytes (accumulator is i64 since 8*5 = 40 bits > 32).

fn b32_val(c: i32): i32 {
    let mut v: i32 = -1
    if c >= 65 { if c <= 90 { v = c - 65 } }
    if c >= 50 { if c <= 55 { v = c - 50 + 26 } }
    if c >= 97 { if c <= 122 { v = c - 97 } }
    return v
}

fn main(): i32 {
    let mut decode: bool = false
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-d") {
            decode = true
        } else {
            if str_char_at(a, 0) != 45 {
                file = a
            }
        }
        i = i + 1
    }
    let s: String = if str_len(file) > 0 { read_file(file) } else { read_stdin() }
    let n: i32 = str_len(s)
    let table: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
    // valid[r] = output chars for a final group of r bytes (r=1..5).
    let v1: i32 = 2
    let v2: i32 = 4
    let v3: i32 = 5
    let v4: i32 = 7
    let v5: i32 = 8
    sb_new()
    if decode {
        // Streaming decode: accumulate 5 bits per char, emit a byte whenever
        // >= 8 bits are pending. Keeps the accumulator small (i32, ≤ ~12 bits),
        // so no i64 is needed. Leftover <8 bits at EOF are padding (discarded).
        let mut i: i32 = 0
        let mut acc: i32 = 0
        let mut bits: i32 = 0
        while i < n {
            let v: i32 = b32_val(str_char_at(s, i))
            if v >= 0 {
                acc = (acc << 5) | v
                bits += 5
                while bits >= 8 {
                    sb_push_char((acc >> (bits - 8)) & 255)
                    bits -= 8
                    acc = acc & ((1 << bits) - 1)
                }
            }
            i += 1
        }
    } else {
        let mut i: i32 = 0
        while i < n {
            let mut r: i32 = n - i
            if r > 5 { r = 5 }
            let b0: i32 = str_char_at(s, i)
            let mut b1: i32 = 0
            let mut b2: i32 = 0
            let mut b3: i32 = 0
            let mut b4: i32 = 0
            if r >= 2 { b1 = str_char_at(s, i + 1) }
            if r >= 3 { b2 = str_char_at(s, i + 2) }
            if r >= 4 { b3 = str_char_at(s, i + 3) }
            if r >= 5 { b4 = str_char_at(s, i + 4) }
            let c0: i32 = b0 >> 3
            let c1: i32 = ((b0 & 7) << 2) | (b1 >> 6)
            let c2: i32 = (b1 >> 1) & 31
            let c3: i32 = ((b1 & 1) << 4) | (b2 >> 4)
            let c4: i32 = ((b2 & 15) << 1) | (b3 >> 7)
            let c5: i32 = (b3 >> 2) & 31
            let c6: i32 = ((b3 & 3) << 3) | (b4 >> 5)
            let c7: i32 = b4 & 31
            let chunks: Vec<i32> = vec_new()
            chunks.push(c0)
            chunks.push(c1)
            chunks.push(c2)
            chunks.push(c3)
            chunks.push(c4)
            chunks.push(c5)
            chunks.push(c6)
            chunks.push(c7)
            let mut valid: i32 = v5
            if r == 1 { valid = v1 }
            if r == 2 { valid = v2 }
            if r == 3 { valid = v3 }
            if r == 4 { valid = v4 }
            let mut k: i32 = 0
            while k < 8 {
                if k < valid {
                    sb_push_char(str_char_at(table, chunks[k]))
                } else {
                    sb_push_char(61)
                }
                k += 1
            }
            i += 5
        }
    }
    if decode {
        print_raw(sb_str())
    } else {
        print_raw(sb_str())
        print_raw("\n")
    }
    return 0
}
