/* vm_bench_ref.c — hand-written C VM (tagged union + switch), the baseline for
 * vm_bench.x. Same instruction set, same program generation, same execution —
 * so the timing gap is pure enum-match codegen vs a C switch.
 *
 * Usage: vm_bench_ref [N]   (default 2000000)
 */
#include <stdio.h>
#include <stdlib.h>

typedef struct {
    int tag;
    union { int v; } u;   /* Push payload; other variants carry nothing */
} Op;

enum { OP_PUSH, OP_ADD, OP_SUB, OP_MUL, OP_HALT };

static int run(Op *program, int n) {
    static int stack[1024];
    int sp = 0, pc = 0;
    while (pc < n) {
        Op op = program[pc];
        switch (op.tag) {
            case OP_PUSH: stack[sp++] = op.u.v; break;
            case OP_ADD: { int b = stack[--sp], a = stack[--sp]; stack[sp++] = a + b; } break;
            case OP_SUB: { int b = stack[--sp], a = stack[--sp]; stack[sp++] = a - b; } break;
            case OP_MUL: { int b = stack[--sp], a = stack[--sp]; stack[sp++] = a * b; } break;
            case OP_HALT: pc = n; break;
        }
        pc++;
    }
    return sp <= 0 ? 0 : stack[0];
}

int main(int argc, char **argv) {
    int n = 2000000;
    if (argc >= 2) n = atoi(argv[1]);
    Op *program = (Op *)malloc((size_t)(n * 2 + 2) * sizeof(Op));
    int k = 0;
    program[k].tag = OP_PUSH; program[k].u.v = 0; k++;
    for (int i = 0; i < n; i++) {
        program[k].tag = OP_PUSH; program[k].u.v = (i % 100) + 1; k++;
        program[k].tag = OP_ADD; k++;
    }
    program[k].tag = OP_HALT; k++;
    printf("%d\n", run(program, k));
    free(program);
    return 0;
}
