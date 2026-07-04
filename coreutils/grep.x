module main

// grep [OPTIONS] <pattern> [file...]
//   -r   recursive (descend into directories)
//   -n   prefix each match with its line number
//   -i   ignore case
//   -v   invert (print non-matching lines)
//   -c   print only the match count per file
//   -l   print only the filename of files with at least one match
//   -o   print only the matched (non-empty) part of each matching line
//   -H   always prefix the filename
// Combined short flags allowed (e.g. -rin). Regex match (POSIX extended regex,
// like `grep -E`) via the regex_match builtin; patterns without metacharacters
// behave as plain substring search. stdin when no file given. Multi-file / -r /
// -H => "file:line:..." prefix.

// Does `pat` (a POSIX extended regex) match anywhere in `line`? -i folds both
// sides to lowercase first (correct for literal-ish patterns; char-class ranges
// under -i are approximate — use explicit [Aa]-style classes).
fn matches(line: String, pat: String, ignore_case: i32, invert: i32): i32 {
    let mut m: i32 = 0
    if ignore_case == 1 {
        m = regex_match(str_lower(line), str_lower(pat))
    } else {
        m = regex_match(line, pat)
    }
    if invert == 1 {
        if m == 1 { return 0 }
        return 1
    }
    return m
}

// Grep one file's text. show_name => prefix "name:"; -c count / -n line number
// handled here. Returns the number of matches.
fn grep_text(text: String, pat: String, name: String, show_name: i32, ign: i32, inv: i32, want_n: i32, want_c: i32, want_o: i32, want_l: i32): i32 {
    let n: i32 = str_len(text)
    let mut start: i32 = 0
    let mut i: i32 = 0
    let mut lineno: i32 = 0
    let mut count: i32 = 0
    while i <= n {
        // A line ends at a newline, or at EOF with trailing content (a final
        // newline does NOT create a phantom empty last line — matches GNU grep).
        let mut do_line: i32 = 0
        if i < n {
            if str_char_at(text, i) == 10 { do_line = 1 }
        } else {
            if start < n { do_line = 1 }
        }
        if do_line == 1 {
            lineno = lineno + 1
            let line: String = str_slice(text, start, i)
            if matches(line, pat, ign, inv) == 1 {
                count = count + 1
                if want_c == 0 && want_l == 0 {
                        if want_o == 1 {
                        let mut lpat: String = pat
                        let mut lline: String = line
                        if ign == 1 {
                            lpat = str_lower(pat)
                            lline = str_lower(line)
                        }
                        let mut pos: i32 = 0
                        let line_len: i32 = str_len(line)
                        while pos <= line_len {
                            let mstart: i32 = regex_find_from(lline, lpat, pos)
                            if mstart < 0 { break }
                            let mlen: i32 = regex_match_len()
                            if show_name == 1 {
                                print_raw(name)
                                print_raw(":")
                            }
                            if want_n == 1 {
                                print_raw(int_to_str(lineno))
                                print_raw(":")
                            }
                            print_raw(str_slice(line, mstart, mstart + mlen))
                            print_raw("\n")
                            pos = mstart + mlen
                            if mlen == 0 { pos = pos + 1 }
                        }
                    } else {
                        if show_name == 1 {
                            print_raw(name)
                            print_raw(":")
                        }
                        if want_n == 1 {
                            print_raw(int_to_str(lineno))
                            print_raw(":")
                        }
                        print_raw(line)
                        print_raw("\n")
                    }
                }
            }
            start = i + 1
        }
        i = i + 1
    }
    if want_c == 1 {
        if show_name == 1 {
            print_raw(name)
            print_raw(":")
        }
        print_raw(int_to_str(count))
        print_raw("\n")
    }
    return count
}

fn grep_file(path: String, pat: String, show_name: i32, ign: i32, inv: i32, want_n: i32, want_c: i32, want_o: i32, want_l: i32): i32 {
    let text: String = read_file(path)
    let count: i32 = grep_text(text, pat, path, show_name, ign, inv, want_n, want_c, want_o, want_l)
    if want_l == 1 {
        if count > 0 {
            print_raw(path)
            print_raw("\n")
        }
    }
    return count
}

// Recursive descent for -r.
fn grep_recurse(dir: String, pat: String, ign: i32, inv: i32, want_n: i32, want_c: i32, want_o: i32, want_l: i32): i32 {
    let count: i32 = dir_count(dir)
    let mut total: i32 = 0
    let mut k: i32 = 0
    while k < count {
        let entry: String = dir_entry(dir, k)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) != 46 {
                let full: String = str_concat(str_concat(dir, "/"), entry)
                if is_dir(full) {
                    total = total + grep_recurse(full, pat, ign, inv, want_n, want_c, want_o, want_l)
                } else {
                    total = total + grep_file(full, pat, 1, ign, inv, want_n, want_c, want_o, want_l)
                }
            }
        }
        k = k + 1
    }
    return total
}

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: grep [-rinvcolH] <pattern> [file...]")
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
    let mut force_name: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        let arg: String = argv(ai)
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

    if ai >= argc() {
        eprint_str("usage: grep [-rinvcolH] <pattern> [file...]")
        return 1
    }
    let pat: String = argv(ai)
    ai = ai + 1
    let nfiles: i32 = argc() - ai

    // stdin case: no files.
    if nfiles == 0 {
        let text: String = read_stdin()
        let rc: i32 = grep_text(text, pat, "", 0, ign, inv, want_n, want_c, want_o, want_l)
        if want_l == 1 {
            if rc > 0 {
                print_raw("(standard input)\n")
            }
        }
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
                total = total + grep_recurse(target, pat, ign, inv, want_n, want_c, want_o, want_l)
            } else {
                total = total + grep_file(target, pat, show_name, ign, inv, want_n, want_c, want_o, want_l)
            }
        } else {
            total = total + grep_file(target, pat, show_name, ign, inv, want_n, want_c, want_o, want_l)
        }
        ai = ai + 1
    }

    if total > 0 { return 0 }
    return 1
}
