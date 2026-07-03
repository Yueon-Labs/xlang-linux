module main

// dir — list directory contents (same as ls, GNU's C:\<dir> equivalent).
// This is an alias for ls; GNU dir == ls --format=vertical by default but
// in practice most users use it as ls.

fn main(): i32 {
    let mut ai: i32 = 1
    let files: Vec<String> = vec_new()
    while ai < argc() {
        files.push(argv(ai))
        ai += 1
    }
    let mut path: String = "."
    if vec_len(files) > 0 { path = files[0] }
    let count: i32 = dir_count(path)
    let mut i: i32 = 0
    while i < count {
        let name: String = dir_entry(path, i)
        if str_len(name) > 0 {
            if str_char_at(name, 0) != '.' {
                print_raw(name)
                print_raw("  ")
            }
        }
        i += 1
    }
    print_raw("\n")
    return 0
}
