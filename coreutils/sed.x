module main

// sed [-n] [-i] [-e SCRIPT]... SCRIPT [file] — stream editor.
// Multiple commands (separated by ';' or multiple -e flags), each with an
// optional line address:
//   [addr]s/pat/repl/[g]   substitute (g = all occurrences on the line; & in
//                          repl = the matched text)
//   [addr]d                delete the line (skip remaining commands, no auto-print)
//   [addr]p                print the line immediately
//   addr = N | N,M         apply only to line N / lines N..M
// -n suppresses automatic end-of-cycle printing. Literal matching (no regex).
// ';' inside s/// is literal (respected during parsing). stdin if no file.
// -i edits the file in place (writes a temp file, renames over the original).

struct SedCmd {
    addr_lo: i32
    addr_hi: i32
    have_addr: i32
    op: i32
    pat: String
    repl: String
    global: i32
}

fn is_digit(c: i32): bool {
    if c < 48 { return false }
    if c > 57 { return false }
    return true
}

fn matches_at(line: String, at: i32, pat: String): bool {
    let ln: i32 = str_len(line)
    let pn: i32 = str_len(pat)
    if pn == 0 { return false }
    if at + pn > ln { return false }
    let mut j: i32 = 0
    while j < pn {
        if str_char_at(line, at + j) != str_char_at(pat, j) { return false }
        j = j + 1
    }
    return true
}

fn substitute(line: String, pat: String, repl: String, global: i32): String {
    let ln: i32 = str_len(line)
    let pn: i32 = str_len(pat)
    if pn == 0 { return line }
    sb_new()
    let mut i: i32 = 0
    let mut did_one: bool = false
    while i < ln {
        let take: bool = (!did_one || global == 1) && matches_at(line, i, pat)
        if take {
            // Expand & in repl to the matched text (pat); other chars literal.
            let rn: i32 = str_len(repl)
            let mut ri: i32 = 0
            while ri < rn {
                if str_char_at(repl, ri) == 38 {
                    sb_push(pat)
                } else {
                    sb_push_char(str_char_at(repl, ri))
                }
                ri = ri + 1
            }
            i = i + pn
            did_one = true
        } else {
            sb_push_char(str_char_at(line, i))
            i = i + 1
        }
    }
    return str_slice(sb_str(), 0, str_len(sb_str()))
}

fn addr_matches(cmd: SedCmd, lineno: i32): bool {
    if cmd.have_addr == 0 { return true }
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
        if pos >= sn { break }
        let op: i32 = str_char_at(script, pos)
        pos = pos + 1
        let mut pat: String = ""
        let mut repl: String = ""
        let mut glob: i32 = 0
        if op == 115 {
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
            if pos < sn {
                if str_char_at(script, pos) == 103 {
                    glob = 1
                    pos = pos + 1
                }
            }
        }
        cmds.push(SedCmd { addr_lo: addr_lo, addr_hi: addr_hi, have_addr: have_addr, op: op, pat: pat, repl: repl, global: glob })
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
                let mut c: i32 = 0
                while c < ncmds {
                    let cmd: SedCmd = cmds[c]
                    if addr_matches(cmd, lineno) {
                        if cmd.op == 115 {
                            cur = substitute(cur, cmd.pat, cmd.repl, cmd.global)
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
