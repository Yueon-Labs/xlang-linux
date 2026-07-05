module main

// grep [OPTIONS] <pattern> [file...]
//   -r   recursive (descend into directories)
//   -n   prefix each match with its line number
//   -i   ignore case
//   -v   invert (print non-matching lines)
//   -c   print only the match count per file
//   -l   print only the filename of files with at least one match
//   -o   print only the matched (non-empty) part of each matching line
//   -A N  print N lines of context AFTER each match
//   -B N  print N lines of context BEFORE each match
//   -C N  print N lines of context around each match ( = -A N -B N )
//   -H   always prefix the filename
// Combined short flags allowed (e.g. -rin). Regex match (POSIX extended regex,
// like `grep -E`) via the regex_match builtin; patterns without metacharacters
// behave as plain substring search. stdin when no file given. Multi-file / -r /
// -H => "file:line:..." prefix.

// Does `pat` contain a regex metacharacter? If not, it's a plain substring and
// we can skip the regex engine (strstr via str_find is far faster than
// regcomp/regexec) — this is the common grep case.
fn is_literal(pat: String): bool {
    let n: i32 = str_len(pat)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(pat, i)
        if c == 46 { return false }
        if c == 42 { return false }
        if c == 43 { return false }
        if c == 63 { return false }
        if c == 91 { return false }
        if c == 93 { return false }
        if c == 40 { return false }
        if c == 41 { return false }
        if c == 124 { return false }
        if c == 123 { return false }
        if c == 125 { return false }
        if c == 94 { return false }
        if c == 36 { return false }
        if c == 92 { return false }
        i = i + 1
    }
    return true
}

// Does `pat` match anywhere in `line`? Literal patterns use str_find (strstr);
// regex patterns use the POSIX engine. -i folds both sides to lowercase first.
fn matches(line: String, pat: String, ignore_case: i32, invert: i32): i32 {
    let mut m: i32 = 0
    if is_literal(pat) {
        if ignore_case == 1 {
            let hit: i32 = str_find(str_lower(line), str_lower(pat))
            m = if hit >= 0 { 1 } else { 0 }
        } else {
            let hit: i32 = str_find(line, pat)
            m = if hit >= 0 { 1 } else { 0 }
        }
    } else {
        if ignore_case == 1 {
            m = regex_match(str_lower(line), str_lower(pat))
        } else {
            m = regex_match(line, pat)
        }
    }
    if invert == 1 {
        if m == 1 { return 0 }
        return 1
    }
    return m
}

// Match the line text[start..end) against pat. Literal + non-i matches
// directly on the buffer via str_find_range — NO per-line str_slice (the
// hot path for `grep LITERAL file`). Other cases (-i, regex) slice the line.
fn range_matches(text: String, start: i32, end: i32, pat: String, ign: i32, inv: i32, lit: bool): i32 {
    let mut m: i32 = 0
    if lit {
        if ign == 1 {
            let line: String = str_slice(text, start, end)
            let hit: i32 = str_find(str_lower(line), str_lower(pat))
            m = if hit >= 0 { 1 } else { 0 }
        } else {
            let hit: i32 = str_find_range(text, pat, start, end)
            m = if hit >= 0 { 1 } else { 0 }
        }
    } else {
        let line: String = str_slice(text, start, end)
        if ign == 1 {
            m = regex_match(str_lower(line), str_lower(pat))
        } else {
            m = regex_match(line, pat)
        }
    }
    if inv == 1 {
        if m == 1 { return 0 }
        return 1
    }
    return m
}

// Context-mode grep (-A/-B/-C): two-pass. First collect all lines + match
// flags, then print each line that is within ctx_b lines before or ctx_a lines
// after any match, with "--" separators between non-contiguous groups.
fn grep_text_ctx(text: String, pat: String, name: String, show_name: i32, ign: i32, inv: i32, want_n: i32, ctx_a: i32, ctx_b: i32): i32 {
    let n: i32 = str_len(text)
    let lines: Vec<String> = vec_new()
    let lnums: Vec<i32> = vec_new()
    let mf: Vec<i32> = vec_new()
    let mut start: i32 = 0
    let mut i: i32 = 0
    let mut lineno: i32 = 0
    while i <= n {
        let mut do_line: i32 = 0
        if i < n {
            if str_char_at(text, i) == 10 { do_line = 1 }
        } else {
            if start < n { do_line = 1 }
        }
        if do_line == 1 {
            lineno = lineno + 1
            let line: String = str_slice(text, start, i)
            lines.push(line)
            lnums.push(lineno)
            mf.push(matches(line, pat, ign, inv))
            start = i + 1
        }
        i = i + 1
    }
    let nl: i32 = vec_len(lines)
    let mut count: i32 = 0
    let mut last_pr: i32 = -1000000
    let mut li: i32 = 0
    while li < nl {
        let mut hot: i32 = 0
        if mf[li] == 1 {
            hot = 1
        } else {
            let mut j: i32 = li - ctx_a
            if j < 0 { j = 0 }
            let mut je: i32 = li + ctx_b
            if je >= nl { je = nl - 1 }
            while j <= je {
                if mf[j] == 1 { hot = 1 }
                j = j + 1
            }
        }
        if hot == 1 {
            if mf[li] == 1 { count = count + 1 }
            if last_pr >= 0 {
                if lnums[li] > last_pr + 1 {
                    sb_push("--\n")
                }
            }
            if show_name == 1 {
                sb_push(name)
                sb_push(":")
            }
            if want_n == 1 {
                sb_push(int_to_str(lnums[li]))
                sb_push(":")
            }
            sb_push(lines[li])
            sb_push("\n")
            last_pr = lnums[li]
        }
        li = li + 1
    }
    return count
}

// Grep one file's text. show_name => prefix "name:"; -c count / -n line number
// handled here. Returns the number of matches.
fn grep_text(text: String, pat: String, name: String, show_name: i32, ign: i32, inv: i32, want_n: i32, want_c: i32, want_o: i32, want_l: i32, ctx_a: i32, ctx_b: i32): i32 {
    let n: i32 = str_len(text)
    let lit: bool = is_literal(pat)
    let mut start: i32 = 0
    let mut lineno: i32 = 0
    let mut count: i32 = 0
    while true {
        // Bulk newline scan (str_find_from = memchr) instead of a per-char
        // str_char_at loop — same trick as uniq/wc. i = end of the current line.
        let nl: i32 = str_find_from(text, "\n", start)
        let i: i32 = if nl < 0 { n } else { nl }
        // A line ends at a newline, or at EOF with trailing content (a final
        // newline does NOT create a phantom empty last line — matches GNU grep).
        let do_line: i32 = if nl >= 0 { 1 } else { if start < n { 1 } else { 0 } }
        if do_line == 1 {
            lineno = lineno + 1
            if range_matches(text, start, i, pat, ign, inv, lit) == 1 {
                count = count + 1
                if want_c == 0 && want_l == 0 {
                    if want_o == 1 {
                        // -o needs per-match positions; slice the line only here
                        // (and only for matching lines), not for every line.
                        let line: String = str_slice(text, start, i)
                        let mut lpat: String = pat
                        let mut lline: String = line
                        if ign == 1 {
                            lpat = str_lower(pat)
                            lline = str_lower(line)
                        }
                        // Literal -o: str_find_from + fixed match length;
                        // regex -o: regex_find_from + regex_match_len.
                        let lit_len: i32 = str_len(lpat)
                        let mut pos: i32 = 0
                        let line_len: i32 = str_len(line)
                        while pos <= line_len {
                            let mstart: i32 = if lit { str_find_from(lline, lpat, pos) } else { regex_find_from(lline, lpat, pos) }
                            if mstart < 0 { break }
                            let mlen: i32 = if lit { lit_len } else { regex_match_len() }
                            if show_name == 1 {
                                sb_push(name)
                                sb_push(":")
                            }
                            if want_n == 1 {
                                sb_push_i32(lineno)
                                sb_push(":")
                            }
                            sb_push_slice(line, mstart, mstart + mlen)
                            sb_push("\n")
                            pos = mstart + mlen
                            if mlen == 0 { pos = pos + 1 }
                        }
                    } else {
                        if show_name == 1 {
                            sb_push(name)
                            sb_push(":")
                        }
                        if want_n == 1 {
                            sb_push_i32(lineno)
                            sb_push(":")
                        }
                        // Emit the line straight from the text buffer — no
                        // per-line str_slice (the old sb_push(line) malloc'd).
                        sb_push_slice(text, start, i)
                        sb_push("\n")
                    }
                }
            }
            start = i + 1
        }
        if nl < 0 { break }
    }
    if want_c == 1 {
        if show_name == 1 {
            sb_push(name)
            sb_push(":")
        }
        sb_push_i32(count)
        sb_push("\n")
    }
    return count
}

fn grep_file(path: String, pat: String, show_name: i32, ign: i32, inv: i32, want_n: i32, want_c: i32, want_o: i32, want_l: i32, ctx_a: i32, ctx_b: i32): i32 {
    let text: String = read_file(path)
    if ctx_a > 0 || ctx_b > 0 {
        return grep_text_ctx(text, pat, path, show_name, ign, inv, want_n, ctx_a, ctx_b)
    }
    let count: i32 = grep_text(text, pat, path, show_name, ign, inv, want_n, want_c, want_o, want_l, ctx_a, ctx_b)
    if want_l == 1 {
        if count > 0 {
            sb_push(path)
            sb_push("\n")
        }
    }
    return count
}

// Recursive descent for -r.
fn grep_recurse(dir: String, pat: String, ign: i32, inv: i32, want_n: i32, want_c: i32, want_o: i32, want_l: i32, ctx_a: i32, ctx_b: i32): i32 {
    let count: i32 = dir_count(dir)
    let mut total: i32 = 0
    let mut k: i32 = 0
    while k < count {
        let entry: String = dir_entry(dir, k)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) != 46 {
                let full: String = str_concat(str_concat(dir, "/"), entry)
                if is_dir(full) {
                    total = total + grep_recurse(full, pat, ign, inv, want_n, want_c, want_o, want_l, ctx_a, ctx_b)
                } else {
                    total = total + grep_file(full, pat, 1, ign, inv, want_n, want_c, want_o, want_l, ctx_a, ctx_b)
                }
            }
        }
        k = k + 1
    }
    return total
}

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: grep [-rinvcolH] [-ABC N] <pattern> [file...]")
        return 1
    }

    // Parse flags from leading -args.
    let mut rec: i32 = 0
    let mut want_n: i32 = 0
    let mut ign: i32 = 0
    let mut inv: i32 = 0
    let mut want_c: i32 = 0
    let mut want_o: i32 = 0
    let mut want_l: i32 = 0
    let mut ctx_a: i32 = 0
    let mut ctx_b: i32 = 0
    let mut force_name: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        let arg: String = argv(ai)
        if str_eq(arg, "-A") {
            if ai + 1 < argc() { ctx_a = str_to_int(argv(ai + 1)) }
            ai = ai + 2
        } else {
            if str_eq(arg, "-B") {
                if ai + 1 < argc() { ctx_b = str_to_int(argv(ai + 1)) }
                ai = ai + 2
            } else {
                if str_eq(arg, "-C") {
                    if ai + 1 < argc() {
                        ctx_a = str_to_int(argv(ai + 1))
                        ctx_b = str_to_int(argv(ai + 1))
                    }
                    ai = ai + 2
                } else {
                    if str_len(arg) >= 2 {
                        if str_char_at(arg, 0) == 45 {
                            let mut ci: i32 = 1
                            while ci < str_len(arg) {
                                let f: i32 = str_char_at(arg, ci)
                                if f == 114 { rec = 1 }
                                if f == 110 { want_n = 1 }
                                if f == 105 { ign = 1 }
                                if f == 118 { inv = 1 }
                                if f == 99 { want_c = 1 }
                                if f == 111 { want_o = 1 }
                                if f == 108 { want_l = 1 }
                                if f == 72 { force_name = 1 }
                                ci = ci + 1
                            }
                            ai = ai + 1
                        } else {
                            break
                        }
                    } else {
                        break
                    }
                }
            }
        }
    }

    if ai >= argc() {
        eprint_str("usage: grep [-rinvcolH] [-ABC N] <pattern> [file...]")
        return 1
    }
    let pat: String = argv(ai)
    ai = ai + 1
    let nfiles: i32 = argc() - ai

    // Buffer all stdout (matches / -o / -c / -l / context) into one
    // StringBuilder, flushed once at the end. Every match previously cost
    // 2-4 print_raw syscalls; on a file with many matches that dominates.
    // Errors stay on stderr via eprint_str, untouched. Order is preserved.
    sb_new()

    // stdin case: no files.
    if nfiles == 0 {
        let text: String = read_stdin()
        if ctx_a > 0 || ctx_b > 0 {
            let rc: i32 = grep_text_ctx(text, pat, "(standard input)", 0, ign, inv, want_n, ctx_a, ctx_b)
            print_raw(sb_str())
            if rc > 0 { return 0 }
            return 1
        }
        let rc: i32 = grep_text(text, pat, "", 0, ign, inv, want_n, want_c, want_o, want_l, ctx_a, ctx_b)
        if want_l == 1 {
            if rc > 0 {
                sb_push("(standard input)\n")
            }
        }
        print_raw(sb_str())
        if rc > 0 { return 0 }
        return 1
    }

    let mut show_name: i32 = 1
    if force_name == 0 {
        if nfiles == 1 {
            if rec == 0 { show_name = 0 }
        }
    }

    let mut total: i32 = 0
    while ai < argc() {
        let target: String = argv(ai)
        if rec == 1 {
            if is_dir(target) {
                total = total + grep_recurse(target, pat, ign, inv, want_n, want_c, want_o, want_l, ctx_a, ctx_b)
            } else {
                total = total + grep_file(target, pat, show_name, ign, inv, want_n, want_c, want_o, want_l, ctx_a, ctx_b)
            }
        } else {
            total = total + grep_file(target, pat, show_name, ign, inv, want_n, want_c, want_o, want_l, ctx_a, ctx_b)
        }
        ai = ai + 1
    }

    print_raw(sb_str())
    if total > 0 { return 0 }
    return 1
}
