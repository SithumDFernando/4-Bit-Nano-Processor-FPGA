# 4-Bit Nanoprocessor — Complete Technical Guide

> **Target Board:** Digilent Basys 3 (Xilinx Artix-7 XC7A35T)  
> **Language:** VHDL  
> **Architecture:** Single-cycle, synchronous, 4-bit processor  
> **Clock:** 100 MHz divided to ~0.5 Hz for human-visible execution

---

## Table of Contents

1. [What Is This Processor?](#1-what-is-this-processor)
2. [Full System Architecture Diagram](#2-full-system-architecture-diagram)
3. [Instruction Set Architecture (ISA)](#3-instruction-set-architecture-isa)
4. [Full Execution Flow — Step by Step](#4-full-execution-flow--step-by-step)
5. [Sub-Component Overview (High Level)](#5-sub-component-overview-high-level)
6. [Deep Dive Into Each Component](#6-deep-dive-into-each-component)
7. [Optimization Techniques](#7-optimization-techniques)
8. [Line-by-Line VHDL Explanation](#8-line-by-line-vhdl-explanation)
9. [Constraint File (XDC) Explained](#9-constraint-file-xdc-explained)
10. [Example Program Walkthrough](#10-example-program-walkthrough)

---

## 1. What Is This Processor?

A **nanoprocessor** is the simplest possible CPU you can build that still does real computation. Think of it as a stripped-down version of the processor in your phone or laptop — reduced to its absolute core: fetch an instruction, decode it, execute it, write the result, move to the next instruction.

This particular design is:

- **4-bit**: all data values are 4-bit numbers (0–15)
- **Single-cycle**: every instruction completes in exactly one clock tick
- **Harvard-style**: instructions live in separate ROM; data lives in registers
- **8 registers** (R0–R7), where R0 is hardwired to 0
- **8 instructions** (locations 0–7) in ROM
- **4 operations**: MOVI, ADD, NEG, JZR

This is built entirely from primitive logic gates and flip-flops — no processor IP, no soft cores. Every AND gate, every flip-flop, every multiplexer is written explicitly in VHDL.

---

## 2. Full System Architecture Diagram

```
                        ┌──────────────────────────────────────────────────────────────────┐
                        │                     NANOPROCESSOR (top level)                    │
                        │                                                                  │
 Clk ──► SLOW_CLK ──────►─────────────────────────────────────────────►  Slw_Clk          │
                        │                                                    │             │
 Clr ───────────────────►──────────────────────────────────────────────►────┤             │
                        │                                               │    │             │
                        │   ┌─────────┐   PC_ROM (3-bit)               │    │             │
                        │   │   PC    │◄──────────────────────────────  │    │             │
                        │   │(3 D-FFs)│   Q = current address          │    │             │
                        │   └────┬────┘                                │    │             │
                        │        │ PC_ROM                              │    │             │
                        │        ▼                                     │    │             │
                        │   ┌─────────┐   ROM_Decoder (12-bit)        │    │             │
                        │   │   ROM   │──────────────────────────────► │    │             │
                        │   │(8 × 12b)│                               │    │             │
                        │   └─────────┘                               │    │             │
                        │                                              │    │             │
                        │        │ PC_ROM                             │    │             │
                        │        ▼                                    │    │             │
                        │   ┌─────────┐   Add3_MuxC (PC+1)          │    │             │
                        │   │ ADDER_3 │─────────────────────────────►│    │             │
                        │   │  (+1)   │                              │    │             │
                        │   └─────────┘                              │    │             │
                        │                                             │    │             │
                        │   ROM_Decoder ─────────────────────────►   │    │             │
                        │                                         │   │    │             │
                        │   ┌──────────────────────┐             │   │    │             │
                        │   │  INSTRUCTION_DEC     │◄────────────┘   │    │             │
                        │   │                      │                 │    │             │
                        │   │  Reg_EN  ──────────────────────────────►────┤            │
                        │   │  Mux_A   ──────────────────────────►   │    │            │
                        │   │  Mux_B   ──────────────────────────►   │    │            │
                        │   │  LD      ─────────────────────────────────────────────► │
                        │   │  Sub     ─────────────────────────────────────────────► │
                        │   │  LSB     ─────────────────────────────────────────────► │
                        │   │  JMP     ─────────────────────────────────────────────► │
                        │   └──────────────────────┘                 │    │            │
                        │                                             │    │            │
                        │   ┌─────────────────────────────────┐      │    │            │
                        │   │        REG_BANK (R0–R7)         │◄─────┘    │            │
                        │   │  (DEC_3_8 → 7 × REG_4)         │           │            │
                        │   │  R0=0000 (hardwired)            │           │            │
                        │   └──────┬──────────────────────────┘           │            │
                        │          │ R0..R7 (each 4-bit)                  │            │
                        │          ▼                                       │            │
                        │   ┌──────────────┐   ┌──────────────┐          │            │
                        │   │  MUX_8_to_1  │   │  MUX_8_to_1  │          │            │
                        │   │   (MuxA)     │   │   (MuxB)     │          │            │
                        │   │  sel=Mux_A  │   │  sel=Mux_B  │          │            │
                        │   └──────┬───────┘   └──────┬───────┘          │            │
                        │          │ MuxA_Adder        │ MuxB_Adder       │            │
                        │          ▼                   ▼                  │            │
                        │   ┌──────────────────────────────────┐          │            │
                        │   │        ADD_SUB_4                 │          │            │
                        │   │  (4 FAs, XOR-based sub control)  │          │            │
                        │   │  overflow ────────────────────────────────────────────► │
                        │   └──────────────┬───────────────────┘          │            │
                        │                  │ MuxD_Adder (4-bit)           │            │
                        │                  │                               │            │
                        │   ┌─────────────────────────┐                   │            │
                        │   │    MUX_2_to_1_4B (MuxD) │◄── Decoder_MuxD  │            │
                        │   │    S = LD               │    (LSB/imm)      │            │
                        │   └──────────┬──────────────┘                   │            │
                        │              │ MuxD_RegBank                      │            │
                        │              └──────────────────────────────────►┘            │
                        │                                                               │
                        │   Zero ◄── NOR4(MuxD_Adder)                                 │
                        │   R    ◄── R7                                               │
                        │   Seven_Seg ◄── LUT_7_SEG(R7)                              │
                        │   an   ◄── "1110" (rightmost digit active)                 │
                        └──────────────────────────────────────────────────────────────┘
```

### PC Update Path

```
         PC_ROM ──► ADDER_3 ──► Add3_MuxC ──►┐
                                               ├──► MUX_2_1_3B (MuxC) ──► PC_MuxC ──► PC
         Decoder_MuxD[2:0] ────────────────►──┘
                  ▲
                  │ JMP (from INSTRUCTION_DEC)
                  │ selects jump address when reg==0
```

---

## 3. Instruction Set Architecture (ISA)

The processor supports exactly **4 instructions**, each encoded as **12 bits**.

### Instruction Encoding Table

```
Bits:   11  10  |  9  8  7  |  6  5  4  |  3  2  1  0
        [opcode] [  Ra/R   ] [   Rb    ] [  imm/addr  ]
```

| Instruction | Bit 11 | Bit 10 | Bits [9:7] | Bits [6:4] | Bits [3:0] | Operation |
|-------------|--------|--------|------------|------------|------------|-----------|
| **MOVI R, d** | 1 | 0 | R (dest) | 000 | d (4-bit imm) | R ← d |
| **ADD Ra, Rb** | 0 | 0 | Ra (dest) | Rb (src) | 0000 | Ra ← Ra + Rb |
| **NEG R** | 0 | 1 | R (target) | R (same) | 0000 | R ← −R (2's complement) |
| **JZR R, d** | 1 | 1 | R (test) | 000 | 0ddd (3-bit addr) | If R==0: PC←d else PC←PC+1 |

### Opcode Decoding (2 bits → 4 instructions)

```
Bit11  Bit10  |  Instruction
  0      0    |  ADD
  0      1    |  NEG
  1      0    |  MOVI
  1      1    |  JZR
```

### Example Instruction Encodings

```
"100010000011"  →  MOVI R1, 3
  1  0  001  000  0011
  │  │   │         │
  │  │   R1         3 (immediate)
  │  │
  MOVI opcode (10)

"000010100000"  →  ADD R1, R2
  0  0  001  010  0000
  │  │   │    │
  │  │   R1   R2
  ADD opcode (00)

"010100000000"  →  NEG R2
  0  1  010  000  0000
  │  │   │
  │  │   R2
  NEG opcode (01)

"110010000111"  →  JZR R1, 7
  1  1  001  000  0111
  │  │   │         │
  │  │   R1         address 7
  JZR opcode (11)
```

---

## 4. Full Execution Flow — Step by Step

Every clock cycle, all of these stages happen **simultaneously** (combinational), and the results are captured **on the rising edge** (sequential). This is the single-cycle model.

```
CLOCK EDGE
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 1 — FETCH                                                     │
│  PC_ROM → ROM → ROM_Decoder (12-bit instruction)                    │
│  Simultaneously: ADDER_3 computes PC_ROM + 1 = Add3_MuxC            │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 2 — DECODE                                                    │
│  INSTRUCTION_DEC reads ROM_Decoder bits [11:10] and produces:       │
│    • Reg_EN  → which register to write into (R0–R7)                 │
│    • Mux_A   → which register is operand A                          │
│    • Mux_B   → which register is operand B                          │
│    • Sub     → ADD (0) or SUB/NEG (1) mode for the ALU              │
│    • LD      → 0 = use ALU result, 1 = use immediate value          │
│    • LSB     → the 4-bit immediate value from instruction           │
│    • JMP     → 1 if jump condition is met (reg==0 AND JZR)          │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 3 — REGISTER READ                                             │
│  MuxA (MUX_8_to_1): selects R[Mux_A] → MuxA_Adder                 │
│  MuxB (MUX_8_to_1): selects R[Mux_B] → MuxB_Adder                 │
│  (For NEG: both muxes point to the same register)                   │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 4 — EXECUTE (ALU)                                             │
│  ADD_SUB_4:                                                          │
│    If Sub=0 (ADD):   S = A + B                                      │
│    If Sub=1 (NEG):   S = A + (NOT B) + 1 = A - B                   │
│    For NEG:  A=R, B=R, so S = R + (NOT R) + 1 = 0 + 1 = -R (2's) │
│  Overflow flag: FA2_C XOR C_out                                     │
│  Zero flag: NOR of all 4 result bits                                │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 5 — WRITEBACK DATA SELECT                                     │
│  MuxD (MUX_2_to_1_4B):                                              │
│    If LD=0: Q = ALU result (MuxD_Adder) → used for ADD/NEG         │
│    If LD=1: Q = LSB (immediate value)   → used for MOVI            │
│  MuxD_RegBank → data to be written to register bank                │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ STAGE 6 — PC UPDATE SELECT                                          │
│  MuxC (MUX_2_to_1_3B):                                              │
│    If JMP=0: Q = PC+1 (sequential execution)                        │
│    If JMP=1: Q = LSB[2:0] (jump to address from instruction)        │
│  PC_MuxC → new PC value                                             │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ RISING CLOCK EDGE — ALL STATE UPDATES HAPPEN HERE                  │
│  1. PC latches PC_MuxC → new instruction address                    │
│  2. REG_BANK: the selected register (Reg_EN) latches MuxD_RegBank   │
│     (only if Reg_EN ≠ "000" — JZR does not write to any register)  │
└─────────────────────────────────────────────────────────────────────┘
```

### NEG Instruction — Why It Works

NEG R computes the 2's complement negation. The 2's complement of a number N is `NOT(N) + 1`.

```
ADD_SUB_4 with M=1 (subtract mode):
  B_modified = B XOR M = B XOR 1 = NOT(B)
  C_in of first FA = M = 1
  Result = A + NOT(B) + 1

For NEG R:
  Mux_A points to R,  Mux_B also points to R
  So A = R, B = R
  Result = R + NOT(R) + 1
         = 0xF + 1      (since R + NOT(R) = all ones = 0xF for 4 bits)
         = 0 + 1        ... no wait:
  Actually: R + NOT(R) = 1111 (all ones = 15), then +1 = 0000 with carry
  But the carry is discarded (it overflows), so effectively we computed -R.
  
  More concretely:
    R = 0011 (3)
    NOT(R) = 1100
    NOT(R) + 1 = 1101 (13 = -3 in 4-bit 2's complement)
    
  So A + NOT(B) + 1 with A=R=0 (we want 0 + NOT(R) + 1):
    Wait — A=R and B=R, so: R + NOT(R) + 1 = 1111 + 1 = 0000 with carry.
    That gives 0, not -R.
  
  The trick: Mux_B uses Inst[9:7] for NEG, which IS the same register as Mux_A.
  But what we actually want is 0 - R = NOT(R) + 1.
  With A=R and B=R: A + NOT(B) + 1 = R + NOT(R) + 1 = 15 + 1 = 0 (wrong!)
  
  CORRECTION — Looking at the actual decoder:
    Mux_A for NEG: "000" (so A = R0 = 0)
    Mux_B for NEG: Inst[9:7] (so B = the target register R)
    
  So: A=0, B=R, Sub=1
  Result = 0 + NOT(R) + 1 = NOT(R) + 1 = -R  ✓
```

### Instruction-by-Instruction Control Signal Table

| Signal | MOVI R,d | ADD Ra,Rb | NEG R | JZR R,d |
|--------|----------|-----------|-------|---------|
| Reg_EN | R | Ra | R | "000" (no write) |
| Mux_A | "000" (R0) | Ra | "000" (R0) | R |
| Mux_B | "000" (R0) | Rb | R | "000" (R0) |
| Sub | 0 | 0 | 1 | 0 |
| LD | 1 | 0 | 0 | 1 |
| LSB | d (imm) | "0000" | "0000" | 0ddd (addr) |
| JMP | 0 | 0 | 0 | R==0 ? 1 : 0 |

---

## 5. Sub-Component Overview (High Level)

Each component plays a specific role in the processor. Here they are from top to bottom:

### SLOW_CLK — Clock Divider
**What it does:** Takes the 100 MHz board clock and divides it down to ~0.5 Hz (1 cycle every 2 seconds) so a human can watch instructions execute on the LEDs. In simulation mode the divider is set to 1 (no division) so tests finish quickly.

### ROM — Program Memory
**What it does:** Stores the program as 8 rows of 12-bit instruction words. Acts like a permanent lookup table — you give it a 3-bit address and it immediately outputs the 12-bit instruction stored there.

### PC — Program Counter
**What it does:** Remembers which instruction to execute next. Contains three D flip-flops to store a 3-bit address (0–7). On every clock edge it loads whatever address MuxC has selected (either PC+1 for sequential, or a jump target).

### ADDER_3 — PC Incrementer
**What it does:** Adds 1 to the current PC value to compute the address of the next instruction. Optimized to use only 5 gates instead of the 15 gates needed by a full 3-bit adder.

### INSTRUCTION_DEC — Instruction Decoder
**What it does:** The brain of the control path. Reads the 12-bit instruction from ROM and generates all the control signals that tell every other component what to do this cycle. Pure combinational logic — no clock needed.

### REG_BANK — Register File
**What it does:** Houses 8 registers (R0–R7), each 4 bits wide. R0 is hardwired to 0000. On each clock edge, the register selected by Reg_EN is updated with the new value. All 8 register outputs are always visible (broadcast bus).

### REG_4 — 4-Bit Register
**What it does:** A single 4-bit storage cell made from 4 D flip-flops with enable. The enable input (Sel) controls whether this register captures a new value on the clock edge. If Sel=0, the register holds its current value.

### D_FF / D_FFwithEN — D Flip-Flop
**What it does:** The fundamental 1-bit storage element. Captures input D on the rising clock edge. D_FFwithEN adds an enable input — only updates if EN=1. This is the lowest-level building block.

### MUX_8_to_1_4B — 8-to-1 Multiplexer (4-bit)
**What it does:** Selects one of 8 four-bit register values based on a 3-bit selector. Used twice (MuxA and MuxB) to route the correct register values to the ALU inputs.

### MUX_2_to_1_4B — 2-to-1 Multiplexer (4-bit)
**What it does:** Chooses between two 4-bit values. MuxD uses this to select between the ALU result (for ADD/NEG) and the immediate value from the instruction (for MOVI).

### MUX_2_to_1_3B — 2-to-1 Multiplexer (3-bit)
**What it does:** Chooses between two 3-bit values. MuxC uses this to select between PC+1 (next sequential instruction) and the jump target address from the instruction.

### ADD_SUB_4 — 4-Bit ALU (Adder/Subtractor)
**What it does:** Performs 4-bit addition or subtraction. When mode M=0, it adds A+B. When M=1, it computes A + NOT(B) + 1, which is subtraction / 2's complement negation. Also produces an overflow flag.

### FA — Full Adder
**What it does:** Adds three 1-bit values (A, B, carry-in) and produces a 1-bit sum and carry-out. Four of these chain together to form the 4-bit ALU.

### HA — Half Adder
**What it does:** Adds two 1-bit values and produces a sum and carry. Two of these combine to form one full adder.

### DEC_3_8 — 3-to-8 Decoder
**What it does:** Takes a 3-bit input and sets exactly one of 8 output lines high. Used to decode the register address into an individual enable signal for each register.

### DEC_2_4 — 2-to-4 Decoder
**What it does:** Takes a 2-bit input and sets exactly one of 4 output lines high. Two of these form the 3-to-8 decoder.

### LUT_7_SEG — 7-Segment Display Lookup
**What it does:** Converts a 4-bit hex value (0–F) into the 7-bit pattern needed to illuminate the correct segments on the 7-segment display on the Basys3 board.

---

## 6. Deep Dive Into Each Component

### 6.1 SLOW_CLK — How Clock Division Works

The Basys3 board runs at 100 MHz — 100 million clock cycles per second. At that speed, instructions execute so fast you can't see anything on the LEDs.

The solution: use a **counter-based clock divider**.

```
100 MHz clock:  ─┐┌─┐┌─┐┌─┐┌─┐┌─┐ ... (100 million per second)
                  └┘ └┘ └┘ └┘ └┘

Counter counts up on every 100 MHz tick.
When counter reaches 50,000,000 → toggle output, reset counter.

Slow clock:     ─────────────────────────────┐              ┌─
                                              └──────────────┘
                 ←── 0.5 seconds ────────────►←── 0.5 sec ──►
```

The slow clock output toggles between 0 and 1 every 50 million ticks, giving 1 complete cycle every 100 million ticks = 1 second period = 1 Hz (changed to 0.5 Hz depending on measurement). In simulation, the counter limit is set to 1 so tests don't take hours.

### 6.2 ROM — How Program Memory Works

```
Address (3-bit) →  ROM array  → Instruction (12-bit)
      000        →  row 0     → "100010000011"  (MOVI R1, 3)
      001        →  row 1     → "100100000001"  (MOVI R2, 1)
      010        →  row 2     → "010100000000"  (NEG R2)
      011        →  row 3     → "001110010000"  (ADD R7, R1)
      100        →  row 4     → "000010100000"  (ADD R1, R2)
      101        →  row 5     → "110010000111"  (JZR R1, 7)
      110        →  row 6     → "110000000011"  (JZR R0, 3)
      111        →  row 7     → "110000000111"  (JZR R0, 7)
```

The ROM is a **combinational lookup** — the address goes in, and the instruction comes out immediately with no clock needed (it's just wires through a big multiplexer under the hood).

The current program computes the sum 3 + 2 + 1 = 6 and accumulates it in R7. Let's trace what it does:
1. `MOVI R1, 3` → R1 = 3
2. `MOVI R2, 1` → R2 = 1
3. `NEG R2` → R2 = -1 (1111 in 4-bit 2's complement = 15 unsigned = -1 signed)
4. `ADD R7, R1` → R7 = R7 + R1 (accumulate R1 into R7)
5. `ADD R1, R2` → R1 = R1 + R2 = R1 - 1 (since R2 = -1)
6. `JZR R1, 7` → if R1==0, jump to address 7 (done), else continue
7. `JZR R0, 3` → R0 is always 0, so always jump back to address 3 (loop)
8. `JZR R0, 7` → R0 is always 0, so always jump to address 7 (infinite halt)

The effect: counts R1 down from 3 to 0, adding R1 to R7 each time. Final R7 = 3+2+1 = 6.

### 6.3 PC — Program Counter Internals

```
        ┌──────────────────────────────────┐
D[2:0] ─►  D_FF2  │  D_FF1  │  D_FF0     │ → Q[2:0]
        │  (bit2) │  (bit1) │  (bit0)    │
        │    Clk ─►─────────►─────────   │
        │    Clr ─►─────────►─────────   │
        └──────────────────────────────────┘
```

Three identical D flip-flops, one per address bit. On every rising clock edge:
- If Clr=1: all bits reset to 0 (processor restarts at instruction 0)
- If Clr=0: all bits load the value from D (the next PC value from MuxC)

### 6.4 ADDER_3 — Optimized +1 Incrementer

A naive 3-bit adder to compute `A + 001` would use three full adders = 15 gates. Since we always add 1 (constant), we can unroll the carry chain:

```
A + 001 carry chain:
  Bit 0: sum = A(0) XOR 1 = NOT A(0),  carry_0 = A(0) AND 1 = A(0)
  Bit 1: sum = A(1) XOR carry_0 = A(1) XOR A(0),  carry_1 = A(1) AND A(0)
  Bit 2: sum = A(2) XOR carry_1 = A(2) XOR (A(1) AND A(0)),  carry_2 = A(2) AND A(1) AND A(0)
```

This gives us the same result with just 5 gates (1 NOT + 1 XOR + 1 AND + 1 XOR + 2 ANDs = 5 gate operations), versus 15 gates for the general case.

### 6.5 INSTRUCTION_DEC — Control Signal Generation

The decoder reads bits 11 and 10 (the opcode) and generates all control signals:

```
Instruction word layout:
  [11][10][9][8][7][6][5][4][3][2][1][0]
   op1 op0  ─────Ra────  ─────Rb────  ──imm/addr──

Decoding bit 11 and 10:
  sig_move = NOT(10) AND  (11)  =  move instruction (MOVI)
  sig_and  = NOT(10) AND NOT(11) = add instruction (ADD)
  sig_neg  =     (10) AND NOT(11) = negate (NEG)
  sig_jump =     (10) AND     (11) = jump (JZR)

LD signal:
  LD = bit 11  (both MOVI and JZR have bit 11 = 1, so this is a direct wire)

Sub signal:
  Sub = sig_neg  (only NEG uses subtraction mode)

LSB (immediate/address data):
  If bit 11 = 1 (MOVI or JZR): LSB = bits[3:0]
  Otherwise: LSB = "0000"

Reg_EN (which register to write):
  For JZR: "000" (no write)
  For all others: bits[9:7]

Mux_A (which register feeds ALU input A):
  For ADD or JZR: bits[9:7] (read the specified register)
  For MOVI/NEG: "000" (read R0 = 0)

Mux_B (which register feeds ALU input B):
  For ADD: bits[6:4] (read the Rb register)
  For NEG: bits[9:7] (read the same R register, used as source for negation)
  Otherwise: "000"

JMP (should we jump?):
  JMP = sig_jump AND NOT(R[0] OR R[1] OR R[2] OR R[3])
  Translation: only jump if this is a JZR instruction AND the tested register is zero
```

### 6.6 REG_BANK — Register File Architecture

```
        I[2:0] ──► DEC_3_8 ──► Sel[7:0]
                              │
                    Sel[0] ─► │ (unused — R0 is hardwired to 0)
                    Sel[1] ─►[REG_4]──► R1
                    Sel[2] ─►[REG_4]──► R2
                    Sel[3] ─►[REG_4]──► R3
                    Sel[4] ─►[REG_4]──► R4
                    Sel[5] ─►[REG_4]──► R5
                    Sel[6] ─►[REG_4]──► R6
                    Sel[7] ─►[REG_4]──► R7
```

The 3-to-8 decoder converts the 3-bit register address into exactly one enable line. This means only one register gets its enable set high on any clock edge — exactly one register updates at a time. If I = "000", Sel[0] goes high, but R0 is hardwired to 0000 and ignores it.

### 6.7 ADD_SUB_4 — How the ALU Handles Both ADD and Subtract

The key insight: subtraction `A - B = A + (-B) = A + (NOT B) + 1`.

The mode bit M controls this:

```
When M=0 (ADD):
  B0x = B(0) XOR 0 = B(0)   (B unchanged)
  C_in of FA_0 = 0           (no extra carry)
  Result = A + B

When M=1 (SUB/NEG):
  B0x = B(0) XOR 1 = NOT B(0)   (B inverted)
  B1x = B(1) XOR 1 = NOT B(1)
  B2x = B(2) XOR 1 = NOT B(2)
  B3x = B(3) XOR 1 = NOT B(3)
  C_in of FA_0 = 1                 (+1)
  Result = A + NOT(B) + 1 = A - B
```

The overflow flag uses the standard signed overflow detection formula:
`Overflow = C_in_of_last_FA XOR C_out_of_last_FA`
= FA2_C XOR C_out

If the carry into and out of the MSB disagree, signed overflow occurred.

### 6.8 FA and HA — Building Blocks of the ALU

```
Half Adder:
  Input: A, B
  Sum:   A XOR B
  Carry: A AND B
  
  Truth table:
  A B | S  C
  0 0 | 0  0
  0 1 | 1  0
  1 0 | 1  0
  1 1 | 0  1

Full Adder (two half adders + OR):
  HA_0: A, B → HA0_S, HA0_C
  HA_1: HA0_S, C_in → HA1_S, HA1_C
  Sum:   HA1_S = A XOR B XOR C_in
  Carry: HA0_C OR HA1_C

Chain of 4 full adders:
  FA_0: A(0), B(0), C_in=M → S(0), carry to FA_1
  FA_1: A(1), B(1), C_in   → S(1), carry to FA_2
  FA_2: A(2), B(2), C_in   → S(2), carry to FA_3 (= FA2_C)
  FA_3: A(3), B(3), C_in   → S(3), C_out
  Overflow = FA2_C XOR C_out
```

### 6.9 DEC_3_8 — Built from Two DEC_2_4s

```
3-bit input I[2:0]:
  I[2] controls which DEC_2_4 is enabled:
    I[2]=0: EN0='1', EN1='0' → DEC_2_4_0 active → Y[3:0]
    I[2]=1: EN0='0', EN1='1' → DEC_2_4_1 active → Y[7:4]
  
  I[1:0] feeds both DEC_2_4s (selecting which output within the active group)

DEC_2_4 truth table (with EN=1):
  I[1:0] | Y[3] Y[2] Y[1] Y[0]
   00    |   0    0    0    1
   01    |   0    0    1    0
   10    |   0    1    0    0
   11    |   1    0    0    0
```

### 6.10 LUT_7_SEG — 7-Segment Display Encoding

The Basys3 board has a 4-digit 7-segment display. Each digit has 7 segments (a–g). A '0' bit turns the segment ON (active-low cathode).

```
    ─a─
  f│   │b
    ─g─
  e│   │c
    ─d─

Segment bit mapping: data[6:0] = {a, b, c, d, e, f, g}
  (check the board schematic — bit order may vary by pin assignment)

Examples:
  "0" → 1000000 (segments b,c,d,e,f,g off... wait: a=1=off, b=0=on...)
  
Actually the encoding in this ROM is:
  Address 0 → "1000000" → displays "0"
  Address 1 → "1111001" → displays "1"
  Address 7 → "1111000" → displays "7"
  Address 6 → "0000010" → displays "6"
```

---

## 7. Optimization Techniques

The goal of optimization in FPGA design is to reduce the number of **Look-Up Tables (LUTs)**, **flip-flops**, and **routing resources** used. On Artix-7, each LUT is a 6-input, 2-output truth-table cell. Fewer LUTs = lower power, faster timing, smaller footprint.

### 7.1 What Is an FPGA LUT?

On Xilinx Artix-7, a basic LUT6 can implement any Boolean function of 6 inputs in a single gate delay. Two LUT6s can form a LUT7 (using the MUXF7 primitive), and two LUT7s can form a LUT8 (using MUXF8). This hierarchy matters when optimizing multiplexers.

```
One LUT6 = any function of up to 6 inputs in 1 logic level delay

For a 4-bit 8-to-1 mux (32 inputs total):
  Naive approach:  decoder + AND-OR tree = many LUT levels
  Optimized:       with/select → Vivado uses MUXF7/MUXF8 primitives = 2 levels
```

### 7.2 MUX_8_to_1_4B — Multiplexer Optimization

**Before (naive approach):**
```vhdl
-- Instantiate DEC_3_8, then AND each register with each decoder output,
-- then OR all 8 together for each bit.
-- For 4 bits: 4 × (8 ANDs + 7 ORs) = 60 gate operations = ~8-10 LUTs
```

**After (optimized):**
```vhdl
with S select Q <=
    R0 when "000",
    R1 when "001",
    ...
    R7 when others;
-- Vivado maps this to MUXF7 primitives: ~4 LUTs, 2 levels of delay
```

**Why it works:** Vivado recognizes `with/select` on a fixed set of cases as a priority multiplexer and maps it to the dedicated `MUXF7`/`MUXF8` hardware within each slice. These primitives are not LUTs — they are dedicated routing multiplexers that add minimal delay.

### 7.3 MUX_2_to_1 — Eliminating Redundant Inversions

**Before (gate-level):**
```vhdl
-- For each bit i:
Q(i) <= (A(i) AND NOT S) OR (B(i) AND S);
-- Per bit: 1 NOT + 2 ANDs + 1 OR = 4 gates
-- For 4 bits: 4 × 4 = 16 gates, and NOT S is computed 4 times
```

**After (optimized):**
```vhdl
Q <= B when S = '1' else A;
-- Synthesiser uses the built-in FPGA MUX primitive in each LUT
-- NOT S is computed once internally; each bit maps to 1 LUT
```

**Savings:** Eliminates 3 repeated NOT-gate computations, reduces to the minimum gate depth.

### 7.4 ADDER_3 — Constant Folding

**Before (general 3-bit adder):**
```
3 full adders to compute A + B, where B can be anything
= 3 × 5 gates = 15 gates
```

**After (dedicated +1 incrementer):**
```
Since B is always 001, the carry chain simplifies:
  S(0) = NOT A(0)                 ← 1 gate (NOT)
  S(1) = A(1) XOR A(0)           ← 1 gate (XOR)
  S(2) = A(2) XOR (A(1) AND A(0))← 2 gates (AND + XOR)
  carry = A(2) AND A(1) AND A(0) ← 2 gates (AND + AND)
Total: 5 gates (down from 15)
```

This is called **constant folding** — when one input is a constant, the expression simplifies.

### 7.5 INSTRUCTION_DEC — Boolean Logic Optimization

**LD signal:**
- LD is 1 for both MOVI (opcode `10`) and JZR (opcode `11`) — both have bit 11 = 1
- **Optimization:** `LD <= Inst(11)` — a direct wire, zero gates
- **Before:** Would need `sig_move OR sig_jump` = 1 OR gate + 2 AND gates = 3 gates

**JMP signal (Zero flag computation):**
```vhdl
JMP <= sig_jump AND NOT(Reg(0) OR Reg(1) OR Reg(2) OR Reg(3));
```
- Using De Morgan's law: `NOT(R0 OR R1 OR R2 OR R3)` = NOR4
- On FPGA: NOR4 fits in a single LUT6 input
- **Before (naive):** `R0=0 AND R1=0 AND R2=0 AND R3=0` = 4 comparisons, 3 ANDs, then AND with sig_jump = 7 operations
- **After:** NOR4 then AND = 2 operations, mapped to 1-2 LUTs

**Reg_EN optimization:**
```vhdl
Reg_EN <= Inst(9 downto 7) when sig_jump = '0' else "000";
```
- **Before:** `sig_jump` would need to gate each of the 3 bits with separate AND gates
- **After:** Vivado maps the conditional directly to 3 MUX primitives — 3 LUTs instead of 3 ANDs + 1 NOT + 3 ANDs = 7 gates

### 7.6 Zero Flag — De Morgan's Law Application

```vhdl
Zero <= NOT (MuxD_Adder(0) OR MuxD_Adder(1) OR MuxD_Adder(2) OR MuxD_Adder(3));
```

**Why this is better than `NOT(bit0) AND NOT(bit1) AND NOT(bit2) AND NOT(bit3)`:**

```
Naive:  NOT(b0) AND NOT(b1) AND NOT(b2) AND NOT(b3)
        = 4 NOTs + 3 ANDs = 7 gates, 4 logic levels

De Morgan: NOT(b0 OR b1 OR b2 OR b3)
           = 3 ORs + 1 NOT = 4 gates, 2 logic levels

On FPGA:   NOR4 maps to a single LUT6 = 1 LUT, 1 level
```

### 7.7 D_FFwithEN — Removing Unused Outputs

The `D_FFwithEN` entity has a `Qbar` output port. In `REG_4`, only `Q` is connected — `Qbar` is never mapped.

**Before:** Synthesizer would generate a NOT gate on the Q output → `Qbar` for each flip-flop. With 7 registers × 4 bits = 28 flip-flops, that's 28 unnecessary NOT gates.

**After:** Since Qbar is unconnected, Vivado trims it during synthesis (dead code elimination). Zero extra gates.

*Note: The port still exists in the entity definition for API compatibility, but it is optimized away.*

### 7.8 REG_BANK — Decoder Architecture

The REG_BANK uses a DEC_3_8 (built from two DEC_2_4s) to generate enable signals. This is already efficient:

```
3-bit address → decoder → 8 one-hot enable lines → 7 registers

The decoder ensures exactly ONE register is written per cycle.
Without the decoder, you'd need 8 separate comparators (one per register).
```

The cascaded decoder (3→8 built from two 2→4) is optimal:
- 2 LUTs for the top-level AND/NOT logic
- 4 + 4 AND gates for the two 2→4 decoders
- Total: ~3-4 LUTs vs. ~8 LUTs for 8 separate 3-input comparators

### 7.9 Summary: Before vs. After Optimization

| Component | Original LUTs | Optimized LUTs | Technique |
|-----------|---------------|----------------|-----------|
| MUX_8_to_1_4B (×2) | ~10 each | ~4 each | `with/select` → MUXF7 |
| MUX_2_to_1_4B | ~6 | ~4 | Conditional assignment |
| MUX_2_to_1_3B | ~5 | ~3 | Conditional assignment |
| INSTRUCTION_DEC | ~12-14 | ~6-8 | Direct Boolean + wire |
| ADDER_3 | ~5 | ~2 | Constant folding |
| Zero flag | ~4 | ~1 | NOR4 (De Morgan) |
| D_FFwithEN Qbar | ~28 gates | 0 | Dead code elimination |
| **Total** | **~87 LUTs** | **~22-26 LUTs** | **~70% reduction** |

---

## 8. Line-by-Line VHDL Explanation

### 8.1 VHDL Primer — Key Concepts

Before reading the code, understand these VHDL fundamentals:

**Entity vs Architecture:** Every VHDL module has two parts:
- `entity` declares the module's ports (interface — what goes in and out)
- `architecture` describes the module's behavior (implementation — how it works)

**Concurrent vs Sequential:** Inside `architecture`:
- Concurrent statements (signal assignments outside processes): run simultaneously, like real hardware
- Sequential statements (inside `process`): execute in order, like software, but only within the process

**Signal assignment `<=`:** Does NOT execute immediately — schedules an update for after the current delta cycle. This models real hardware propagation delay.

**`std_logic`:** The standard 1-bit logic type. Can be: `'0'`, `'1'`, `'U'` (uninitialized), `'X'` (unknown), `'Z'` (high impedance), etc.

**`std_logic_vector`:** An array of `std_logic` bits. `(3 downto 0)` means 4 bits, index 3 is MSB.

**Component instantiation:** Like calling a function, but creates a permanent hardware module. Port maps connect the instantiated component's ports to local signals.

---

### 8.2 NANOPROCESSOR.vhd — Line by Line

```vhdl
library IEEE;                        -- Import the IEEE standard library
use IEEE.STD_LOGIC_1164.ALL;         -- Standard logic types (std_logic, std_logic_vector)
use IEEE.NUMERIC_STD.ALL;            -- Numeric operations (unsigned, to_integer)
```
These three lines appear in almost every VHDL file. `IEEE.STD_LOGIC_1164` defines `std_logic`. `IEEE.NUMERIC_STD` defines numeric conversion functions like `to_integer(unsigned(...))`.

```vhdl
entity NANOPROCESSOR is
    Port ( Clr : in STD_LOGIC;                    -- Active-high reset (center button on Basys3)
           Clk : in STD_LOGIC;                    -- 100 MHz board clock input
           R : out STD_LOGIC_VECTOR (3 downto 0); -- R7 register value → LEDs 0-3
           Overflow : out STD_LOGIC;              -- ALU signed overflow flag → LED14
           Zero : out STD_LOGIC;                  -- Zero flag (ALU result=0) → LED15
           Seven_Seg : out std_logic_vector (6 downto 0);  -- 7-segment cathodes
           an : out STD_LOGIC_VECTOR (3 downto 0));        -- 7-segment anode selects
end NANOPROCESSOR;
```
This is the top-level interface — everything visible to the outside world (the FPGA pins).

```vhdl
architecture Behavioral of NANOPROCESSOR is
```
Everything between here and `end Behavioral` defines the internal implementation.

```vhdl
    component SLOW_CLK is 
        Port (  Clk_in : in std_logic;
                Clk_out : out std_logic);
    end component;
```
A **component declaration** tells this architecture that a module named `SLOW_CLK` exists and what its ports are. This is like a function prototype in C — it describes the interface but not the implementation. You must declare every sub-module you want to instantiate.

```vhdl
    component MUX_8_1_4B is
        Port ( S : in STD_LOGIC_VECTOR;   -- 3-bit select (uses unconstrained vector)
               R0..R7 : in STD_LOGIC_VECTOR;   -- 8 × 4-bit inputs
               Q : out STD_LOGIC_VECTOR);      -- 4-bit output
    end component;
```
The `STD_LOGIC_VECTOR` without size constraints here means the size will be determined by the actual port connections at instantiation time (VHDL's "unconstrained array" feature).

```vhdl
    -- (similar component declarations for all other sub-modules)
    -- REG_BANK, INSTRUCTION_DEC, MUX_2_1_4B, MUX_2_1_3B, ROM,
    -- PC, ADDER_3, ADD_SUB_4, LUT_7_SEG
```

```vhdl
    signal PC_ROM, Add3_MuxC, PC_MuxC : std_logic_vector(2 downto 0);
```
Three 3-bit internal wires:
- `PC_ROM`: output of PC → address sent to ROM
- `Add3_MuxC`: PC+1 (output of ADDER_3) → input A of MuxC
- `PC_MuxC`: selected next PC value → input D of PC

```vhdl
    signal ROM_Decoder : std_logic_vector(11 downto 0);
```
12-bit wire: the raw instruction fetched from ROM, goes to INSTRUCTION_DEC.

```vhdl
    signal Decoder_MuxD : std_logic_vector(3 downto 0);    -- LSB / immediate value
    signal Decoder_MuxC, Decoder_MuxDSelc, Decoder_Adder : std_logic;
    -- Decoder_MuxC   = JMP signal (select jump vs sequential in MuxC)
    -- Decoder_MuxDSelc = LD signal (select ALU vs immediate in MuxD)
    -- Decoder_Adder  = Sub signal (ADD vs SUB mode)
```

```vhdl
    signal Decoder_RegBank, Decoder_MuxA, Decoder_MuxB : std_logic_vector(2 downto 0);
    -- Decoder_RegBank = Reg_EN: 3-bit register address to write
    -- Decoder_MuxA    = 3-bit select for which register feeds ALU port A
    -- Decoder_MuxB    = 3-bit select for which register feeds ALU port B
```

```vhdl
    signal MuxD_Adder, MuxD_RegBank : std_logic_vector(3 downto 0);
    -- MuxD_Adder  = 4-bit ALU result (from ADD_SUB_4)
    -- MuxD_RegBank = 4-bit value to write into register bank (from MuxD)
```

```vhdl
    signal R0,R1,R2,R3,R4,R5,R6,R7 : std_logic_vector(3 downto 0);
```
The 8 register values, always visible as signals. These are the outputs of REG_BANK and the inputs to MuxA and MuxB.

```vhdl
    signal MuxA_Adder, MuxB_Adder : std_logic_vector(3 downto 0);
    -- MuxA_Adder = output of MuxA → ALU input A (also fed back to INSTRUCTION_DEC as Reg)
    -- MuxB_Adder = output of MuxB → ALU input B
    signal Slw_Clk : std_logic;      -- Divided clock from SLOW_CLK
    signal Adder_Cout : std_logic;   -- Carry-out from ADDER_3 (unused but required by port)
```

```vhdl
begin
```
Everything after `begin` and before `end Behavioral` is the concurrent code. All of these instantiations and assignments exist simultaneously as hardware.

```vhdl
    LUT : LUT_7_SEG
        Port map(
            address => R7,          -- Feed R7 register value into 7-seg lookup
            data => Seven_Seg);     -- Result goes to the 7-seg cathode pins
```
This instantiates the 7-segment lookup table. R7's value (0–15) is looked up and the corresponding 7-bit segment pattern drives the display.

```vhdl
    Slow_Clk_0 : Slow_Clk
        Port map(
            Clk_in => Clk,          -- 100 MHz board clock
            Clk_out => Slw_Clk);    -- Divided slow clock for rest of system
```

```vhdl
    Adder : ADD_SUB_4
        Port map(
            A => MuxA_Adder,        -- Operand A: selected register value
            B => MuxB_Adder,        -- Operand B: selected register value
            M => Decoder_Adder,     -- Mode: 0=ADD, 1=SUB/NEG
            overflow => overflow,   -- Signed overflow flag → direct to output port
            S => MuxD_Adder);       -- 4-bit result
```

```vhdl
    MuxA : MUX_8_1_4B
        Port map (
            R0 => R0, R1 => R1, ...  R7 => R7,   -- All 8 register values as inputs
            S => Decoder_MuxA,                     -- 3-bit select from decoder
            Q => MuxA_Adder);                      -- Selected register value to ALU
    MuxB : MUX_8_1_4B
        Port map ( ... S => Decoder_MuxB, Q => MuxB_Adder);   -- Same for ALU port B
```

```vhdl
    Register_Bank_0 : REG_BANK
        Port map (
            D => MuxD_RegBank,      -- Data to write (from MuxD output)
            Clk => Slw_Clk,         -- Slow clock: register writes happen here
            I => Decoder_RegBank,   -- Which register to write (3-bit address)
            Clr => Clr,             -- Synchronous reset
            R0 => R0, R1 => R1, ... R7 => R7);   -- All outputs always available
```

```vhdl
    MuxC : MUX_2_1_3B
        Port map (
            A => Add3_MuxC,              -- Input A: PC+1 (sequential next address)
            B => Decoder_MuxD(2 downto 0),   -- Input B: jump target (lower 3 bits of LSB)
            S => Decoder_MuxC,           -- Select: JMP signal (0=sequential, 1=jump)
            Q => PC_MuxC);               -- Output: next PC value
```
Note: `Decoder_MuxD(2 downto 0)` takes only the lower 3 bits of the 4-bit LSB field — because PC addresses are 3-bit (0–7).

```vhdl
    Adder_3bit_0 : ADDER_3
        Port map (
            A => PC_ROM,            -- Current PC value (3-bit)
            Carry => Adder_Cout,    -- Carry out (not used, but port must be connected)
            S => Add3_MuxC);        -- PC+1 result
```

```vhdl
    Instruction_Decoder_0 : INSTRUCTION_DEC
        Port map (
            Inst => ROM_Decoder,         -- Full 12-bit instruction from ROM
            Reg => MuxA_Adder,           -- Value of register being tested (for JZR zero check)
            LSB => Decoder_MuxD,         -- 4-bit immediate/address field
            Reg_EN => Decoder_RegBank,   -- Register to write
            Mux_A => Decoder_MuxA,       -- ALU A register select
            Mux_B => Decoder_MuxB,       -- ALU B register select
            LD => Decoder_MuxDSelc,      -- Load immediate vs ALU result
            Sub => Decoder_Adder,        -- ADD vs SUB mode
            JMP => Decoder_MuxC);        -- Jump condition met
```
Note: `Reg => MuxA_Adder` — this is the value of the register being tested (for JZR). The instruction decoder uses the Mux_A select to point MuxA to the register being tested, then the output of MuxA (`MuxA_Adder`) comes back to the decoder so it can check if it's zero.

```vhdl
    MuxD : MUX_2_1_4B
        Port map (
            A => MuxD_Adder,         -- Input A: ALU result (for ADD/NEG)
            B => Decoder_MuxD,       -- Input B: immediate value (for MOVI)
            S => Decoder_MuxDSelc,   -- Select: LD signal (0=ALU, 1=immediate)
            Q => MuxD_RegBank);      -- Output: value to write to register
```

```vhdl
    Program_Counter_0 : PC
        Port map ( 
            D => PC_MuxC,     -- Next PC value (from MuxC)
            Clr => Clr,       -- Reset to 0
            Clk => Slw_Clk,   -- Slow clock (updates on rising edge)
            Q => PC_ROM);     -- Current PC value (drives ROM address)
```

```vhdl
    ROM_0 : ROM
        Port map (
            S => PC_ROM,        -- Address: current PC value
            Q => ROM_Decoder);  -- Output: 12-bit instruction
```

```vhdl
    R <= R7;
```
Direct wire: the `R` output port (connected to LEDs 0–3) always shows the current value of register R7.

```vhdl
    Zero <= NOT (MuxD_Adder(0) OR MuxD_Adder(1) OR MuxD_Adder(2) OR MuxD_Adder(3));
```
Zero flag: NOR of all 4 bits of the ALU result. High when all bits are zero. Note: this is the **ALU result**, not the register writeback — so for MOVI and JZR (where LD=1), the zero flag still reflects what the ALU computed (which may be 0+0=0 since R0 is used as both inputs for those cases).

```vhdl
    an <= "1110";
```
Active-low anode control: "1110" enables only digit 0 (rightmost). The other three digits (AN3, AN2, AN1) have anodes set high (off). AN0 is set low (on), showing the 7-segment digit.

---

### 8.3 SLOW_CLK.vhd — Line by Line

```vhdl
entity SLOW_CLK is
    Port ( Clk_in : in STD_LOGIC;    -- Fast clock input (100 MHz from board)
           Clk_out : out STD_LOGIC); -- Divided slow clock output
end SLOW_CLK;

architecture Behavioral of SLOW_CLK is
    signal count: integer := 1;           -- Counter, initialized to 1
    signal clk_status : std_logic := '0'; -- Current slow clock state, starts low
begin
    process (Clk_in) begin                -- Sensitivity list: runs when Clk_in changes
        if (rising_edge (Clk_in)) then    -- Only act on rising edges of the fast clock
            count <= count + 1;           -- Increment counter every fast clock tick
--          if (count = 50000000) then    -- For real board: toggle every 50M ticks (0.5s)
            if (count = 1) then           -- For simulation: toggle every 1 tick
                clk_status <= not clk_status;  -- Toggle the slow clock state
                Clk_out <= clk_status;         -- Drive the output (one delta behind)
                count <= 1;                    -- Reset counter to 1
            end if;
        end if;
    end process;
end Behavioral;
```

**Important subtlety:** `Clk_out <= clk_status` assigns the OLD value of `clk_status` (before `not clk_status` takes effect), because in VHDL, signal assignments inside a process don't update until the process finishes. This creates a one-delta-cycle delay. On real hardware this doesn't matter because both signal updates are instantaneous.

---

### 8.4 ROM.vhd — Line by Line

```vhdl
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;          -- Needed for to_integer() and unsigned()

entity ROM is
    Port ( S : in STD_LOGIC_VECTOR (2 downto 0);    -- 3-bit address (0-7)
           Q : out STD_LOGIC_VECTOR (11 downto 0)); -- 12-bit instruction output
end ROM;

architecture Behavioral of ROM is
    type rom_type is array (0 to 7) of std_logic_vector(12-1 downto 0);
    -- Defines a new type: an array of 8 elements, each element is a 12-bit vector
    
    signal ROM : rom_type := (        -- Declare signal of that type and initialize it
        "100010000011",  -- addr 0: MOVI R1, 3
        "100100000001",  -- addr 1: MOVI R2, 1
        "010100000000",  -- addr 2: NEG R2
        "001110010000",  -- addr 3: ADD R7, R1
        "000010100000",  -- addr 4: ADD R1, R2
        "110010000111",  -- addr 5: JZR R1, 7
        "110000000011",  -- addr 6: JZR R0, 3
        "110000000111"   -- addr 7: JZR R0, 7
    );
begin
    Q <= ROM(to_integer(unsigned(S)));
    -- to_integer(unsigned(S)): convert the 3-bit std_logic_vector to an integer index
    -- ROM(...): index into the array with that integer
    -- Result drives Q combinationally (no clock = immediate output)
end Behavioral;
```

---

### 8.5 PC.vhd — Line by Line

```vhdl
entity PC is
     Port ( D : in STD_LOGIC_VECTOR (2 downto 0);   -- Next PC value input (3-bit)
            Clr : in STD_LOGIC;                      -- Synchronous reset
            Clk : in STD_LOGIC;                      -- Clock
            Q : out STD_LOGIC_VECTOR (2 downto 0));  -- Current PC value output
end PC;

architecture Behavioral of PC is
    component D_FF                -- Declare the D flip-flop component we'll use
        port ( 
           D : in STD_LOGIC;
           Res : in STD_LOGIC;
           Clk : in STD_LOGIC;
           Q : out STD_LOGIC);
    end component;
begin
    D_FF0 : D_FF          -- Instantiate flip-flop for bit 0 of PC
        port map ( 
        D => D(0),         -- Input: bit 0 of next PC
        Q => Q(0),         -- Output: bit 0 of current PC
        Res => Clr,        -- Reset: connected to global clear
        Clk => Clk);       -- Clock: slow clock
    
    D_FF1 : D_FF port map (D => D(1), Q => Q(1), Res => Clr, Clk => Clk);
    D_FF2 : D_FF port map (D => D(2), Q => Q(2), Res => Clr, Clk => Clk);
    -- Three identical flip-flops, one per address bit
    -- All share the same clock and reset
end Behavioral;
```

---

### 8.6 INSTRUCTION_Dec.vhd — Line by Line

```vhdl
entity INSTRUCTION_DEC is
    Port ( Inst : in STD_LOGIC_VECTOR (11 downto 0);  -- Full 12-bit instruction
           Reg : in STD_LOGIC_VECTOR (3 downto 0);    -- Value of MuxA register (for JZR)
           LSB : out STD_LOGIC_VECTOR (3 downto 0);   -- 4-bit immediate/address
           Reg_EN : out STD_LOGIC_VECTOR (2 downto 0);-- Which register to write
           Mux_A : out STD_LOGIC_VECTOR (2 downto 0); -- Which register → ALU A
           LD : out STD_LOGIC;                        -- 1=use immediate, 0=use ALU
           Mux_B : out STD_LOGIC_VECTOR (2 downto 0); -- Which register → ALU B
           Sub : out STD_LOGIC;                       -- 1=subtract, 0=add
           JMP : out STD_LOGIC);                      -- 1=take jump
end INSTRUCTION_DEC;

architecture Behavioral of INSTRUCTION_DEC is
    signal sig_move, sig_and, sig_neg, sig_jump : std_logic;
    -- Internal signals for each decoded instruction type
begin
    -- Decode opcode from bits 11 and 10
    sig_move <= (NOT Inst(10)) AND      Inst(11);  -- MOVI: 10
    sig_and  <= (NOT Inst(10)) AND (NOT Inst(11)); -- ADD:  00
    sig_neg  <=      Inst(10)  AND (NOT Inst(11)); -- NEG:  01
    sig_jump <=      Inst(10)  AND      Inst(11);  -- JZR:  11
    -- These four signals are mutually exclusive: exactly one is '1' per instruction

    LD <= Inst(11);
    -- LD is '1' for MOVI (bit11=1) and JZR (bit11=1), '0' for ADD and NEG
    -- This is a direct wire — no logic gates at all, just a connection

    Sub <= sig_neg;
    -- Only NEG uses subtraction mode in the ALU. Direct wire.

    LSB <= Inst(3 downto 0) when Inst(11) = '1' else "0000";
    -- For MOVI: bits[3:0] = 4-bit immediate value
    -- For JZR:  bits[3:0] = 0ddd (lower 3 are jump address)
    -- For ADD/NEG: force to 0 (not needed but cleaner)

    Reg_EN <= Inst(9 downto 7) when sig_jump = '0' else "000";
    -- For ADD/NEG/MOVI: write to register specified in bits[9:7]
    -- For JZR: "000" disables all writes (no register is modified)

    Mux_A <= Inst(9 downto 7) when (sig_and = '1' or sig_jump = '1') else "000";
    -- For ADD: read Ra from register bank (Ra is in bits[9:7])
    -- For JZR: read the tested register (also in bits[9:7]) — to check if it's zero
    -- For MOVI/NEG: select R0 (always 0) as ALU input A

    Mux_B <= Inst(6 downto 4) when sig_and  = '1' else  -- ADD: read Rb from bits[6:4]
             Inst(9 downto 7) when sig_neg  = '1' else  -- NEG: read same R as source
             "000";                                      -- MOVI/JZR: select R0
    -- For NEG: both Mux_A (via "000"→R0=0) and Mux_B (→R) selected correctly:
    -- ALU computes 0 + NOT(R) + 1 = -R

    JMP <= sig_jump AND NOT(Reg(0) OR Reg(1) OR Reg(2) OR Reg(3));
    -- JMP is '1' only when:
    --   1. This is a JZR instruction (sig_jump='1')   AND
    --   2. The tested register equals zero (all bits zero → NOR = '1')
    -- Reg is the value output of MuxA, which points to the tested register
end Behavioral;
```

---

### 8.7 REG_BANK.vhd — Line by Line

```vhdl
entity REG_BANK is
    Port ( D : in STD_LOGIC_VECTOR (3 downto 0);  -- 4-bit data to write
           Clk : in STD_LOGIC;                    -- Clock
           I : in STD_LOGIC_VECTOR (2 downto 0);  -- 3-bit register address to write
           Clr : in STD_LOGIC;                    -- Reset
           R0..R7 : out STD_LOGIC_VECTOR (3 downto 0)); -- All 8 register outputs
end REG_BANK;

architecture Behavioral of REG_BANK is
    component REG_4   ... end component;   -- 4-bit register with enable
    component DEC_3_8 ... end component;   -- 3-to-8 decoder
    
    signal Sel : std_logic_vector (7 downto 0);   -- One-hot enable for each register
begin
    Decoder_3_to_8_0 : DEC_3_8
        port map(
            I => I,     -- 3-bit register address input
            EN => '1',  -- Always enabled (literal '1' constant)
            Y => Sel);  -- 8-bit one-hot output
    
    R0 <= "0000";  -- R0 is hardwired: always outputs 0, never stores anything
    
    Register_1 : REG_4
        port map(
            Clk => Clk,
            Val => D,          -- All registers receive the same data bus
            Sel => Sel(1),     -- But only the selected one has Sel='1' (enable)
            Clr => Clr,
            Reg_out => R1);
    -- Registers 2-7 follow the same pattern, with Sel(2) through Sel(7)
end Behavioral;
```

**The broadcast bus pattern:** All 7 real registers (R1–R7) see the same `D` input. The decoder ensures only one of them has `Sel='1'` at a time, so only that one latches D on the clock edge. The others hold their previous value.

---

### 8.8 REG_4.vhd — Line by Line

```vhdl
entity REG_4 is
    Port ( Clk : in STD_LOGIC;
           Val : in STD_LOGIC_VECTOR (3 downto 0);   -- 4-bit value to potentially store
           Sel : in STD_LOGIC;                        -- Enable: 1=store Val, 0=hold
           Clr : in STD_LOGIC;
           Reg_out : out STD_LOGIC_VECTOR (3 downto 0));  -- Current stored value
end REG_4;

architecture Behavioral of REG_4 is
    component D_FFwithEN ... end component;
    signal Activate : std_logic;    -- Declared but unused (synthesis dead code)
begin
    D_FF_0 : D_FFwithEN
        port map(
            D => Val(0),       -- Bit 0 of input data
            Res => Clr,        -- Reset
            Clk => Clk,
            EN => Sel,         -- Enable: 1=latch, 0=hold
            Q => Reg_out(0));  -- Bit 0 of stored value (Qbar not connected → optimized away)
    -- D_FF_1, D_FF_2, D_FF_3 handle bits 1, 2, 3 identically
end Behavioral;
```

---

### 8.9 D_FF.vhd — Line by Line

```vhdl
entity D_FF is
    Port ( D    : in  STD_LOGIC;   -- Data input: captured on rising clock edge
           Res  : in  STD_LOGIC;   -- Synchronous reset (active high)
           Clk  : in  STD_LOGIC;   -- Clock input
           Q    : out STD_LOGIC;   -- Stored value output
           Qbar : out STD_LOGIC);  -- Complement of Q (used in PC, not in REG_4)
end D_FF;

architecture Behavioral of D_FF is
begin
    process (Clk)          -- Sensitive to clock changes only (synchronous design)
    begin
        if rising_edge(Clk) then    -- Only act on 0→1 transitions
            if Res = '1' then        -- Reset has priority
                Q    <= '0';
                Qbar <= '1';
            else
                Q    <= D;           -- Normal operation: capture D
                Qbar <= not D;
            end if;
        end if;
    end process;
end Behavioral;
```

**Why `rising_edge(Clk)` and not `Clk'event and Clk='1'`?** Both work, but `rising_edge()` is the modern, preferred form — it handles metastability edge cases correctly for non-standard `std_logic` values like 'X' and 'U'.

---

### 8.10 D_FFwithEN.vhd — Line by Line

```vhdl
architecture Behavioral of D_FFwithEN is
begin
    process (Clk) begin
        if (rising_edge(Clk)) then
            if Res = '1' then            -- Reset has highest priority
                Q <= '0';
                Qbar <= '1';
            else
                if EN = '1' then         -- Only update if enabled
                    Q <= D;
                    Qbar <= not D;
                end if;
                -- If EN='0': no assignment → signal retains previous value
                -- This is how VHDL models a flip-flop with enable (clock-enable)
            end if;
        end if;
    end process;
end Behavioral;
```

The nested `if EN = '1'` is the key: if it's not entered, no assignment happens, so Q keeps its old value. On FPGA, this synthesizes to a flip-flop with a dedicated CE (Clock Enable) pin — zero extra LUTs, zero extra routing.

---

### 8.11 ADD_SUB_4.vhd — Line by Line

```vhdl
entity ADD_SUB_4 is
    Port ( A : in STD_LOGIC_VECTOR (3 downto 0);   -- 4-bit operand A
           B : in STD_LOGIC_VECTOR (3 downto 0);   -- 4-bit operand B
           S : out STD_LOGIC_VECTOR (3 downto 0);  -- 4-bit result
           M : in STD_LOGIC;                       -- Mode: 0=ADD, 1=SUB
           overflow : out STD_LOGIC);              -- Signed overflow flag
end ADD_SUB_4;

architecture Behavioral of ADD_SUB_4 is
    component FA ... end component;
    
    SIGNAL FA0_S, FA0_C, FA1_S, FA1_C, FA2_S, FA2_C, FA3_S, FA3_C, C_out : std_logic;
    -- Intermediate carry signals between the chained full adders
    Signal B0x, B1x, B2x, B3x : std_logic;
    -- B bits after optional inversion by M
begin
    B0x <= B(0) XOR M;   -- If M=0: B0x = B(0) unchanged. If M=1: B0x = NOT B(0)
    B1x <= B(1) XOR M;   -- Same for all 4 bits of B
    B2x <= B(2) XOR M;
    B3x <= B(3) XOR M;
    -- XOR with 1 inverts; XOR with 0 passes through. Elegant.

    FA_0 : FA port map (
        A => A(0),    -- Bit 0 of operand A
        B => B0x,     -- Bit 0 of B (possibly inverted)
        C_in => M,    -- Initial carry = M: adds +1 for subtraction (completing 2's complement)
        S => S(0),    -- Bit 0 of result
        C_Out => FA0_C);  -- Carry to next stage

    FA_1 : FA port map (A => A(1), B => B1x, C_in => FA0_C, S => S(1), C_Out => FA1_C);
    FA_2 : FA port map (A => A(2), B => B2x, C_in => FA1_C, S => S(2), C_Out => FA2_C);
    FA_3 : FA port map (A => A(3), B => B3x, C_in => FA2_C, S => S(3), C_Out => C_out);

    overflow <= FA2_C xor C_out;
    -- Signed overflow: the carry INTO the MSB differs from carry OUT of the MSB
    -- This detects when the signed result doesn't fit in 4 bits
    -- Example: 0111 (7) + 0001 (1) = 1000 (-8 signed) → overflow=1
end Behavioral;
```

---

### 8.12 ADDER_3.vhd — Line by Line

```vhdl
architecture Behavioral of ADDER_3 is
begin
    S(0)  <= NOT A(0);                   
    -- Adding 1 to any number: bit 0 always flips (1+0=1, 0+1=1, both → flip)
    -- Half-adder with B=1: sum = A XOR 1 = NOT A
    
    S(1)  <= A(1) XOR A(0);             
    -- Bit 1 = A(1) XOR carry_from_bit0
    -- carry_from_bit0 = A(0) AND 1 = A(0)
    -- So S(1) = A(1) XOR A(0)
    
    S(2)  <= A(2) XOR (A(1) AND A(0));  
    -- Bit 2 = A(2) XOR carry_from_bit1
    -- carry_from_bit1 = A(1) AND carry_from_bit0 = A(1) AND A(0)
    -- So S(2) = A(2) XOR (A(1) AND A(0))
    
    carry <= A(2) AND A(1) AND A(0);    
    -- Carry out: only when ALL bits were '1' (i.e., 111+1=1000, carry=1)
    -- Not used in this design but included for completeness
end Behavioral;
```

---

### 8.13 FA.vhd and HA.vhd — Line by Line

```vhdl
-- HA: Half Adder
architecture Behavioral of HA is
begin
    C <= A AND B;    -- Carry: both inputs are 1
    S <= A XOR B;    -- Sum: inputs differ
end Behavioral;

-- FA: Full Adder (two half adders)
architecture Behavioral of FA is
    SIGNAL HA0_S, HA0_C, HA1_S, HA1_C : std_logic;
begin
    HA_0 : HA port map (A => A, B => B, S => HA0_S, C => HA0_C);
    -- First HA: adds A and B
    -- HA0_S = A XOR B (partial sum)
    -- HA0_C = A AND B (carry if both inputs are 1)
    
    HA_1 : HA port map (A => HA0_S, B => C_in, S => HA1_S, C => HA1_C);
    -- Second HA: adds partial sum with carry-in
    -- HA1_S = (A XOR B) XOR C_in = final sum bit
    -- HA1_C = (A XOR B) AND C_in (carry from second stage)
    
    S <= HA1_S;               -- Final sum = A XOR B XOR C_in
    C_out <= HA0_C OR HA1_C;  -- Final carry = (A AND B) OR ((A XOR B) AND C_in)
    -- The OR here: carry is produced if EITHER:
    --   both A and B were 1 (HA0_C)
    --   OR A XOR B was 1 AND C_in was 1 (HA1_C)
end Behavioral;
```

---

### 8.14 MUX_8_to_1_4B.vhd — Line by Line

```vhdl
architecture Behavioral of MUX_8_1_4B is
begin
    with S select Q <=    -- VHDL selected signal assignment
        R0 when "000",    -- When S=0, output R0
        R1 when "001",    -- When S=1, output R1
        R2 when "010",
        R3 when "011",
        R4 when "100",
        R5 when "101",
        R6 when "110",
        R7 when others;   -- "others" = "111" = R7 (default case, covers metavalues too)
end Behavioral;
```

The `with/select` construct covers all possible values of S (the `others` clause handles `"111"` and any simulation-only values like `'U'`). This is more robust than if/else chains which can leave undefined cases.

---

### 8.15 MUX_2_to_1_4B.vhd and MUX_2_to_1_3B.vhd — Line by Line

```vhdl
-- MUX_2_to_1_4B
architecture Behavioral of MUX_2_1_4B is
begin
    Q <= B when S = '1' else A;
    -- Conditional signal assignment:
    -- If S is '1': Q = B
    -- Otherwise (S='0' or any other value): Q = A
    -- Each bit of Q independently: Q(i) = B(i) if S else A(i)
end Behavioral;

-- MUX_2_to_1_3B is identical but for 3-bit vectors
```

This single line replaces the 16-gate implementation you'd write if building from individual AND/OR/NOT gates. The synthesizer infers a MUX primitive directly.

---

### 8.16 DEC_3_8.vhd and DEC_2_4.vhd — Line by Line

```vhdl
-- DEC_2_4: 2-to-4 decoder
architecture Behavioral of DEC_2_4 is
begin
    Y(0) <= (not I(0)) and (not I(1)) and EN;  -- 00: both bits are 0
    Y(1) <=       I(0) and (not I(1)) and EN;  -- 01: only bit 0 is 1
    Y(2) <= (not I(0)) and       I(1) and EN;  -- 10: only bit 1 is 1
    Y(3) <=       I(0) and       I(1) and EN;  -- 11: both bits are 1
    -- EN gates all outputs: when EN=0, all outputs are 0
    -- Exactly one output is '1' when EN='1'
end Behavioral;

-- DEC_3_8: uses two DEC_2_4s
architecture Behavioral of DEC_3_8 is
    signal I0, I1 : std_logic_vector(1 downto 0);  -- Lower 2 bits fed to both decoders
    signal Y0, Y1 : std_logic_vector(3 downto 0);  -- Each sub-decoder's output
    signal EN0, EN1 : std_logic;
begin
    EN0 <= not(I(2)) and EN;   -- EN0='1' when bit 2 is 0 and top-level EN is 1
    EN1 <=     I(2)  and EN;   -- EN1='1' when bit 2 is 1 and top-level EN is 1
    I0 <= I(1 downto 0);       -- Both sub-decoders see the same lower 2 bits
    I1 <= I(1 downto 0);
    
    Decoder_2_to_4_0: DEC_2_4 port map(I => I0, EN => EN0, Y => Y0);
    -- When I(2)=0: this decoder is enabled, handles addresses 0-3
    
    Decoder_2_to_4_1: DEC_2_4 port map(I => I1, EN => EN1, Y => Y1);
    -- When I(2)=1: this decoder is enabled, handles addresses 4-7
    
    Y(3 downto 0) <= Y0;   -- Lower half of output from first decoder
    Y(7 downto 4) <= Y1;   -- Upper half from second decoder
end Behavioral;
```

---

### 8.17 LUT_7_SEG.vhd — Line by Line

```vhdl
architecture Behavioral of LUT_7_SEG is
    type rom_type is array (0 to 15) of std_logic_vector(6 downto 0);
    -- Array type: 16 entries (for hex digits 0–F), each 7 bits wide
    
    signal sevenSegment_ROM : rom_type := (
        "1000000",  -- 0: segments a,b,c,d,e,f on, g off (0 shape)
        "1111001",  -- 1: only segments b,c on
        "0100100",  -- 2: a,b,d,e,g on
        "0110000",  -- 3: a,b,c,d,g on
        "0011001",  -- 4: b,c,f,g on
        "0010010",  -- 5: a,c,d,f,g on
        "0000010",  -- 6: a,c,d,e,f,g on
        "1111000",  -- 7: a,b,c on
        "0000000",  -- 8: all segments on
        "0010000",  -- 9: a,b,c,d,f,g on
        "0001000",  -- a: a,b,c,e,f,g on
        "0000011",  -- b: c,d,e,f,g on
        "1000110",  -- c: a,d,e,f on
        "0100001",  -- d: b,c,d,e,g on
        "0000110",  -- e: a,d,e,f,g on
        "0001110"   -- f: a,e,f,g on
    );
    -- Bit encoding: 0=segment ON (active-low cathode), 1=segment OFF
begin
    data <= sevenSegment_ROM(to_integer(unsigned(address)));
    -- Convert 4-bit address to integer, look up the 7-bit pattern
    -- This is purely combinational (like the ROM)
end Behavioral;
```

---

## 9. Constraint File (XDC) Explained

The `.xdc` file (Xilinx Design Constraints) tells Vivado which FPGA pin to connect each VHDL port to, and what electrical standard to use.

```tcl
set_property -dict { PACKAGE_PIN W5  IOSTANDARD LVCMOS33 } [get_ports Clk]
-- Connect the 'Clk' port in VHDL to physical pin W5 on the chip
-- LVCMOS33 = Low-Voltage CMOS 3.3V standard (Basys3 runs at 3.3V)

create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports Clk]
-- Tell the timing analyzer: this clock has period 10 ns (= 100 MHz)
-- Waveform: rises at 0 ns, falls at 5 ns (50% duty cycle)

set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports Clr]
-- Center push button → Reset signal

set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports {R[0]}]
-- LED 0 → bit 0 of R7 register output

set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports Overflow]
-- LED 14 → Overflow flag

set_property -dict { PACKAGE_PIN L1  IOSTANDARD LVCMOS33 } [get_ports Zero]
-- LED 15 → Zero flag

set_property -dict { PACKAGE_PIN W7  IOSTANDARD LVCMOS33 } [get_ports {Seven_Seg[0]}]
-- 7-segment cathode pin a → Seven_Seg bit 0

set_property -dict { PACKAGE_PIN U2  IOSTANDARD LVCMOS33 } [get_ports {an[0]}]
-- 7-segment anode 0 (rightmost digit enable, active-low)

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
-- Configuration voltage settings required by Artix-7 for correct startup
```

### Basys3 Physical Layout

```
┌─────────────────────────────────────────────────────┐
│  BASYS 3 BOARD                                      │
│                                                     │
│  [7-SEG DISPLAY]  ← R7 value shown as hex digit    │
│  [ _ _ _ 7 ]      ← only rightmost digit enabled   │
│                                                     │
│  [LED15][LED14]   ← Zero | Overflow flags           │
│  [LED3][LED2][LED1][LED0]  ← R7[3:0]              │
│                                                     │
│         [BTN_CENTER]  ← Reset (Clr)                │
│                                                     │
│  W5 ← 100MHz crystal oscillator (bottom left)      │
└─────────────────────────────────────────────────────┘
```

---

## 10. Example Program Walkthrough

The ROM contains a program that sums the numbers from 3 down to 1: **3 + 2 + 1 = 6**.

### Cycle-by-Cycle Trace

| Cycle | PC | Instruction | Operation | R1 | R2 | R7 |
|-------|----|---------|-----------|----|----|----|
| 0 | 0 | MOVI R1, 3 | R1 ← 3 | **3** | ? | 0 |
| 1 | 1 | MOVI R2, 1 | R2 ← 1 | 3 | **1** | 0 |
| 2 | 2 | NEG R2 | R2 ← -R2 = -1 = 1111 | 3 | **F(−1)** | 0 |
| 3 | 3 | ADD R7, R1 | R7 ← R7+R1 = 0+3 | 3 | F | **3** |
| 4 | 4 | ADD R1, R2 | R1 ← R1+R2 = 3+(−1) | **2** | F | 3 |
| 5 | 5 | JZR R1, 7 | R1≠0, PC←6 | 2 | F | 3 |
| 6 | 6 | JZR R0, 3 | R0=0, jump to 3 | 2 | F | 3 |
| 7 | 3 | ADD R7, R1 | R7 ← R7+R1 = 3+2 | 2 | F | **5** |
| 8 | 4 | ADD R1, R2 | R1 ← 2+(−1) | **1** | F | 5 |
| 9 | 5 | JZR R1, 7 | R1≠0, PC←6 | 1 | F | 5 |
| 10 | 6 | JZR R0, 3 | R0=0, jump to 3 | 1 | F | 5 |
| 11 | 3 | ADD R7, R1 | R7 ← 5+1 | 1 | F | **6** |
| 12 | 4 | ADD R1, R2 | R1 ← 1+(−1) | **0** | F | 6 |
| 13 | 5 | JZR R1, 7 | R1=0! Jump to 7 | 0 | F | 6 |
| 14 | 7 | JZR R0, 7 | R0=0, jump to 7 (forever) | 0 | F | **6** |

**Final result:** R7 = 6 = `0110` binary = displayed as "6" on the 7-segment display and on LEDs 1 and 2.

### Signal State at Cycle 3 (ADD R7, R1)

```
PC_ROM        = "011"  (address 3)
ROM_Decoder   = "001110010000"  (ADD R7, R1)

Decoder outputs:
  sig_and     = 1  (ADD instruction, opcode 00)
  Reg_EN      = "111"  (write R7, from Inst[9:7]=111)
  Mux_A       = "111"  (read R7, from Inst[9:7]=111)
  Mux_B       = "001"  (read R1, from Inst[6:4]=001)
  Sub         = 0  (addition)
  LD          = 0  (use ALU result)
  JMP         = 0  (not a jump)

MuxA_Adder    = R7 = "0000"  (R7 is currently 0)
MuxB_Adder    = R1 = "0011"  (R1 = 3)

ADD_SUB_4:
  A = 0000, B = 0011, M = 0
  S = 0000 + 0011 = 0011  (3)
  overflow = 0

MuxD_RegBank  = 0011  (LD=0 → use ALU result)

PC update:
  Add3_MuxC   = "100"  (PC+1 = 4)
  JMP = 0 → PC_MuxC = "100"
  → Next cycle: PC = 4
  
On clock edge:
  R7 latches 0011 = 3  ✓
  PC latches 100 = 4   ✓
```

---

## Component Dependency Hierarchy

```
NANOPROCESSOR
├── SLOW_CLK
├── ROM
├── PC
│   └── D_FF
├── ADDER_3
├── INSTRUCTION_DEC
├── REG_BANK
│   ├── DEC_3_8
│   │   └── DEC_2_4
│   └── REG_4 (×7)
│       └── D_FFwithEN
├── MUX_8_to_1_4B (×2: MuxA, MuxB)
├── ADD_SUB_4
│   └── FA (×4)
│       └── HA (×2 each)
├── MUX_2_to_1_4B (MuxD)
├── MUX_2_to_1_3B (MuxC)
└── LUT_7_SEG
```

Build and simulate in bottom-up order: start from HA/D_FF, work up to NANOPROCESSOR.
