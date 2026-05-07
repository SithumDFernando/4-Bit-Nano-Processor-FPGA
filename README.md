# na4-bit Nanoprocessor (Extended)

This project implements an extended 4-bit Nanoprocessor with a 14-bit Instruction Set Architecture (ISA).

## Instruction Format

Instructions are 14 bits long with the following structure:
`[Opcode (4 bits)] [Reg A (3 bits)] [Reg B (3 bits)] [Immediate/Address (4 bits)]`

### Supported Instructions

The first 4 bits (Opcode) define the operation in the `00xx` or `01xx` patterns:

| Instruction | Opcode | Format             | Description                        |
| :---------- | :----- | :----------------- | :--------------------------------- |
| **ADD**     | `0000` | `0000 Ra Rb 0000`  | Add: `Ra = Ra + Rb`                |
| **NEG**     | `0001` | `0001 Ra 000 0000` | Negate: `Ra = -Ra`                 |
| **MOVI**    | `0010` | `0010 Ra 000 dddd` | Move Immediate: `Ra = dddd`        |
| **JZR**     | `0011` | `0011 Ra 000 dddd` | Jump if Zero: `If Ra=0, PC = dddd` |
| **SUB**     | `0100` | `0100 Ra Rb 0000`  | Subtract: `Ra = Ra - Rb`           |
| **AND**     | `0101` | `0101 Ra Rb 0000`  | Bitwise AND: `Ra = Ra AND Rb`      |

## Components

- **Instruction Decoder**: Decodes 14-bit instructions and generates control signals.
- **Register Bank**: Contains 8 distinct 4-bit registers (R0 to R7).
- **ADD_SUB_4**: 4-bit Arithmetic Unit for addition and subtraction.
- **AND_4**: 4-bit Logic Unit for bitwise operations.
- **ROM**: Stores the program memory (14 bits x 8 locations).
- **Program Counter (PC)**: Tracks the current instruction address.
- **Muxes**: Route data between registers, ALU, and ROM.

## New Features (Extended)

- **14-bit ISA**: Expanded from 12 bits to allow for future instruction set growth.
- **SUB Instruction**: Native support for subtraction using the 2's complement adder.
- **AND Instruction**: Native support for 4-bit bitwise logical AND operation.
- **Documentation**: Instructions now follow a consistent `00xx`/`01xx` opcode scheme.
