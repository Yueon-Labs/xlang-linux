module main

// date [+FORMAT] [-u] [-R] [-I[FMT]] [-d @EPOCH] [-r FILE] — print a date/time
// (GNU date subset). With no arguments, prints the ctime-style default now.
// FORMAT follows strftime(3): %Y %m %d %H %M %S %Z %z %a %A %b %B %j %p %I %e.
//   +FORMAT              use FORMAT (everything after the leading +)
//   -u, --utc            UTC instead of local time
//   -R, --rfc-2822       RFC 2822: "Thu, 03 Jul 2026 10:30:00 +0800"
//   -I, --iso-8601       ISO 8601 date: 2026-07-03
//   -I[FMT]              FMT in {date,hours,minutes,seconds,ns}
//   -d @EPOCH            format the given Unix timestamp (seconds since 1970)
//   -r, --reference FILE format FILE's last-modification time

// Map an --iso-8601 precision word to a strftime format.
fn iso_format(precision: String): String {
    if precision == "seconds" { return "%Y-%m-%dT%H:%M:%S" }
    if precision == "minutes" { return "%Y-%m-%dT%H:%M" }
    if precision == "hours" { return "%Y-%m-%dT%H" }
    if precision == "ns" { return "%Y-%m-%dT%H:%M:%S" }
    return "%Y-%m-%d"
}

// Number of leading ASCII-digit characters in s (0 if none).
fn leading_digit_count(s: String): i32 {
    let n: i32 = str_len(s)
    let mut i: i32 = 0
    while i < n {
        let c: i32 = str_char_at(s, i)
        if c < 48 || c > 57 { break }
        i += 1
    }
    return i
}

// Seconds-per-unit for relative dates. Only EXACT multiples of a second are
// listed (so results match GNU byte-for-byte). month/year are deliberately
// omitted — they need calendar arithmetic (variable length) and would diverge.
fn unit_seconds(word: String): i32 {
    if str_starts_with(word, "week") { return 604800 }
    if str_starts_with(word, "day") { return 86400 }
    if str_starts_with(word, "hour") { return 3600 }
    if str_starts_with(word, "minute") { return 60 }
    if str_starts_with(word, "second") { return 1 }
    return 0
}

// Resolve a -d / --date value to a Unix epoch. Supported forms:
//   @EPOCH                 absolute Unix timestamp
//   now | today            current time
//   yesterday | tomorrow   ±1 day
//   "N unit [ago]"         N is a leading integer, unit in
//                          {second,minute,hour,day,week}[s]; "ago" negates.
// Returns DATE_BAD (a sentinel no real result hits) if unrecognized.
fn resolve_date(val: String): i32 {
    let bad: i32 = -2000000000
    if str_starts_with(val, "@") {
        return str_to_int(str_slice(val, 1, str_len(val)))
    }
    let now: i32 = time_now()
    if val == "now" || val == "today" { return now }
    if val == "yesterday" { return now - 86400 }
    if val == "tomorrow" { return now + 86400 }
    let dc: i32 = leading_digit_count(val)
    if dc > 0 {
        let amt: i32 = str_to_int(str_slice(val, 0, dc))
        let mut rest: String = str_slice(val, dc, str_len(val))
        let mut ri: i32 = 0
        while ri < str_len(rest) {
            if str_char_at(rest, ri) == 32 { ri += 1 } else { break }
        }
        rest = str_slice(rest, ri, str_len(rest))
        let secs: i32 = unit_seconds(rest)
        if secs > 0 {
            let mut e: i32 = now + amt * secs
            if str_contains(rest, "ago") { e = now - amt * secs }
            return e
        }
    }
    return bad
}

fn main(): i32 {
    let mut utc: i32 = 0
    // Default matches ctime(3): "Wed Jul  3 10:30:00 CST 2026".
    let mut fmt: String = "%a %b %e %H:%M:%S %Z %Y"
    let mut have_epoch: i32 = 0
    let mut epoch: i32 = 0
    let mut ai: i32 = 1
    while ai < argc() {
        let a: String = argv(ai)
        // step is 1 for single-token flags, 2 for -d/-r (which eat the next arg).
        let mut step: i32 = 1
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
        } else if a == "-d" || a == "--date" {
            if ai + 1 < argc() {
                let val: String = argv(ai + 1)
                let e: i32 = resolve_date(val)
                if e != -2000000000 {
                    epoch = e
                    have_epoch = 1
                }
                step = 2
            }
        } else if str_starts_with(a, "--date=") {
            let val: String = str_slice(a, 7, str_len(a))
            let e: i32 = resolve_date(val)
            if e != -2000000000 {
                epoch = e
                have_epoch = 1
            }
        } else if a == "-r" || a == "--reference" {
            if ai + 1 < argc() {
                let f: String = argv(ai + 1)
                let m: i32 = stat_field(f, 5)
                if m >= 0 {
                    epoch = m
                    have_epoch = 1
                } else {
                    print_str("date: cannot stat '")
                    print_str(f)
                    print_str("'\n")
                    return 1
                }
                step = 2
            }
        } else if str_starts_with(a, "--reference=") {
            let f: String = str_slice(a, 12, str_len(a))
            let m: i32 = stat_field(f, 5)
            if m >= 0 {
                epoch = m
                have_epoch = 1
            } else {
                print_str("date: cannot stat '")
                print_str(f)
                print_str("'\n")
                return 1
            }
        } else if a == "--version" {
            print_str("date (xlang coreutils) 1.0\n")
            return 0
        } else if a == "--help" || a == "-h" {
            print_str("usage: date [+FORMAT] [-u] [-R] [-I[FMT]] [-d @EPOCH] [-r FILE]\n")
            return 0
        }
        ai += step
    }
    let mut out: String = ""
    if have_epoch == 1 {
        if utc == 1 {
            out = time_format_at_utc(fmt, epoch)
        } else {
            out = time_format_at(fmt, epoch)
        }
    } else {
        if utc == 1 {
            out = time_format_utc(fmt)
        } else {
            out = time_format(fmt)
        }
    }
    print_raw(out)
    print_raw("\n")
    return 0
}
