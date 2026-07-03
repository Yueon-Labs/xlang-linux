module main

// pr — paginate or columnate text for printing. Simple version: adds headers
// and page breaks. GNU pr has many flags; this implements -n (number lines),
// -h (header), -l (page length), and -w (page width).
// Without flags: simple line numbering with 5-digit width.

fn main(): i32 {
    let mut want_n: i32 = 0
    let mut header: String = ""
    let mut page_len: i32 = 66
    let mut page_width: i32 = 72
    let mut have_header: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if str_char_at(a, 0) == '-' && str_len(a) > 1 {
            let flag: i32 = str_char_at(a, 1)
            if flag == 'n' { want_n = 1 }
            if flag == 'h' {
                ai += 1
                if ai < argc() { header = argv(ai) }
                have_header = 1
            }
            if flag == 'l' {
                let rest: String = str_slice(a, 2, str_len(a))
                if str_len(rest) > 0 { page_len = str_to_int(rest) }
            }
            if flag == 'w' {
                let rest: String = str_slice(a, 2, str_len(a))
                if str_len(rest) > 0 { page_width = str_to_int(rest) }
            }
        }
        ai += 1
    }
    let data: String = read_stdin()
    let n: i32 = str_len(data)
    let mut lineno: i32 = 1
    let mut start: i32 = 0
    let mut i: i32 = 0
    let mut on_page: i32 = 0
    let mut lines_this_page: i32 = 0
    let header_text: String = header
    while i <= n {
        let mut at_line_end: i32 = 0
        if i == n { at_line_end = 1 } else {
            if data[i] == '\n' { at_line_end = 1 }
        }
        if at_line_end == 1 {
            if lines_this_page == 0 {
                if have_header == 1 {
                    print_str(header_text)
                    print_str("\n\n")
                }
            }
            if want_n == 1 {
                let num: String = pad_zero(lineno, 5)
                print_str(num)
                print_str(" ")
            }
            print_raw(str_slice(data, start, i))
            print_raw("\n")
            lineno += 1
            lines_this_page += 1
            start = i + 1
            if lines_this_page >= page_len - 5 {
                print_raw("\f")
                lines_this_page = 0
                on_page += 1
            }
        }
        i += 1
    }
    if lines_this_page > 0 { print_raw("\f") }
    return 0
}

fn pad_zero(n: i32, width: i32): String {
    let s: String = int_to_str(n)
    let sl: i32 = str_len(s)
    if sl >= width { return s }
    sb_new()
    let mut k: i32 = sl
    while k < width {
        sb_push(" ")
        k += 1
    }
    sb_push(s)
    return str_slice(sb_str(), 0, str_len(sb_str()))
}
