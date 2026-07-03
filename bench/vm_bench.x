module main

// vm_bench — a tiny stack-based bytecode VM, dogfooding payload enums.
// `enum Op { Push(i32), Add, Sub, Mul, Halt }` is the instruction set; the
// dispatcher is a `match` over Op (binding Push's payload). Benchmarks enum
// match dispatch vs a hand-written C VM (tagged union + switch).
//
// Usage: vm_bench [N]   (default 2000000) — runs a generated program and
// prints the final stack-top.

enum Op {
    Push(i32)
    Add
    Sub
    Mul
    Halt
}

// Run a bytecode program on a fixed stack (sp = stack pointer). Returns the
// final stack top (or 0 if empty).
fn run(program: Vec<Op>): i32 {
    let stack: Vec<i32> = vec_new()
    for i in 0..1024 {
        stack.push(0)
    }
    let mut sp: i32 = 0
    let mut pc: i32 = 0
    let n: i32 = vec_len(program)
    while pc < n {
        let op: Op = program[pc]
        match op {
            Push(v) => {
                stack[sp] = v
                sp += 1
            }
            Add => {
                sp -= 1
                let b: i32 = stack[sp]
                sp -= 1
                let a: i32 = stack[sp]
                stack[sp] = a + b
                sp += 1
            }
            Sub => {
                sp -= 1
                let b: i32 = stack[sp]
                sp -= 1
                let a: i32 = stack[sp]
                stack[sp] = a - b
                sp += 1
            }
            Mul => {
                sp -= 1
                let b: i32 = stack[sp]
                sp -= 1
                let a: i32 = stack[sp]
                stack[sp] = a * b
                sp += 1
            }
            Halt => {
                pc = n
            }
        }
        pc += 1
    }
    if sp <= 0 {
        return 0
    }
    return stack[0]
}

fn main(): i32 {
    let mut n: i32 = 2000000
    if argc() >= 2 {
        n = str_to_int(argv(1))
    }
    // Generate a STACK-BALANCED program: Push(0), then (Push(x), Add)*n, Halt.
    // Each (Push, Add) pair nets 0 on sp (Add pops 2, pushes 1; Push pushes 1),
    // so sp stays 1 and the running value accumulates the sum — no overflow of
    // the fixed stack regardless of n.
    let program: Vec<Op> = vec_new()
    program.push(Push(0))
    let mut i: i32 = 0
    while i < n {
        program.push(Push((i % 100) + 1))
        program.push(Add)
        i += 1
    }
    program.push(Halt)
    print_i32(run(program))
    return 0
}
