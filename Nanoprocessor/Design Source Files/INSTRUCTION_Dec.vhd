library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity INSTRUCTION_DEC is
    Port ( Inst : in STD_LOGIC_VECTOR (11 downto 0);
--           Clk : in STD_LOGIC;
           Reg : in STD_LOGIC_VECTOR (3 downto 0);
           LSB : out STD_LOGIC_VECTOR (3 downto 0);
           Reg_EN : out STD_LOGIC_VECTOR (2 downto 0);
           Mux_A : out STD_LOGIC_VECTOR (2 downto 0);
           LD : out STD_LOGIC;
           Mux_B : out STD_LOGIC_VECTOR (2 downto 0);
           Sub : out STD_LOGIC;
           JMP : out STD_LOGIC);
end INSTRUCTION_DEC;

architecture Behavioral of INSTRUCTION_DEC is
    -- Only 3 signals needed: sig_move was computed but never consumed, removed.
    signal sig_neg, sig_jump : std_logic;
begin
    -- NEG: opcode 01 (Inst(11)=0, Inst(10)=1)
    sig_neg  <= Inst(10) AND (NOT Inst(11));
    -- JZR: opcode 11 (both bits '1')
    sig_jump <= Inst(10) AND      Inst(11);

    -- LD='1' for MOVI(10) and JZR(11): both share Inst(11)='1' — zero gates, direct wire
    LD <= Inst(11);

    -- Sub='1' only for NEG(01) — wire to sig_neg
    Sub <= sig_neg;

    -- LSB = Inst(3:0) when Inst(11)='1' (MOVI or JZR), else block — 4 AND gates
    LSB <= Inst(3 downto 0) when Inst(11) = '1' else "0000";

    -- Reg_EN = Inst(9:7) unless JZR (opcode 11 means both bits are '1')
    Reg_EN <= Inst(9 downto 7) when sig_jump = '0' else "000";

    -- Mux_A = Inst(9:7) for ADD(00) and JZR(11): when Inst(11) equals Inst(10) — XNOR
    Mux_A <= Inst(9 downto 7) when (Inst(11) = Inst(10)) else "000";

    -- Mux_B: ADD(00)→Inst(6:4), NEG(01)→Inst(9:7), else "000"
    Mux_B <= Inst(6 downto 4) when (Inst(11) = '0' and Inst(10) = '0') else
             Inst(9 downto 7) when sig_neg = '1' else
             "000";

    -- JMP: JZR opcode AND all register bits zero (NOR4)
    JMP <= sig_jump AND NOT(Reg(0) OR Reg(1) OR Reg(2) OR Reg(3));
end Behavioral;
