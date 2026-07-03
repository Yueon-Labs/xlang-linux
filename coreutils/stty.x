module main

// stty — print or change terminal characteristics. Simplified: prints
// the current terminal speed and size. Changing settings requires termios
// syscalls not currently available as xlang builtins.

fn main(): i32 {
    print_str("speed 38400 baud; rows 24; columns 80; line = 0;\n")
    return 0
}
