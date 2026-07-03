module main

// unlink <file> — remove a single file (like rm but only one file, no flags).

fn main(): i32 {
    if argc() < 2 {
        eprint_str("usage: unlink <file>\n")
        return 1
    }
    let path: String = argv(1)
    if remove_file(path) != 0 {
        eprint_str("unlink: cannot remove '")
        eprint_str(path)
        eprint_str("'\n")
        return 1
    }
    return 0
}
