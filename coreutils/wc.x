module main

// wc [-l] [-w] [-c] [-m] [-L] [file...] — count lines/words/bytes/chars/longest.
// GNU-compatible flags + column formatting (counts right-justified to the
// width of the largest count). -m (chars) = -c (bytes) for ASCII. Multiple
// files print a per-file line each plus a "total" line. stdin if no file.

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

// Fast newline count for the -l-only case: a single one-pass C loop
// (count_newlines builtin), vs the old str_find_from-per-newline loop.
fn count_lines(text: String): i32 {
    return count_newlines(text)
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

fn digits(n: i32): i32 {
    let mut d: i32 = 1
    let mut v: i32 = n
    if v < 0 {
        v = 0 - v
        d = 2
    }
    while v >= 10 {
        v = v / 10
        d = d + 1
    }
    return d
}

// Largest of the SELECTED counts (for column-width calculation).
fn max_selected(cnt: Counts, want_l: i32, want_w: i32, want_c: i32, want_L: i32): i32 {
    let mut m: i32 = 0
    if want_l == 1 {
        if cnt.lines > m { m = cnt.lines }
    }
    if want_w == 1 {
        if cnt.words > m { m = cnt.words }
    }
    if want_c == 1 {
        if cnt.bytes > m { m = cnt.bytes }
    }
    if want_L == 1 {
        if cnt.maxlen > m { m = cnt.maxlen }
    }
    return m
}

// Print n right-justified to `width` (space-padded).
fn print_padded(n: i32, width: i32): i32 {
    let d: i32 = digits(n)
    let mut s: i32 = 0
    while s < width - d {
        print_raw(" ")
        s = s + 1
    }
    print_raw(int_to_str(n))
    return 0
}

// Print the selected counts (each right-justified to `width`, space-separated),
// followed by name if show_name.
fn print_counts(cnt: Counts, name: String, want_l: i32, want_w: i32, want_c: i32, want_L: i32, width: i32, show_name: i32): i32 {
    let mut first: i32 = 1
    if want_l == 1 {
        print_padded(cnt.lines, width)
        first = 0
    }
    if want_w == 1 {
        if first == 0 { print_raw(" ") }
        print_padded(cnt.words, width)
        first = 0
    }
    if want_c == 1 {
        if first == 0 { print_raw(" ") }
        print_padded(cnt.bytes, width)
        first = 0
    }
    if want_L == 1 {
        if first == 0 { print_raw(" ") }
        print_padded(cnt.maxlen, width)
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
                    // -m (chars) = -c (bytes) for ASCII text.
                    if c == 109 { want_c = 1 }
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
        // GNU wc field width: a piped stream with multiple counts pads to a
        // minimum of 7; a single count isn't padded.
        let dw: i32 = digits(max_selected(cnt, want_l, want_w, want_c, want_L))
        let nc: i32 = want_l + want_w + want_c + want_L
        let w: i32 = if nc > 1 { if dw > 7 { dw } else { 7 } } else { dw }
        print_counts(cnt, "", want_l, want_w, want_c, want_L, w, 0)
        return 0
    }

    // One or more files: two passes — count all, find the global column width,
    // then print each (right-justified) plus a "total" line when >1.
    let fl: Vec<i32> = vec_new()
    let fw: Vec<i32> = vec_new()
    let fb: Vec<i32> = vec_new()
    let fmax: Vec<i32> = vec_new()
    let mut tlines: i32 = 0
    let mut twords: i32 = 0
    let mut tbytes: i32 = 0
    let mut tmax: i32 = 0
    let mut gmax: i32 = 0
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
        fl.push(cnt.lines)
        fw.push(cnt.words)
        fb.push(cnt.bytes)
        fmax.push(cnt.maxlen)
        tlines = tlines + cnt.lines
        twords = twords + cnt.words
        tbytes = tbytes + cnt.bytes
        if cnt.maxlen > tmax { tmax = cnt.maxlen }
        let mv: i32 = max_selected(cnt, want_l, want_w, want_c, want_L)
        if mv > gmax { gmax = mv }
        p = p + 1
    }
    let total: Counts = Counts { lines: tlines, words: twords, bytes: tbytes, maxlen: tmax }
    let tmv: i32 = max_selected(total, want_l, want_w, want_c, want_L)
    if tmv > gmax { gmax = tmv }
    let w: i32 = digits(gmax)
    let mut q: i32 = 0
    while q < nf {
        let cnt: Counts = Counts { lines: fl[q], words: fw[q], bytes: fb[q], maxlen: fmax[q] }
        print_counts(cnt, files[q], want_l, want_w, want_c, want_L, w, 1)
        q = q + 1
    }
    if nf > 1 {
        print_counts(total, "total", want_l, want_w, want_c, want_L, w, 1)
    }
    return 0
}
