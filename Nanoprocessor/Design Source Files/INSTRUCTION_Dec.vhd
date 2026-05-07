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
    signal sig_move, sig_and, sig_neg, sig_jump : std_logic;
begin
    -- Decode opcode from bits 11:10
    sig_move <= (NOT Inst(10)) AND      Inst(11);
    sig_and  <= (NOT Inst(10)) AND (NOT Inst(11));
    sig_neg  <=      Inst(10)  AND (NOT Inst(11));
    sig_jump <=      Inst(10)  AND      Inst(11);

    -- LD: '1' for MOVI and JZR (both have Inst(11)='1') — direct wire, no gates
    LD <= Inst(11);

    -- Sub: '1' only for NEG — wire to existing signal
    Sub <= sig_neg;

    -- LSB: Inst(3:0) for MOVI/JZR (Inst(11)='1'), else "0000" — 4 AND gates
    LSB <= Inst(3 downto 0) when Inst(11) = '1' else "0000";

    -- Reg_EN: Inst(9:7) for all instructions except JZR — 3 AND gates + 1 NOT
    Reg_EN <= Inst(9 downto 7) when sig_jump = '0' else "000";

    -- Mux_A: Inst(9:7) for ADD and JZR, "000" for MOVI/NEG — 3 AND gates + 1 OR
    Mux_A <= Inst(9 downto 7) when (sig_and = '1' or sig_jump = '1') else "000";

    -- Mux_B: Inst(6:4) for ADD, Inst(9:7) for NEG, "000" otherwise — 2-way instead of 4-way
    Mux_B <= Inst(6 downto 4) when sig_and  = '1' else
             Inst(9 downto 7) when sig_neg  = '1' else
             "000";

    -- JMP: '1' only when JZR and tested register is zero
    JMP <= sig_jump AND NOT(Reg(0) OR Reg(1) OR Reg(2) OR Reg(3));
end Behavioral;
