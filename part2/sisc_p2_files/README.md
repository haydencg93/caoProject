# ECE:3350 SISC Processor Part 2 Self-Test

These files automatically check your processor against the expected values
after running Parts 1 + 2 instructions. They do NOT require data memory or
any Part 3 modules — they only test arithmetic, logic, and branch execution.

## Quick Start (ModelSim)

1. Copy all files from this folder into your project directory.
2. In ModelSim:

```
source run_selftest_p2.tcl
run_checkpoint_test
```

The script automatically swaps in the test program and restores your
original `imem.data` when done.

## Quick Start (Icarus Verilog)

```bash
cp imem_p2_test.data imem.data
iverilog -g2005 -o test autograder_p2_checkpoint_tb.v sisc.v ctrl.v rf.v \
    alu.v mux32.v statreg.v br.v im.v ir.v pc.v
vvp test
```

## Available Tests

### `run_checkpoint_test` (recommended)

Checks at three points during execution:

| Checkpoint | After addr | What it verifies |
|---|---|---|
| 1 | 0x0B | Part 1 Section 1: ADI, ADD, SHL, SUB, SHR, XOR, NOT, RTL, OR, AND |
| 2 | 0x11 | Part 1 Section 2: SUB (with status), RTR, ADD (overflow) |
| 3 | HLT  | Part 2 branches: BRA, BRR, BNE (unconditional), BNR |

If checkpoints 1 and 2 pass but 3 fails, your Part 1 still works and
the problem is in your branch logic.

### `run_main_test`

Checks only the final register state (16 registers). Includes diagnostic
hints for common branch bugs.

## Expected Final Values

| Register | Expected | Why |
|---|---|---|
| R1 | 00000001 | Set by ADI |
| R2 | 00000000 | Decremented to 0 by outer loop |
| R3 | 00000000 | Decremented to 0 by inner loop |
| R4 | 00000006 | Accumulated: 3 + 2 + 1 = 6 from nested loops |
| R5 | FF000019 | Set by Part 1 OR instruction, unchanged |

The value R4 = 6 specifically confirms that all four branch types work:
the outer loop runs 3 iterations (controlled by BRR and BNE), and the
inner loop accumulates 3+2+1 (controlled by BNR).

## Files

| File | Purpose |
|------|---------|
| `autograder_p2_tb.v` | Main test — checks final register values |
| `autograder_p2_checkpoint_tb.v` | Checkpoint test — checks at each section |
| `imem_p2_test.data` | Test program (Parts 1+2, HLT at 0x1E) |
| `run_selftest_p2.tcl` | ModelSim runner script |
| `golden_reference_p2.txt` | Instruction-by-instruction expected trace |

## Instance Naming

The testbenches access internals via hierarchical references:

```
uut.u2.ram_array[N]   — Register file (rf, instance u2)
uut.u9.instr          — Instruction register (ir, instance u9)
uut.u10.pc_out        — Program counter (pc, instance u10)
```

If your `sisc.v` uses different instance names, search the testbench
files for `uut.u2`, `uut.u9`, `uut.u10` and update them.

## Troubleshooting

**TIMEOUT:** PC is stuck. Verify `ir_load=1` and `pc_write=1` in fetch.

**Checkpoints 1-2 pass, 3 fails with R4=0:**
The BRA at 0x13 is incorrectly branching to L3, skipping the loops entirely.
This BRA has CC=0010 (N flag). After `ADD R4,R0,R0`, STAT is 0001 (Z=1, N=0).
So `(CC & STAT) = (0010 & 0001) = 0000`, which is NOT != 0 — don't branch.

**R4 = 3 instead of 6:**
Only one outer loop iteration ran. Check that `BNE #0,L1` at 0x1C is
unconditional. BNE with CC=0000 always branches: `(0000 & STAT) == 0` is
always true regardless of STAT.

**R4 > 6:**
The inner loop (BNR at 0x1B) isn't stopping. BNR branches when
`(CC & STAT) == 0`. Here CC=0001 (Z). When SUB produces zero, Z=1, so
`(0001 & 0001) = 0001 != 0` → condition fails → loop stops.
