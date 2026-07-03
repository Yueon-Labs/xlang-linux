module main

// date [+FORMAT] [-u] [-R] [-I[FMT]] — print the current date/time (GNU date
// subset). With no arguments, prints the ctime-style default. FORMAT follows
// strftime(3): %Y %m %d %H %M %S %Z %z %a %A %b %B %j %p %I %e, etc.
//   +FORMAT              use FORMAT (everything after the leading +)
//   -u, --utc            print in UTC instead of local time
//   -R, --rfc-2822       RFC 2822: "Thu, 03 Jul 2026 10:30:00 +0800"
//   -I, --iso-8601       ISO 8601 date: 2026-07-03
//   -I[FMT]              FMT in {date,hours,minutes,seconds,ns}

// Map an --iso-8601 precision word to a strftime format.
fn iso_format(precision: String): String {
    if precision == "seconds" { return "%Y-%m-%dT%H:%M:%S" }
    if precision == "minutes" { return "%Y-%m-%dT%H:%M" }
    if precision == "hours" { return "%Y-%m-%dT%H:%M" }
    if precision == "ns" { return "%Y-%m-%dT%H:%M:%S" }
    return "%Y-%m-%d"
}

fn main(): i32 {
    let mut utc: i32 = 0
    // Default matches ctime(3): "Wed Jul  3 10:30:00 CST 2026".
    let mut fmt: String = "%a %b %e %H:%M:%S %Z %Y"
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        if str_starts_with(a, "+") {
            fmt = str_slice(a, 1, str_len(a))
        } else if a == "-u" || a == "--utc" || a == "--universal" {
            utc = 1
        } else if a == "-R" || a == "--rfc-2822" || a == "--rfc-email" {
            fmt = "%a, %d %b %Y %H:%M:%S %z"
        } else if a == "-I" || a == "--iso-8601" || a == "--iso-8601=date" {
            fmt = "%Y-%m-%d"
        } else if str_starts_with(a, "--iso-8601=") {
            fmt = iso_format(str_slice(a, 11, str_len(a)))
        } else if a == "-Iseconds" {
            fmt = "%Y-%m-%dT%H:%M:%S"
        } else if a == "-Iminutes" {
            fmt = "%Y-%m-%dT%H:%M"
        } else if a == "-Ihours" {
            fmt = "%Y-%m-%dT%H"
        } else if a == "--version" {
            print_str("date (xlang coreutils) 1.0\n")
            return 0
        } else if a == "--help" || a == "-h" {
            print_str("usage: date [+FORMAT] [-u] [-R] [-I[FMT]]\n")
            return 0
        }
        ai += 1
    }
    let mut out: String = ""
    if utc == 1 {
        out = time_format_utc(fmt)
    } else {
        out = time_format(fmt)
    }
    print_raw(out)
    print_raw("\n")
    return 0
}
