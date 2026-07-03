module main

// nc — pure-xlang netcat (the TCP swiss-army knife). Two modes:
//   nc <host> <port>     connect, then relay stdin <-> socket bidirectionally
//   nc -l <port>         listen, accept one connection, relay stdin <-> socket
//
// Binary-safe end to end (read_rbuf/recv_n in, send_rbuf/write_rbuf out — NUL
// bytes preserved), so `cat file | nc host port` and `nc -l port > out` carry
// arbitrary bytes. Bidirectional relay via fork: the child pumps stdin (fd 0)
// to the socket, the parent pumps the socket to stdout (fd 1). The child ends
// on stdin EOF; the parent ends when the peer closes. SIGPIPE is ignored so a
// dead-peer send doesn't kill the relay.

// Pump stdin (fd 0) -> sock until stdin EOF, then half-close the socket's write
// side (SHUT_WR) so the peer sees EOF while we (the parent) keep reading its
// reply. Without this, an nc<->nc relay deadlocks (each side waits for the
// other to close). (child side of the relay)
fn pump_in(sock: i32): i32 {
    while true {
        let n: i32 = read_rbuf(0)
        if n == 0 { break }
        send_rbuf(sock, n)
    }
    shutdown_wr(sock)
    return 0
}

// Pump sock -> stdout (fd 1) until the peer closes. (parent side of the relay)
fn pump_out(sock: i32): i32 {
    while true {
        let n: i32 = recv_n(sock)
        if n == 0 { break }
        write_rbuf(1, 0, n)
    }
    return 0
}

// Bidirectional relay: fork — child does stdin->sock, parent does sock->stdout.
fn relay(sock: i32): i32 {
    let pid: i32 = fork()
    if pid == 0 {
        pump_in(sock)
        return 0
    }
    pump_out(sock)
    return 0
}

fn main(): i32 {
    ignore_sigpipe()

    // listen mode: nc -l <port>
    if argc() >= 3 {
        if str_eq(argv(1), "-l") {
            let port: i32 = str_to_int(argv(2))
            let lfd: i32 = tcp_listen(port)
            let sock: i32 = accept(lfd)
            close_fd(lfd)
            relay(sock)
            return 0
        }
    }

    // connect mode: nc <host> <port>
    if argc() < 3 {
        eprint_str("usage: nc <host> <port>   |   nc -l <port>")
        return 1
    }
    let host: String = argv(1)
    let port: i32 = str_to_int(argv(2))
    let sock: i32 = tcp_connect(host, port)
    if sock < 0 {
        eprint_str("nc: connection failed")
        return 1
    }
    relay(sock)
    return 0
}
