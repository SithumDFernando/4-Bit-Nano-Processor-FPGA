library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimizations vs original:
-- 1. Removed unused D_FF component declaration and Res signal
-- 2. Replaced ~50 intermediate signals and manual AND/OR mux trees
--    (sig_move2/3, m_LSB, a_Reg_EN, etc.) with a 2-bit opcode alias
-- 3. Per-instruction mux trees collapse into four-way with/select
--    statements — Vivado maps to 6-LUT muxes (2 levels) instead of
--    original AND/OR pattern (4-5 levels)
-- 4. Moved JMP zero-check inside: uses VHDL conditional (single AND-NOR gate)
entity INSTRUCTION_DEC is
    Port ( Inst   : in  STD_LOGIC_VECTOR (11 downto 0);
           Reg    : in  STD_LOGIC_VECTOR (3 downto 0);
           LSB    : out STD_LOGIC_VECTOR (3 downto 0);
           Reg_EN : out STD_LOGIC_VECTOR (2 downto 0);
           Mux_A  : out STD_LOGIC_VECTOR (2 downto 0);
           LD     : out STD_LOGIC;
           Mux_B  : out STD_LOGIC_VECTOR (2 downto 0);
           Sub    : out STD_LOGIC;
           JMP    : out STD_LOGIC);
end INSTRUCTION_DEC;

architecture Behavioral of INSTRUCTION_DEC is
    signal opcode : std_logic_vector(1 downto 0);
begin
    opcode <= Inst(11 downto 10);

    -- Destination register: all instructions write to Inst[9:7] except JZR
    with opcode select Reg_EN <=
        "000"              when "11",   -- JZR: no register write
        Inst(9 downto 7)   when others; -- MOVI / ADD / NEG

    -- Operand A mux select (also register tested for JZR zero-check)
    with opcode select Mux_A <=
        "000"              when "10",   -- MOVI: A unused, select R0
        Inst(9 downto 7)   when "00",   -- ADD:  Ra
        "000"              when "01",   -- NEG:  A = R0 = 0 (result = 0 - R)
        Inst(9 downto 7)   when others; -- JZR:  register to test

    -- Operand B mux select
    with opcode select Mux_B <=
        "000"              when "10",   -- MOVI: B unused
        Inst(6 downto 4)   when "00",   -- ADD:  Rb
        Inst(9 downto 7)   when "01",   -- NEG:  B = R (compute 0 - R)
        "000"              when others; -- JZR:  R0

    -- LD='1' selects immediate on data bus
    with opcode select LD <=
        '1' when "10",   -- MOVI
        '0' when "00",   -- ADD
        '0' when "01",   -- NEG
        '1' when others; -- JZR (but Reg_EN="000" blocks write)

    -- Subtract: only NEG computes 0 - R
    with opcode select Sub <=
        '1' when "01",
        '0' when others;

    -- LSB carries the immediate (MOVI) or jump address [2:0] (JZR)
    LSB <= Inst(3 downto 0);

    -- Jump enable: JZR opcode AND tested register equals zero
    JMP <= '1' when (opcode = "11") and (Reg = "0000") else '0';
end Behavioral;
