module main

// diff <a> <b> — line-by-line diff via longest-common-subsequence.
// Prints "< line" for lines only in <a> and "> line" for lines only in <b>,
// in file order (the standard diff markers). Exit 0 if identical, 1 if
// different, 2 on error. The LCS DP is a flat Vec<i32> of size (m+1)*(n+1),
// so it's O(m*n) in time and space — fine for ordinary source files.

// Split file text into a Vec<String> of lines (a trailing newline does not
// create a phantom empty last line).
fn read_lines(path: String): Vec<String> {
    let v: Vec<String> = vec_new()
    let s: String = read_file(path)
    let n: i32 = str_len(s)
    let mut start: i32 = 0
    let mut k: i32 = 0
    while k < n {
        if str_char_at(s, k) == 10 {
            v.push(str_slice(s, start, k))
            start = k + 1
        }
        k = k + 1
    }
    if start < n {
        v.push(str_slice(s, start, n))
    }
    return v
}

fn main(): i32 {
    if argc() < 3 {
        eprint_str("usage: diff <file_a> <file_b>")
        return 2
    }
    let a: Vec<String> = read_lines(argv(1))
    let b: Vec<String> = read_lines(argv(2))
    let m: i32 = vec_len(a)
    let n: i32 = vec_len(b)
    let cols: i32 = n + 1

    // Flat LCS DP table, initialized to 0.
    let dp: Vec<i32> = vec_new()
    let cells: i32 = (m + 1) * cols
    let mut c: i32 = 0
    while c < cells {
        dp.push(0)
        c = c + 1
    }

    // Fill: dp[i][j] = LCS(a[0..i], b[0..j]).
    let mut i: i32 = 1
    while i <= m {
        let mut j: i32 = 1
        while j <= n {
            if str_eq(a[i - 1], b[j - 1]) == 1 {
                dp[i * cols + j] = dp[(i - 1) * cols + (j - 1)] + 1
            } else {
                let up: i32 = dp[(i - 1) * cols + j]
                let left: i32 = dp[i * cols + (j - 1)]
                let mut best: i32 = up
                if left > up { best = left }
                dp[i * cols + j] = best
            }
            j = j + 1
        }
        i = i + 1
    }

    // Backtrack from (m,n); collect ops in reverse order.
    let ops: Vec<String> = vec_new()
    let mut bi: i32 = m
    let mut bj: i32 = n
    while bi > 0 || bj > 0 {
        if bi > 0 {
            if bj > 0 {
                if str_eq(a[bi - 1], b[bj - 1]) == 1 {
                    bi = bi - 1
                    bj = bj - 1
                } else {
                    let up: i32 = dp[(bi - 1) * cols + bj]
                    let left: i32 = dp[bi * cols + (bj - 1)]
                    if left >= up {
                        ops.push(str_concat("> ", b[bj - 1]))
                        bj = bj - 1
                    } else {
                        ops.push(str_concat("< ", a[bi - 1]))
                        bi = bi - 1
                    }
                }
            } else {
                ops.push(str_concat("< ", a[bi - 1]))
                bi = bi - 1
            }
        } else {
            ops.push(str_concat("> ", b[bj - 1]))
            bj = bj - 1
        }
    }

    // Print ops in reverse (file order). Exit 0 if no differences.
    let no: i32 = vec_len(ops)
    let mut p: i32 = no - 1
    while p >= 0 {
        print_raw(ops[p])
        print_raw("\n")
        p = p - 1
    }
    if no == 0 {
        return 0
    }
    return 1
}
