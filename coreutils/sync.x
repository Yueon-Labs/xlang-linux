module main

// sync — flush filesystem buffers. Calls sync(2).

fn main(): i32 {
    sync()
    return 0
}
