# 4-Bit Nanoprocessor — Component Explanation

**Target:** Xilinx BASYS3 (Artix-7 xc7a35tcpg236-1) | **Tool:** Vivado 2018.2  
**Architecture:** Single-cycle, 8-instruction ROM, 8 × 4-bit registers, 4-instruction ISA

---

## ISA — Instruction Set Architecture

Every instruction is **12 bits wide**. The top 2 bits are the opcode.

| Instruction | Opcode | Encoding (12 bits)       | Operation              |
|-------------|--------|--------------------------|------------------------|
| MOVI R, d   | `10`   | `10 RRR 0000 dddd`       | R ← d (4-bit immediate)|
| ADD  Ra, Rb | `00`   | `00 Ra  Rb   0000`       | Ra ← Ra + Rb           |
| NEG  R      | `01`   | `01 RRR 000000000`       | R  ← 0 − R  (negate)  |
| JZR  R, d   | `11`   | `11 RRR 0000 0ddd`       | if R = 0: PC ← d       |

- Bits 11–10 = opcode, bits 9–7 = destination/source register, bits 3–0 = immediate / jump target.  
- R0 is hardwired to `0000` — writing to it is silently ignored, reading it always gives zero.  
- `JZR R0, addr` always jumps (R0 = 0 permanently) → used as an unconditional jump.

---

## Demo Program loaded in ROM

Computes **3 + 2 + 1 = 6**, stores result in R7, then halts.

| Addr | Instruction          | Effect                        |
|------|----------------------|-------------------------------|
| 0    | MOVI R1, 3           | R1 = 3 (loop counter)         |
| 1    | MOVI R2, 1           | R2 = 1                        |
| 2    | NEG  R2              | R2 = −1 (decrement value)     |
| 3    | ADD  R7, R1          | R7 += R1  ← **loop body**    |
| 4    | ADD  R1, R2          | R1 −= 1   (R1 = R1 + (−1))   |
| 5    | JZR  R1, 7          | if R1 = 0 → goto 7 (done)     |
| 6    | JZR  R0, 3          | always → goto 3 (loop)        |
| 7    | JZR  R0, 7          | always → goto 7  **HALT**     |

Final state: R7 = `0110` (6), displayed on the rightmost 7-segment digit.

---

## Components

### FA — Full Adder
**File:** `FA.vhd` | **Type:** Combinational

Single-bit adder. The fundamental building block of all arithmetic units.

| Port  | Dir | Width | Description           |
|-------|-----|-------|-----------------------|
| A, B  | in  | 1     | Data inputs           |
| C_in  | in  | 1     | Carry in              |
| S     | out | 1     | Sum: A ⊕ B ⊕ C_in    |
| C_out | out | 1     | Carry out: AB + C_in(A⊕B) |

```
S     = A XOR B XOR C_in
C_out = (A AND B) OR (C_in AND (A XOR B))
```

Vivado maps this to a single carry-chain LUT4 entry.

---

### ADDER_3 — 3-bit PC Incrementer
**File:** `ADDER_3.vhd` | **Type:** Combinational  
**Instantiates:** FA × 3

Adds exactly 1 to its 3-bit input. Used to compute **PC + 1** every cycle.

| Port  | Dir | Width | Description     |
|-------|-----|-------|-----------------|
| A     | in  | 3     | Current PC      |
| S     | out | 3     | PC + 1          |
| carry | out | 1     | Overflow (unused by top-level) |

Implemented by chaining three FAs with B = `1`, `0`, `0` and C_in = `0`. Carries propagate through the chain. When A = `111` (7), S wraps to `000` with carry = 1.

---

### ADD_SUB_4 — 4-bit ALU (Add / Subtract)
**File:** `ADD_SUB_4.vhd` | **Type:** Combinational  
**Instantiates:** FA × 4

Performs both **addition** and **2's-complement subtraction** using the XOR trick on operand B.

| Port     | Dir | Width | Description                  |
|----------|-----|-------|------------------------------|
| A, B     | in  | 4     | Operands                     |
| M        | in  | 1     | Mode: 0 = add, 1 = subtract  |
| S        | out | 4     | Result                       |
| overflow | out | 1     | Signed overflow flag         |

**Key trick:** each B bit is XOR'd with M before entering the adder, and M is also fed as C_in to FA_0.

- M = 0: B ⊕ 0 = B, C_in = 0 → S = A + B
- M = 1: B ⊕ 1 = ~B, C_in = 1 → S = A + ~B + 1 = A − B  (2's complement)

**Overflow detection:** `overflow = carry_into_MSB XOR carry_out_of_MSB`  
(a signed overflow occurs when the carry into the sign bit differs from the carry out).

- Used to execute **ADD** (M=0) and **NEG** (M=1, A = R0 = 0000, so S = 0 − B = −B).

---

### MUX_2_1_3B — 2-to-1 Mux, 3-bit
**File:** `MUX_2_to_1_3B.vhd` | **Type:** Combinational

| Port | Dir | Width | Description             |
|------|-----|-------|-------------------------|
| A, B | in  | 3     | Input channels          |
| S    | in  | 1     | Select: 0→A, 1→B        |
| Q    | out | 3     | Selected output         |

Used as **MuxC** in the top-level to choose the next PC value:
- S=0 (JMP=0): Q = ADDER_3 output (PC+1) — normal sequential execution
- S=1 (JMP=1): Q = Decoder_MuxD[2:0] — jump target from instruction

---

### MUX_2_1_4B — 2-to-1 Mux, 4-bit
**File:** `MUX_2_to_1_4B.vhd` | **Type:** Combinational

Same structure as MUX_2_1_3B but 4 bits wide.

Used as **MuxD** to choose what data is written to the register bank:
- S=0 (LD=0): Q = ALU result (ADD / NEG)
- S=1 (LD=1): Q = Decoder_MuxD (4-bit immediate from MOVI / JZR)

---

### MUX_8_1_4B — 8-to-1 Mux, 4-bit
**File:** `MUX_8_to_1_4B.vhd` | **Type:** Combinational

Selects one of 8 register values based on a 3-bit select.

| Port     | Dir | Width | Description              |
|----------|-----|-------|--------------------------|
| S        | in  | 3     | Register select (0–7)    |
| R0 – R7  | in  | 4 each| Register file read ports |
| Q        | out | 4     | Selected register value  |

Instantiated **twice** in the top-level:
- **MuxA**: selects the first ALU operand (Ra for ADD; register-under-test for JZR)
- **MuxB**: selects the second ALU operand (Rb for ADD; register to negate for NEG)

Implemented as a `with S select` statement — Vivado maps this to a 2-LUT-level mux tree.

---

### ROM — Program ROM
**File:** `ROM.vhd` | **Type:** Combinational (asynchronous read)

Stores the 8-instruction program as a constant array.

| Port | Dir | Width | Description              |
|------|-----|-------|--------------------------|
| S    | in  | 3     | Address (from PC)        |
| Q    | out | 12    | Instruction word         |

Declared as a VHDL `constant` so Vivado infers a **distributed LUT ROM** (not flip-flops). Output is purely combinational — the instruction is available immediately when the address changes, within the same clock cycle.

---

### SLOW_CLK — Clock Divider
**File:** `SLOW_CLK.vhd` | **Type:** Sequential (uses board 100 MHz clock)

Divides the 100 MHz board clock down to a visible rate for the LEDs.

| Port     | Dir | Width | Description          |
|----------|-----|-------|----------------------|
| Clk_in   | in  | 1     | 100 MHz board clock  |
| Clk_out  | out | 1     | Divided slow clock   |

| Generic     | Default    | Effect                           |
|-------------|------------|----------------------------------|
| CLK_DIV_MAX | 50,000,000 | toggles every 50M cycles → 1 Hz |

**How it works:** An internal counter increments on every rising edge of Clk_in. When it reaches CLK_DIV_MAX − 1 it resets to 0 and toggles `clk_status`. The period of Clk_out = 2 × CLK_DIV_MAX × 10 ns.

- Board use: 2 × 50,000,000 × 10 ns = 1 second per cycle (1 Hz) — each instruction takes 1 second, visible on LEDs.
- Testbench: override with `generic map(CLK_DIV_MAX => 4)` → 80 ns per instruction.

---

### PC — Program Counter
**File:** `PC.vhd` | **Type:** Sequential (clocked by Slow_Clk)

3-bit register holding the address of the current instruction.

| Port | Dir | Width | Description                          |
|------|-----|-------|--------------------------------------|
| D    | in  | 3     | Next PC value (from MuxC)            |
| Clr  | in  | 1     | Synchronous reset: sets Q to 000     |
| Clk  | in  | 1     | Slow clock (rising-edge triggered)   |
| Q    | out | 3     | Current PC → drives ROM address      |

On every rising slow_clk edge:
- If Clr = 1 → Q ← "000"
- Else → Q ← D

D is either PC+1 (sequential) or the jump target (JZR taken), selected by MuxC.

---

### REG_BANK — Register Bank
**File:** `REG_BANK.vhd` | **Type:** Sequential (clocked by Slow_Clk) + combinational read

Holds the 8 general-purpose 4-bit registers.

| Port    | Dir | Width | Description                         |
|---------|-----|-------|-------------------------------------|
| D       | in  | 4     | Data to write                       |
| I       | in  | 3     | Destination register index (0–7)    |
| Clk     | in  | 1     | Slow clock                          |
| Clr     | in  | 1     | Synchronous reset (clears R1–R7)    |
| R0 – R7 | out | 4 each| Register outputs (always available) |

**Write (on rising Clk edge):**
- Clr = 1 → all registers cleared to 0
- Clr = 0 AND I ≠ 0 → regs(I) ← D
- I = 0 → no write (R0 is hardwired to 0)

**Read:** purely combinational — all 8 register values are always driven on the output ports. R0 is a constant `"0000"` (no flip-flop). R1–R7 use 7 × 4 = **28 FDRE flip-flops**.

Both MuxA and MuxB read from the register bank outputs simultaneously to form the two ALU operands.

---

### INSTRUCTION_DEC — Instruction Decoder
**File:** `INSTRUCTION_Dec.vhd` | **Type:** Combinational

Decodes the 12-bit instruction and generates all control signals for one cycle.

| Port   | Dir | Width | Description                              |
|--------|-----|-------|------------------------------------------|
| Inst   | in  | 12    | Current instruction from ROM             |
| Reg    | in  | 4     | Value of the register selected by Mux_A (for JZR zero-check) |
| LSB    | out | 4     | Immediate value / jump target            |
| Reg_EN | out | 3     | Which register to write                  |
| Mux_A  | out | 3     | Register index for ALU input A           |
| Mux_B  | out | 3     | Register index for ALU input B           |
| LD     | out | 1     | 1 = write immediate to reg; 0 = write ALU result |
| Sub    | out | 1     | 1 = ALU subtracts (NEG); 0 = adds        |
| JMP    | out | 1     | 1 = take jump (JZR and Reg=0)            |

**Opcode = Inst[11:10]:**

| Opcode | Instruction | Reg_EN       | Mux_A        | Mux_B        | LD | Sub | JMP              |
|--------|-------------|--------------|--------------|--------------|----|----|------------------|
| `10`   | MOVI        | Inst[9:7]    | "000"        | "000"        | 1  | 0  | 0                |
| `00`   | ADD         | Inst[9:7]    | Inst[9:7]    | Inst[6:4]    | 0  | 0  | 0                |
| `01`   | NEG         | Inst[9:7]    | "000" (R0)   | Inst[9:7]    | 0  | 1  | 0                |
| `11`   | JZR         | "000" (none) | Inst[9:7]    | "000"        | 1  | 0  | Reg="0000" ? 1:0 |

NEG works by computing **0 − R**: Mux_A selects R0 (=0) as operand A, Mux_B selects the register to negate as operand B, Sub=1 triggers subtraction.

---

### LUT_7_SEG — 7-Segment Display Decoder
**File:** `LUT_7_SEG.vhd` | **Type:** Combinational (ROM)

Converts a 4-bit hex digit (0–F) to the active-low 7-segment pattern.

| Port    | Dir | Width | Description              |
|---------|-----|-------|--------------------------|
| address | in  | 4     | Digit to display (0–F)   |
| data    | out | 7     | Segment pattern (active-low) |

**Segment encoding:** `data(6:0)` = `(CG, CF, CE, CD, CC, CB, CA)` where each bit being `0` turns the segment **on** (common-anode display, active-low).

| Digit | Pattern   | Segments on        |
|-------|-----------|-------------------|
| 0     | `1000000` | a,b,c,d,e,f       |
| 6     | `0000010` | a,f,g,e,d,c       |
| 3     | `0110000` | a,b,c,d,g         |

Declared as a `constant` so Vivado maps the 16-entry table directly to a **distributed LUT ROM** rather than 7 × 16 flip-flops.

---

### NANOPROCESSOR — Top-Level
**File:** `NANOPROCESSOR.vhd` | **Type:** Structural

Connects all sub-components into the complete single-cycle processor.

| Port      | Dir | Width | Description                      |
|-----------|-----|-------|----------------------------------|
| Clk       | in  | 1     | 100 MHz board clock              |
| Clr       | in  | 1     | Reset (active high, BTNC)        |
| R         | out | 4     | R7 value → LD3:LD0               |
| Overflow  | out | 1     | ALU overflow → LD4               |
| Zero      | out | 1     | ALU result = 0 → LD5             |
| Seven_Seg | out | 7     | 7-segment segments               |
| AN        | out | 4     | Anode control (fixed `"1110"`)   |

**Generic:** `CLK_DIV_MAX` (default 50,000,000) — passed through to SLOW_CLK.

`AN <= "1110"` permanently enables only the **rightmost digit** of the 4-digit display.

`Zero <= '1' when MuxD_Adder = "0000"` — the zero flag reflects the ALU output, not the register write data.

---

## Complete Datapath — One Instruction Cycle

All combinational logic settles between slow_clk edges. State is captured **only on the rising edge of slow_clk**.

```
 slow_clk rising edge
        │
        ▼
 ┌─────────────┐    12-bit instruction
 │  PC  (reg)  │──────────────────────► ROM
 └─────────────┘                         │
        ▲                                ▼
        │                     ┌──────────────────┐
  PC_MuxC (next PC)           │ INSTRUCTION_DEC  │
        │                     │  (combinational) │
        │                  ┌──┴──────────────────┴───┐
   ┌────┴────┐             │  Reg_EN  Mux_A  Mux_B  │
   │ MuxC    │             │  LD      Sub     JMP    │
   │ 2-to-1  │◄────────────┴──────────────────────┘
   │ 3-bit   │     JMP signal         │         │
   └────┬────┘                        │         │
        │                        Mux_A        Mux_B
  PC+1 ◄┤◄── ADDER_3(PC)              │         │
        │                             ▼         ▼
   LSB[2:0]──────────────────► ┌─────────────────────┐
   (jump target)               │  REG_BANK (R0–R7)   │
                               │  (read: comb.)       │
                               └──────────┬──────────┘
                                    │          │
                                  MuxA       MuxB
                                    │          │
                                    ▼          ▼
                               ┌──────────────────┐
                               │   ADD_SUB_4      │
                               │  M=Sub signal    │──► Overflow
                               └────────┬─────────┘
                                        │ ALU result
                                   ┌────┴────┐
                                   │  MuxD   │◄── Immediate (LD=1)
                                   │ 2-to-1  │
                                   └────┬────┘
                                        │ write data
                                        ▼
                         ┌──────────────────────────┐
                         │  REG_BANK  (write port)  │◄── Reg_EN, Clk
                         │  captures on rising Clk  │
                         └──────────────────────────┘
                                  R7 ──► LUT_7_SEG ──► Seven_Seg
                                  R7 ──► R (LEDs)
```

**Key points for the viva:**
1. **Single-cycle:** every instruction completes in exactly one slow_clk period — no pipeline registers, no hazards.
2. **All reads are combinational** (ROM, register file, decoder, muxes, ALU). Only **PC and REG_BANK latch state**, and they do so on the **same** clock edge simultaneously.
3. **R0 = 0 always.** No flip-flop is allocated for it. `JZR R0, addr` is the unconditional jump because the zero-check on R0 always succeeds.
4. **NEG uses the ALU in subtract mode** with R0 (=0) as operand A: result = 0 − R = −R.
5. **Overflow flag** detects signed overflow in 4-bit 2's complement arithmetic only.
6. **The slow clock** is not a pipeline stage — it is the entire cycle. All logic must settle within one slow_clk period (10 ns on board at 100 MHz board clock; one slow_clk period = 1 second at default CLK_DIV_MAX).
