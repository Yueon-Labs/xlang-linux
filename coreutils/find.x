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

fn find_walk(dir: String, dir_depth: i32, maxdepth: i32, namepat: String, typ: String, ign: i32, exec_tpl: String, have_exec: i32): i32 {
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
                            if have_exec == 1 {
                                run_exec(path, exec_tpl)
                            } else {
                                print_raw(path)
                                print_raw("\n")
                            }
                            count = count + 1
                        }
                    }
                    if isd == 1 {
                        count = count + find_walk(path, entry_depth, maxdepth, namepat, typ, ign, exec_tpl, have_exec)
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
                            // Collect the command + args (until ';'), joined with
                            // spaces; {} placeholders are substituted per match.
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
                            i = i + 1
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
            if have_exec == 1 {
                run_exec(start, exec_tpl)
            } else {
                print_raw(start)
                print_raw("\n")
            }
        }
    }
    find_walk(start, 0, maxdepth, namepat, typ, ign, exec_tpl, have_exec)
    return 0
}
