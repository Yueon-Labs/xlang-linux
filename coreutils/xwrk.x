module main

// xwrk <host> <port> <path> <duration_s> <concurrency> — pure-xlang HTTP load
// generator (mini wrk/ab). Forks <concurrency> workers; each opens ONE keepalive
// connection and fires `GET <path>` requests for <duration_s> seconds (now_s
// timing), counting complete responses (Content-Length framed, binary-safe via
// recv_n). Each worker writes its count to a per-worker file; the parent waits,
// sums, and prints req/s.
//
// Dogfoods the whole stack: a pure-xlang tool benchmarking the pure-xlang
// servers, replacing the python bench_py.py client. Concurrency is prefork
// (one blocking keepalive loop per worker); aggregation uses files since fork'd
// processes don't share memory.

// Read exactly one HTTP response (headers + Content-Length body) off a keepalive
// connection, so the stream stays framed for the next request. Returns 1 if a
// complete response was read, 0 if the connection closed first.
fn read_one_response(sock: i32): i32 {
    sb_new()
    let mut total: i32 = 0
    let mut hdrlen: i32 = -1
    let mut cl: i32 = -1
    let mut done: i32 = 0
    while done == 0 {
        let n: i32 = recv_n(sock)
        if n == 0 { return 0 }
        sb_push(rbuf_str())
        total = total + n
        if hdrlen < 0 {
            let buf: String = sb_str()
            let he: i32 = str_find(buf, "\r\n\r\n")
            if he >= 0 {
                hdrlen = he + 4
                let k: i32 = str_find(buf, "Content-Length:")
                if k >= 0 {
                    if k < hdrlen {
                        let blen: i32 = str_len(buf)
                        let mut p: i32 = k + 16
                        while p < blen {
                            if str_char_at(buf, p) == 32 { p = p + 1 } else { break }
                        }
                        let mut ve: i32 = p
                        while ve < blen {
                            let c: i32 = str_char_at(buf, ve)
                            if c == 13 { break }
                            if c == 10 { break }
                            ve = ve + 1
                        }
                        cl = str_to_int(str_slice(buf, p, ve))
                    }
                }
            }
        }
        if hdrlen >= 0 {
            if cl >= 0 {
                if total - hdrlen >= cl { done = 1 }
            } else {
                done = 1
            }
        }
    }
    return 1
}

fn worker(idx: i32, host: String, port: i32, req: String, duration: i32, tmpdir: String): i32 {
    let mut sock: i32 = tcp_connect(host, port)
    if sock >= 0 { set_nodelay(sock) }
    let start: i32 = now_s()
    let mut count: i32 = 0
    while now_s() - start < duration {
        if sock < 0 {
            sock = tcp_connect(host, port)
            if sock >= 0 { set_nodelay(sock) }
        }
        if sock >= 0 {
            send_str(sock, req)
            if read_one_response(sock) == 1 {
                count = count + 1
            } else {
                close_fd(sock)
                sock = -1
            }
        }
    }
    if sock >= 0 { close_fd(sock) }
    let fn_: String = str_concat(str_concat(tmpdir, "/w"), int_to_str(idx))
    write_file(fn_, int_to_str(count))
    return 0
}

fn main(): i32 {
    if argc() < 6 {
        eprint_str("usage: xwrk <host> <port> <path> <duration_s> <concurrency>")
        return 1
    }
    let host: String = argv(1)
    let port: i32 = str_to_int(argv(2))
    let path: String = argv(3)
    let duration: i32 = str_to_int(argv(4))
    let concurrency: i32 = str_to_int(argv(5))

    sb_new()
    sb_push("GET ")
    sb_push(path)
    sb_push(" HTTP/1.1\r\nHost: ")
    sb_push(host)
    sb_push("\r\nConnection: keep-alive\r\n\r\n")
    let req: String = sb_str()

    // Per-run temp dir (keyed by pid) for worker counts.
    let tmpdir: String = str_concat("/tmp/xwrk_", int_to_str(getpid()))
    make_dir(tmpdir)

    let mut i: i32 = 0
    while i < concurrency {
        let pid: i32 = fork()
        if pid == 0 {
            worker(i, host, port, req, duration, tmpdir)
            return 0
        }
        i = i + 1
    }

    // Parent: reap all workers, then sum their counts.
    let mut w: i32 = 0
    while w < concurrency {
        wait_child()
        w = w + 1
    }
    let mut total: i32 = 0
    let mut j: i32 = 0
    while j < concurrency {
        let fn_: String = str_concat(str_concat(tmpdir, "/w"), int_to_str(j))
        let fd: i32 = open_read(fn_)
        if fd >= 0 {
            let s: String = read_fd(fd)
            total = total + str_to_int(s)
            close_fd(fd)
        }
        j = j + 1
    }

    let rps: i32 = total / duration
    print_raw("xwrk: ")
    print_raw(int_to_str(total))
    print_raw(" reqs / ")
    print_raw(int_to_str(duration))
    print_raw("s = ")
    print_raw(int_to_str(rps))
    print_raw(" req/s (")
    print_raw(int_to_str(concurrency))
    print_raw(" keepalive conns)\n")
    return 0
}
