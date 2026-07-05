module main

// sed [-n] [-i] [-e SCRIPT]... SCRIPT [file] — stream editor.
// Multiple commands (separated by ';' or multiple -e flags), each with an
// optional line address:
//   [addr]s/pat/repl/[g]   substitute (g = all occurrences on the line; & in
//                          repl = the matched text)
//   [addr]d                delete the line (skip remaining commands, no auto-print)
//   [addr]p                print the line immediately
//   addr = N | N,M         apply only to line N / lines N..M
// -n suppresses automatic end-of-cycle printing. s/pat/repl/ uses POSIX
// extended-regex matching (patterns without metacharacters are literal).
// ';' inside s/// is literal (respected during parsing). stdin if no file.
// -i edits the file in place (writes a temp file, renames over the original).

struct SedCmd {
    addr_lo: i32
    addr_hi: i32
    have_addr: i32
    addr_re: String
    have_re: i32
    op: i32
    pat: String
    repl: String
    global: i32
    nth: i32
}

fn is_digit(c: i32): bool {
    if c < 48 { return false }
    if c > 57 { return false }
    return true
}

// Regex substitution: pat is a POSIX extended regex; each (non-overlapping,
// or just the first without g) match is replaced by `repl`, with `&` in repl
// expanding to the matched text. Match spans come from regex_find_from /
// regex_match_len (xlang#98). Patterns without metacharacters behave as plain
// literal substitution (all existing cases unchanged).
fn substitute(line: String, pat: String, repl: String, global: i32, nth: i32): String {
    let ln: i32 = str_len(line)
    sb_new()
    let mut i: i32 = 0
    let mut count: i32 = 0
    let mut done: i32 = 0
    while i <= ln {
        if done == 1 {
            break
        }
        let mstart: i32 = regex_find_from(line, pat, i)
        if mstart < 0 || mstart > ln {
            sb_push_slice(line, i, ln)
            done = 1
            break
        }
        let mlen: i32 = regex_match_len()
        count = count + 1
        sb_push_slice(line, i, mstart)
        // Replace THIS match? With nth>0, only the Nth; else the 1st, or all (g).
        let mut do_repl: i32 = 0
        if nth > 0 {
            if count == nth { do_repl = 1 }
        } else {
            if count == 1 || global == 1 { do_repl = 1 }
        }
        if do_repl == 1 {
            let rn: i32 = str_len(repl)
            let mut ri: i32 = 0
            while ri < rn {
                if str_char_at(repl, ri) == 38 {
                    sb_push_slice(line, mstart, mstart + mlen)
                } else {
                    sb_push_char(str_char_at(repl, ri))
                }
                ri = ri + 1
            }
        } else {
            sb_push_slice(line, mstart, mstart + mlen)
        }
        i = mstart + mlen
        if nth > 0 {
            if count >= nth {
                sb_push_slice(line, i, ln)
                done = 1
            }
        } else {
            if global == 0 {
                sb_push_slice(line, i, ln)
                done = 1
            }
        }
        // Zero-length match guard (e.g. `a*`): advance one char so we don't
        // loop forever, passing the char through unchanged.
        if mlen == 0 && done == 0 {
            if i < ln {
                sb_push_char(str_char_at(line, i))
                i = i + 1
            } else {
                done = 1
            }
        }
    }
    return str_slice(sb_str(), 0, str_len(sb_str()))
}

fn addr_matches(cmd: SedCmd, lineno: i32, line: String): bool {
    if cmd.have_addr == 0 {
        if cmd.have_re == 0 { return true }
    }
    if cmd.have_re == 1 {
        if regex_match(line, cmd.addr_re) == 1 { return true }
        return false
    }
    if lineno < cmd.addr_lo { return false }
    if lineno > cmd.addr_hi { return false }
    return true
}

// Parse the combined script into SedCmds, respecting s/// delimiters (a ';'
// inside s/// is literal, not a command separator).
fn parse_script(script: String): Vec<SedCmd> {
    let cmds: Vec<SedCmd> = vec_new()
    let sn: i32 = str_len(script)
    let mut pos: i32 = 0
    while pos < sn {
        while pos < sn {
            if str_char_at(script, pos) == 59 { pos = pos + 1 } else { break }
        }
        if pos >= sn { break }
        let mut addr_lo: i32 = 0
        let mut addr_hi: i32 = 0
        let mut have_addr: i32 = 0
        let mut addr_re: String = ""
        let mut have_re: i32 = 0
        if is_digit(str_char_at(script, pos)) {
            have_addr = 1
            while pos < sn {
                if is_digit(str_char_at(script, pos)) {
                    addr_lo = addr_lo * 10 + (str_char_at(script, pos) - 48)
                    pos = pos + 1
                } else { break }
            }
            addr_hi = addr_lo
            if pos < sn {
                if str_char_at(script, pos) == 44 {
                    pos = pos + 1
                    addr_hi = 0
                    while pos < sn {
                        if is_digit(str_char_at(script, pos)) {
                            addr_hi = addr_hi * 10 + (str_char_at(script, pos) - 48)
                            pos = pos + 1
                        } else { break }
                    }
                }
            }
        }
        if have_addr == 0 {
            if pos < sn {
                if str_char_at(script, pos) == 47 {
                    have_re = 1
                    pos = pos + 1
                    let re_start: i32 = pos
                    while pos < sn {
                        if str_char_at(script, pos) == 47 { break }
                        pos = pos + 1
                    }
                    addr_re = str_slice(script, re_start, pos)
                    if pos < sn { pos = pos + 1 }
                }
            }
        }
        if pos >= sn { break }
        let op: i32 = str_char_at(script, pos)
        pos = pos + 1
        let mut pat: String = ""
        let mut repl: String = ""
        let mut glob: i32 = 0
        let mut nth: i32 = 0
        if op == 115 || op == 121 {
            let sep: i32 = str_char_at(script, pos)
            pos = pos + 1
            let pat_start: i32 = pos
            while pos < sn {
                if str_char_at(script, pos) == sep { break }
                pos = pos + 1
            }
            pat = str_slice(script, pat_start, pos)
            if pos < sn { pos = pos + 1 }
            let repl_start: i32 = pos
            while pos < sn {
                if str_char_at(script, pos) == sep { break }
                pos = pos + 1
            }
            repl = str_slice(script, repl_start, pos)
            if pos < sn { pos = pos + 1 }
            if op == 115 {
                // Flags: g (global), or a number N (replace Nth occurrence).
                while pos < sn {
                    let fc: i32 = str_char_at(script, pos)
                    if fc == 103 {
                        glob = 1
                        pos = pos + 1
                    } else {
                        if fc >= 48 && fc <= 57 {
                            nth = nth * 10 + (fc - 48)
                            pos = pos + 1
                        } else {
                            break
                        }
                    }
                }
            }
        }
        if op == 97 || op == 105 || op == 99 {
            if pos < sn {
                if str_char_at(script, pos) == 32 { pos = pos + 1 }
            }
            if pos < sn {
                if str_char_at(script, pos) == 92 { pos = pos + 1 }
            }
            let text_start: i32 = pos
            while pos < sn {
                if str_char_at(script, pos) == 59 { break }
                pos = pos + 1
            }
            pat = str_slice(script, text_start, pos)
        }
        cmds.push(SedCmd { addr_lo: addr_lo, addr_hi: addr_hi, have_addr: have_addr, addr_re: addr_re, have_re: have_re, op: op, pat: pat, repl: repl, global: glob, nth: nth })
    }
    return cmds
}

fn main(): i32 {
    let mut suppress: i32 = 0
    let mut in_place: i32 = 0
    let mut script: String = ""
    let mut file: String = ""
    let mut i: i32 = 1
    while i < argc() {
        let a: String = argv(i)
        if str_eq(a, "-n") {
            suppress = 1
        } else {
            if str_eq(a, "-i") {
                in_place = 1
            } else {
            if str_eq(a, "-e") {
                i = i + 1
                if i < argc() {
                    if str_len(script) > 0 { script = str_concat(script, ";") }
                    script = str_concat(script, argv(i))
                }
            } else {
                if str_len(script) == 0 {
                    script = a
                } else {
                    file = a
                }
            }
        }
        }
        i = i + 1
    }

    if in_place == 1 {
        if str_len(file) == 0 {
            eprint_str("sed: -i requires a file argument\n")
            return 1
        }
    }
    let cmds: Vec<SedCmd> = parse_script(script)
    let ncmds: i32 = vec_len(cmds)
    let mut text: String = ""
    if str_len(file) > 0 {
        text = read_file(file)
    } else {
        text = read_stdin()
    }
    let n: i32 = str_len(text)
    let mut lineno: i32 = 0
    let mut start: i32 = 0
    let mut k: i32 = 0
    // For -i: collect output here (can't use the global sb during the loop —
    // substitute() uses it), then write+rename after the loop.
    let out_lines: Vec<String> = vec_new()
    while k <= n {
        let is_end: bool = (k == n)
        let mut do_line: bool = is_end
        if is_end == false {
            if str_char_at(text, k) == 10 { do_line = true }
        }
        if do_line {
            if k > start {
                lineno = lineno + 1
                let mut cur: String = str_slice(text, start, k)
                let mut deleted: i32 = 0
                let mut quit: i32 = 0
                let mut append_text: String = ""
                let mut have_append: i32 = 0
                let mut c: i32 = 0
                while c < ncmds {
                    let cmd: SedCmd = cmds[c]
                    if addr_matches(cmd, lineno, cur) {
                        if cmd.op == 115 {
                            cur = substitute(cur, cmd.pat, cmd.repl, cmd.global, cmd.nth)
                        }
                        if cmd.op == 121 {
                            cur = str_translate(cur, cmd.pat, cmd.repl)
                        }
                        if cmd.op == 99 {
                            cur = cmd.pat
                        }
                        if cmd.op == 100 { deleted = 1 }
                        if cmd.op == 112 {
                            if in_place == 1 {
                                out_lines.push(cur)
                                out_lines.push("\n")
                            } else {
                                print_raw(cur)
                                print_raw("\n")
                            }
                        }
                        if cmd.op == 61 {
                            if in_place == 1 {
                                out_lines.push(int_to_str(lineno))
                                out_lines.push("\n")
                            } else {
                                print_raw(int_to_str(lineno))
                                print_raw("\n")
                            }
                        }
                        if cmd.op == 113 {
                            quit = 1
                        }
                        if cmd.op == 105 {
                            if in_place == 1 {
                                out_lines.push(cmd.pat)
                                out_lines.push("\n")
                            } else {
                                print_raw(cmd.pat)
                                print_raw("\n")
                            }
                        }
                        if cmd.op == 97 {
                            append_text = cmd.pat
                            have_append = 1
                        }
                    }
                    if deleted == 1 { c = ncmds } else { c = c + 1 }
                }
                if deleted == 0 {
                    if suppress == 0 {
                        if in_place == 1 {
                            out_lines.push(cur)
                            out_lines.push("\n")
                        } else {
                            print_raw(cur)
                            print_raw("\n")
                        }
                    }
                }
                if have_append == 1 {
                    if in_place == 1 {
                        out_lines.push(append_text)
                        out_lines.push("\n")
                    } else {
                        print_raw(append_text)
                        print_raw("\n")
                    }
                }
                if quit == 1 {
                    break
                }
            }
            start = k + 1
        }
        k = k + 1
    }
    if in_place == 1 {
        // Build the full output (sb is free now — substitute() isn't running)
        // and write it to a temp file, then atomically rename over the original.
        sb_new()
        let mut oi: i32 = 0
        while oi < vec_len(out_lines) {
            sb_push(out_lines[oi])
            oi = oi + 1
        }
        let tmp: String = str_concat(file, ".xlang-sed-tmp")
        write_file(tmp, sb_str())
        rename_file(tmp, file)
    }
    return 0
}
