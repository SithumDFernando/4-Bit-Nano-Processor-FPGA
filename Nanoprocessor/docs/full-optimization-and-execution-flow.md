# Full Optimization & Execution Flow of the Nanoprocessor

This document serves as the master guide to the 4-bit Nanoprocessor. It traces the full data process cycle—from instruction fetch to writeback—while integrating a detailed breakdown of the optimizations applied. It highlights exactly **where**, **how**, and **why** the optimizations impact the processor's execution.

---

## Part 1: The Full Process Loop (Data Flow)

The Nanoprocessor operates on a **Single-Cycle Architecture**. Everything described below happens during exactly **one tick** of the slow clock. There are no intermediate pipeline registers to hold data; combinational logic routes and computes everything instantly between clock edges.

### 1. Clock Scaling (The Heartbeat)
* **What happens:** The BASYS 3 board native clock runs at 100 MHz (10 nanoseconds per cycle). The processor's execution is stepped down to ~0.5 Hz (2 seconds per cycle) so a human can visibly watch the LEDs change on the FPGA board.
* **Component:** `Slow_Clk`

### 2. Instruction Fetch
* **What happens:** The Program Counter (PC) safely holds the address of the current instruction (a 3-bit number, e.g., `010`).
* **Data Flow:**
  - This 3-bit address travels to the **Program ROM**.
  - The ROM instantly looks up row `010` and outputs the 12-bit instruction (e.g., `100010000011` for `MOVI R1, 3`).
  - Simultaneously, the 3-bit address goes to the **3-bit Adder (PC+1)**, computing the default next address (`011`).

### 3. Decode & Control Generation
* **What happens:** The 12-bit instruction enters the **Instruction Decoder**.
* **Data Flow:** The decoder analyzes the bits purely combinationally. It splits the instruction and sets out control signals that configure the entire rest of the datapath:
  - `Reg_En`: Which register to write to (e.g., `001` for R1).
  - `Mux_Sel_A` & `Mux_Sel_B`: Which registers should dump their contents to the ALU.
  - `Imm_Sel`: Controls if the datapath should route back an immediate value directly from the instruction or wait for the ALU result.
  - `Add_Sub`: Commands the ALU to Add (`0`) or Subtract (`1`).

### 4. Data Fetch (Execution Setup)
* **What happens:** With `Mux_Sel_A` and `Mux_Sel_B` set, the datapath reaches into the **Register Bank**.
* **Data Flow:** The two 8-way Multiplexers (`MUX_8_to_1_4B`) route the selected 4-bit values out to the ALU as `operand_a` and `operand_b`.

### 5. Execution (ALU)
* **What happens:** The ALU (`Add_Sub_4bit`) receives the two 4-bit operands.
* **Data Flow:** The ALU computes both operands instantly. If `Add_Sub` is `1`, the B operand is inverted, and `1` is fed to the carry-in bit to perform 2's complement subtraction. It outputs:
  - `alu_result` (the 4-bit math result).
  - `Zero` flag (high if the result is exactly `0000`).
  - `Overflow` flag (high if a signed overflow occurs).

### 6. Value Selection (Data Bus)
* **What happens:** We now have two possible answers: the `alu_result` or an Immediate value (the last 4 bits of the instruction).
* **Data Flow:** The `MUX_2_to_1_4B` is controlled by `Imm_Sel`. It picks the correct answer and places it onto the `data_bus`.

### 7. Writeback & PC Update (The Clock Edge Strikes)
* **What happens:** The cycle finishes. The clock edge hits, and the system permanently stores the new state.
* **Data Flow:**
  - **Register Bank:** If `Reg_En_Load` is high, the value sitting on the `data_bus` is locked into the register designated by `Reg_En`.
  - **Program Counter:** The jump-check unit checks if a Jump Instruction (`JZR`) was active AND if `operand_a` equalled zero. If true, the PC locks in the instruction's embedded Jump Target Address. Otherwise, the PC locks in the `PC+1` value.

The processor is now ready to begin the cycle again at step 2.

---

## Part 2: Optimization Breakdown (How & Why)

The original codebase relied heavily on structural instantiations—connecting small gate-level VHDL primitives with wires together manually to build complex components. The optimized codebase transitions from structural to **behavioural** modelling, allowing the Xilinx Vivado synthesizer to optimize the logic down to its core components.

### 1. Register Bank: Eliminating Structural Chains

* **Original:** Used a 3-to-8 Decoder component, connected to seven individual 4-bit Register components, each of which contained four D-Flip-Flops with Enable components.
* **Optimized:** Replaced entirely with a behavioural memory array: `type reg_file_t is array (1 to 7) of std_logic_vector(3 downto 0);` inside a single clocked VHDL `process`.
* **How & Why:** Instead of forcing Vivado to trace signals across four hierarchal files to figure out it's just meant to be storage, the behavioural array tells Vivado exactly what is needed.
* **Pros:**
  - Massively reduces lines of code and eliminates component files.
  - Vivado natively maps this directly to 28 efficient FDRE primitives (Flip-Flops).
  - Allows Vivado to apply SRL (Shift-Register-LUT) optimizations on the read ports.
* **Cons:** Less explicit for learning pure digital logic gate connections.

### 2. Instruction Decoder: `with/select` Instead of AND/OR

* **Original:** Used over 100 lines of explicit logic equations matching boolean minterms to generate the control signals (e.g. `(m_LSB AND sig_move3) OR (a_LSB AND sig_and3) ...`).
* **Optimized:** Leverages concurrent VHDL `with ... select` statements based on a 2-bit opcode.
* **How & Why:** The original approach forced synthesis mapping into a multi-stage tree of LUTs (Look-Up Tables, max taking 4-5 layers). `with/select` tells the synthesizer precisely what mapping to construct, directly resolving to a 2-layer thick 6-input LUT tree.
* **Pros:**
  - Huge reduction in propagation delay (combinational delay).
  - Less chip area (fewer LUTs consumed).
* **Cons:** None from a hardware perspective.

### 3. Program and Display ROMs: Constant Distributed Memory

* **Original:** The `Program_ROM` and `LUT_7_SEG` used `signal` types bounded by variables to store their hex arrays.
* **Optimized:** Changed the array declarations from `signal` to `constant`.
* **How & Why:** In VHDL, asserting a `signal` with initial data infers physical registers (Flip-Flops). By changing this entirely to `constant`, Vivado understands that the data is *Read-Only*. It drops the Flip-Flops entirely and maps the table into available routing slices on the LUT fabric (Distributed ROM).
* **Pros:** Highly efficient, lower cost, avoids using massive Block-RAM modules for tiny tables.
* **Cons:** Cannot ever be overwritten at runtime (which is perfectly normal for a true ROM).

### 4. Full Adder (FA): Direct Equation Flattening

* **Original:** Created an FA by physically combining two Half-Adder (`HA.vhd`) components through connecting wires.
* **Optimized:** Eliminated the HA instantiations internally and used a pure logic equation: `S <= A xor B xor C_in;`
* **How & Why:** The initial structure caused the carry-chain addition to break across two logic levels. By flattening it, Vivado wraps it entirely into native hardware elements meant precisely for chained addition (the FPGA Carry Chain `CARRY4` primitive blocks).
* **Pros:** The ripple-carry time is sliced significantly. The 4-bit adder loses 4 levels of gate delays across worst-case operations.
* **Cons:** Removes the visible modularity of seeing HA components.

### 5. Control Simplification (Zero check and Jumps)

* **Original:** Component and gate sprawl everywhere meant signals were dragged up and down to check logic conditions (like checking `S` bits manually).
* **Optimized:** Advanced logic flags inside `NANOPROCESSOR.vhd` natively (e.g. `Zero <= '1' when alu_result = "0000"`).
* **How & Why:** Modern synthesizers translate these expressions efficiently into highly compressed NOR logic configurations in a single LUT slice.
* **Pros:** Cleans up visual noise and wires heavily.
* **Cons:** None.