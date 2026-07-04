module main

// find [dir] [-name GLOB] [-iname GLOB] [-type f|d] [-maxdepth N] [-print]
//            [-exec CMD ARGS... ;]
//   -name GLOB    match the entry name against a wildcard glob (* and ?)
//   -iname GLOB   like -name but case-insensitive
//   -type f|d     file | directory
//   -maxdepth N   don't descend below depth N (0 = start point only, like GNU)
//   -print        (accepted, always prints — default action)
//   -exec CMD ... ;  run CMD per match; {} in the args is replaced by the path
//                    (e.g. -exec echo found {} ;). Tokenizes on whitespace, so
//                    paths/args with spaces aren't supported.
//   -delete          delete matched files (and empty directories)
//   -mtime N         modified exactly N days ago; +N = more than, -N = less than
//   -newer FILE      modified more recently than FILE
// Pre-order recursive walk; default start dir is ".". GNU-style depth: the start
// point is depth 0, its entries depth 1, etc.

// Lowercase one ASCII char (A-Z → a-z); -iname uses this for case-insensitive glob.
fn lower_char(c: i32): i32 {
    if c >= 65 && c <= 90 { return c + 32 }
    return c
}

// Wildcard match: '*' = any run, '?' = one char. Iterative with backtracking.
// ign=1 → case-insensitive (for -iname).
fn glob_match(name: String, pat: String, ign: i32): i32 {
    let nn: i32 = str_len(name)
    let pn: i32 = str_len(pat)
    let mut ni: i32 = 0
    let mut pi: i32 = 0
    let mut star: i32 = -1
    let mut nstar: i32 = 0
    while ni < nn {
        let mut mc: i32 = 0
        if pi < pn {
            let mut pc: i32 = str_char_at(pat, pi)
            let mut nc: i32 = str_char_at(name, ni)
            if ign == 1 {
                pc = lower_char(pc)
                nc = lower_char(nc)
            }
            if pc == nc { mc = 1 }
            if pc == 63 { mc = 1 }
        }
        if mc == 1 {
            ni = ni + 1
            pi = pi + 1
        } else {
            let mut isstar: i32 = 0
            if pi < pn {
                if str_char_at(pat, pi) == 42 { isstar = 1 }
            }
            if isstar == 1 {
                star = pi
                nstar = ni
                pi = pi + 1
            } else {
                if star >= 0 {
                    pi = star + 1
                    nstar = nstar + 1
                    ni = nstar
                } else {
                    return 0
                }
            }
        }
    }
    // Name consumed: any remaining pattern must be all '*' (else no match).
    let mut ok2: i32 = 1
    while pi < pn {
        if str_char_at(pat, pi) == 42 { pi = pi + 1 } else { ok2 = 0 }
        if ok2 == 0 { pi = pn }
    }
    if ok2 == 1 { return 1 }
    return 0
}

fn type_ok(isd: i32, typ: String): i32 {
    if str_eq(typ, "f") {
        if isd == 1 { return 0 }
    }
    if str_eq(typ, "d") {
        if isd == 0 { return 0 }
    }
    return 1
}

fn name_ok(name: String, namepat: String, ign: i32): i32 {
    if str_len(namepat) == 0 { return 1 }
    return glob_match(name, namepat, ign)
}

fn size_ok(path: String, thr: i32, mode: i32, mult: i32): i32 {
    if thr < 0 { return 1 }
    let raw_sz: i32 = file_size(path)
    let mut sz: i32 = raw_sz
    if mult > 1 {
        sz = ((raw_sz + mult - 1) / mult) * mult
    }
    if mode > 0 {
        if sz > thr { return 1 }
        return 0
    }
    if mode < 0 {
        if sz < thr { return 1 }
        return 0
    }
    if sz == thr { return 1 }
    return 0
}

fn mtime_ok(path: String, thr: i32, mode: i32): i32 {
    if thr < 0 { return 1 }
    let mtime: i32 = stat_field(path, 5)
    let now: i32 = time_now()
    let age_days: i32 = (now - mtime) / 86400
    if mode > 0 {
        if age_days > thr { return 1 }
        return 0
    }
    if mode < 0 {
        if age_days < thr { return 1 }
        return 0
    }
    if age_days == thr { return 1 }
    return 0
}

// Run an -exec command template (`tpl`, with {} placeholders) for one match:
// substitute {} → path, fork, the child exec's the command (or exits 127 on
// failure), the parent waits — so find survives and runs -exec per match.
// (exec_split tokenizes on whitespace, so this is correct for commands/paths
// without spaces.)
fn run_exec(path: String, tpl: String): i32 {
    let cmd: String = str_replace(tpl, "{}", path)
    let pid: i32 = fork()
    if pid == 0 {
        exec_split(cmd)
        exit(127)
    }
    if pid > 0 {
        wait_child()
    }
    return 0
}

fn find_walk(dir: String, dir_depth: i32, maxdepth: i32, namepat: String, typ: String, ign: i32, exec_tpl: String, have_exec: i32, size_thr: i32, size_mode: i32, size_mult: i32, want_delete: i32, mtime_thr: i32, mtime_mode: i32, newer_thr: i32): i32 {
    let n: i32 = dir_count(dir)
    let mut i: i32 = 0
    let mut count: i32 = 0
    while i < n {
        let entry: String = dir_entry(dir, i)
        if str_len(entry) > 0 {
            if str_char_at(entry, 0) != 46 {
                let entry_depth: i32 = dir_depth + 1
                let within: i32 = 1
                let mut w: i32 = within
                if maxdepth >= 0 {
                    if entry_depth > maxdepth { w = 0 }
                }
                if w == 1 {
                    let path: String = str_concat(str_concat(dir, "/"), entry)
                    let isd: i32 = is_dir(path)
                    if type_ok(isd, typ) == 1 {
                        if name_ok(entry, namepat, ign) == 1 {
                            if size_ok(path, size_thr, size_mode, size_mult) == 1 {
                            if mtime_ok(path, mtime_thr, mtime_mode) == 1 {
                            if newer_thr < 0 || stat_field(path, 5) > newer_thr {
                                if have_exec == 1 {
                                    run_exec(path, exec_tpl)
                                } else {
                                    if want_delete == 1 {
                                        remove_file(path)
                                    } else {
                                        print_raw(path)
                                        print_raw("\n")
                                    }
                                }
                                count = count + 1
                            }
                            }
                            }
                        }
                    }
                    if isd == 1 {
                        count = count + find_walk(path, entry_depth, maxdepth, namepat, typ, ign, exec_tpl, have_exec, size_thr, size_mode, size_mult, want_delete, mtime_thr, mtime_mode, newer_thr)
                    }
                }
            }
        }
        i = i + 1
    }
    return count
}

fn main(): i32 {
    let mut start: String = "."
    let mut namepat: String = ""
    let mut typ: String = ""
    let mut maxdepth: i32 = -1
    let mut ign: i32 = 0
    let mut exec_tpl: String = ""
    let mut have_exec: i32 = 0
    let mut size_thr: i32 = -1
    let mut size_mode: i32 = 0
    let mut size_mult: i32 = 1
    let mut want_delete: i32 = 0
    let mut mtime_thr: i32 = -1
    let mut mtime_mode: i32 = 0
    let mut newer_thr: i32 = -1

    let mut i: i32 = 1
    if argc() >= 2 {
        if str_char_at(argv(1), 0) != 45 {
            start = argv(1)
            i = 2
        }
    }
    while i < argc() {
        if str_eq(argv(i), "-name") {
            if i + 1 < argc() {
                namepat = argv(i + 1)
                ign = 0
            }
            i = i + 2
        } else {
            if str_eq(argv(i), "-iname") {
                if i + 1 < argc() {
                    namepat = argv(i + 1)
                    ign = 1
                }
                i = i + 2
            } else {
                if str_eq(argv(i), "-type") {
                    if i + 1 < argc() { typ = argv(i + 1) }
                    i = i + 2
                } else {
                    if str_eq(argv(i), "-maxdepth") {
                        if i + 1 < argc() { maxdepth = str_to_int(argv(i + 1)) }
                        i = i + 2
                    } else {
                        if str_eq(argv(i), "-exec") {
                            sb_new()
                            let mut j: i32 = i + 1
                            let mut firsta: i32 = 1
                            while j < argc() {
                                let ea: String = argv(j)
                                if str_eq(ea, ";") { break }
                                if firsta == 0 { sb_push(" ") }
                                sb_push(ea)
                                firsta = 0
                                j = j + 1
                            }
                            exec_tpl = str_slice(sb_str(), 0, str_len(sb_str()))
                            have_exec = 1
                            i = j + 1
                        } else {
                            if str_eq(argv(i), "-delete") {
                                want_delete = 1
                                i = i + 1
                            } else {
                                if str_eq(argv(i), "-newer") {
                                    if i + 1 < argc() {
                                        newer_thr = stat_field(argv(i + 1), 5)
                                    }
                                    i = i + 2
                                } else {
                                if str_eq(argv(i), "-mtime") {
                                    if i + 1 < argc() {
                                        let spec: String = argv(i + 1)
                                        let sl: i32 = str_len(spec)
                                        let mut sp2: i32 = 0
                                        mtime_mode = 0
                                        if sl > 0 {
                                            if str_char_at(spec, 0) == 43 { mtime_mode = 1
                                            sp2 = 1 }
                                            if str_char_at(spec, 0) == 45 { mtime_mode = 0 - 1
                                            sp2 = 1 }
                                        }
                                        mtime_thr = 0
                                        while sp2 < sl {
                                            let c: i32 = str_char_at(spec, sp2)
                                            if c >= 48 {
                                                if c <= 57 {
                                                    mtime_thr = mtime_thr * 10 + (c - 48)
                                                }
                                            }
                                            if c < 48 { break }
                                            if c > 57 { break }
                                            sp2 = sp2 + 1
                                        }
                                    }
                                    i = i + 2
                                } else {
                                if str_eq(argv(i), "-size") {
                                if i + 1 < argc() {
                                    let spec: String = argv(i + 1)
                                    let sl: i32 = str_len(spec)
                                    let mut sp: i32 = 0
                                    size_mode = 0
                                    if sl > 0 {
                                        if str_char_at(spec, 0) == 43 { size_mode = 1
                                        sp = 1 }
                                        if str_char_at(spec, 0) == 45 { size_mode = 0 - 1
                                        sp = 1 }
                                    }
                                    let mut num: i32 = 0
                                    while sp < sl {
                                        let c: i32 = str_char_at(spec, sp)
                                        if c >= 48 {
                                            if c <= 57 {
                                                num = num * 10 + (c - 48)
                                                sp = sp + 1
                                            }
                                        }
                                        if c < 48 { break }
                                        if c > 57 { break }
                                    }
                                    let mut mult: i32 = 1
                                    if sp < sl {
                                        let u: i32 = str_char_at(spec, sp)
                                        if u == 99 { mult = 1 }
                                        if u == 107 { mult = 1024 }
                                        if u == 77 { mult = 1048576 }
                                        if u == 71 { mult = 1073741824 }
                                    }
                                    size_mult = mult
                                    size_thr = num * mult
                                }
                                i = i + 2
                            } else {
                                i = i + 1
                            }
                        }
                    }
                    }
                }
                    }
                }
            }
        }
    }

    // Print the start point itself if it passes the filters (GNU behavior).
    let start_isd: i32 = is_dir(start)
    if type_ok(start_isd, typ) == 1 {
        if name_ok(start, namepat, ign) == 1 {
            if size_ok(start, size_thr, size_mode, size_mult) == 1 {
                if have_exec == 1 {
                    run_exec(start, exec_tpl)
                } else {
                    if want_delete == 1 {
                        remove_file(start)
                    } else {
                        print_raw(start)
                        print_raw("\n")
                    }
                }
            }
        }
    }
    find_walk(start, 0, maxdepth, namepat, typ, ign, exec_tpl, have_exec, size_thr, size_mode, size_mult, want_delete, mtime_thr, mtime_mode, newer_thr)
    return 0
}
