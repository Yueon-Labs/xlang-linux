module main

// wc [-l] [-w] [-c] [-L] [file...] — count lines/words/bytes/longest-line.
// GNU-compatible flags. No flag = lines words bytes. Multiple files print a
// per-file line each plus a "total" line (sum). stdin if no file.

struct Counts {
    lines: i32
    words: i32
    bytes: i32
    maxlen: i32
}

// Count one text blob.
fn count(text: String): Counts {
    let n: i32 = str_len(text)
    let mut lines: i32 = 0
    let mut words: i32 = 0
    let mut bytes: i32 = 0
    let mut maxlen: i32 = 0
    let mut cur: i32 = 0
    let mut in_word: i32 = 0
    let mut k: i32 = 0
    while k < n {
        let c: i32 = str_char_at(text, k)
        bytes = bytes + 1
        if c == 10 {
            lines = lines + 1
            if cur > maxlen { maxlen = cur }
            cur = 0
        } else {
            cur = cur + 1
        }
        if c == 32 || c == 9 || c == 10 || c == 13 {
            in_word = 0
        } else {
            if in_word == 0 {
                words = words + 1
                in_word = 1
            }
        }
        k = k + 1
    }
    if cur > maxlen { maxlen = cur }
    return Counts { lines: lines, words: words, bytes: bytes, maxlen: maxlen }
}

// Fast newline count for the -l-only case: str_find_from scans for '\n' at
// C/memchr speed (bulk), vs the per-char str_char_at loop in count() which the
// Linux scoreboard flagged as ~9x slower than GNU wc -l. Only correct when no
// other count (-w/-c/-L) is needed.
fn count_lines(text: String): i32 {
    let mut lines: i32 = 0
    let mut start: i32 = 0
    while true {
        let pos: i32 = str_find_from(text, "\n", start)
        if pos < 0 { break }
        lines = lines + 1
        start = pos + 1
    }
    return lines
}

fn only_lines(want_l: i32, want_w: i32, want_c: i32, want_L: i32): i32 {
    if want_l == 1 {
        if want_w == 0 {
            if want_c == 0 {
                if want_L == 0 {
                    return 1
                }
            }
        }
    }
    return 0
}

// Print the requested counts (space-separated), followed by name if show_name.
fn print_counts(cnt: Counts, name: String, want_l: i32, want_w: i32, want_c: i32, want_L: i32, show_name: i32): i32 {
    let mut first: i32 = 1
    if want_l == 1 {
        if first == 0 { print_raw(" ") }
        print_raw(int_to_str(cnt.lines))
        first = 0
    }
    if want_w == 1 {
        if first == 0 { print_raw(" ") }
        print_raw(int_to_str(cnt.words))
        first = 0
    }
    if want_c == 1 {
        if first == 0 { print_raw(" ") }
        print_raw(int_to_str(cnt.bytes))
        first = 0
    }
    if want_L == 1 {
        if first == 0 { print_raw(" ") }
        print_raw(int_to_str(cnt.maxlen))
        first = 0
    }
    if show_name == 1 {
        print_raw(" ")
        print_raw(name)
    }
    print_raw("\n")
    return 0
}

fn main(): i32 {
    let mut want_l: i32 = 0
    let mut want_w: i32 = 0
    let mut want_c: i32 = 0
    let mut want_L: i32 = 0
    let files: Vec<String> = vec_new()

    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_len(a) >= 2 {
            if str_char_at(a, 0) == 45 {
                let la: i32 = str_len(a)
                let mut j: i32 = 1
                while j < la {
                    let c: i32 = str_char_at(a, j)
                    if c == 108 { want_l = 1 }
                    if c == 119 { want_w = 1 }
                    if c == 99 { want_c = 1 }
                    if c == 76 { want_L = 1 }
                    j = j + 1
                }
                i = i + 1
            } else {
                files.push(a)
                i = i + 1
            }
        } else {
            files.push(a)
            i = i + 1
        }
    }
    if want_l == 0 {
        if want_w == 0 {
            if want_c == 0 {
                if want_L == 0 {
                    want_l = 1
                    want_w = 1
                    want_c = 1
                }
            }
        }
    }

    // stdin case: no files.
    let nf: i32 = vec_len(files)
    if nf == 0 {
        let s: String = read_stdin()
        let mut cnt: Counts = Counts { lines: 0, words: 0, bytes: 0, maxlen: 0 }
        if only_lines(want_l, want_w, want_c, want_L) == 1 {
            cnt.lines = count_lines(s)
        } else {
            cnt = count(s)
        }
        print_counts(cnt, "", want_l, want_w, want_c, want_L, 0)
        return 0
    }

    // One or more files: per-file line, plus "total" when >1.
    let mut tlines: i32 = 0
    let mut twords: i32 = 0
    let mut tbytes: i32 = 0
    let mut tmax: i32 = 0
    let fast_l: i32 = only_lines(want_l, want_w, want_c, want_L)
    let mut p: i32 = 0
    while p < nf {
        let f: String = files[p]
        let s: String = read_file(f)
        let mut cnt: Counts = Counts { lines: 0, words: 0, bytes: 0, maxlen: 0 }
        if fast_l == 1 {
            cnt.lines = count_lines(s)
        } else {
            cnt = count(s)
        }
        print_counts(cnt, f, want_l, want_w, want_c, want_L, 1)
        tlines = tlines + cnt.lines
        twords = twords + cnt.words
        tbytes = tbytes + cnt.bytes
        if cnt.maxlen > tmax { tmax = cnt.maxlen }
        p = p + 1
    }
    if nf > 1 {
        let total: Counts = Counts { lines: tlines, words: twords, bytes: tbytes, maxlen: tmax }
        print_counts(total, "total", want_l, want_w, want_c, want_L, 1)
    }
    return 0
}
