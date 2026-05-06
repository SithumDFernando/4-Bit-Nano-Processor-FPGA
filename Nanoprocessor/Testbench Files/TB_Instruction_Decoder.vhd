library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Instruction_Decoder is
end TB_Instruction_Decoder;

architecture Behavioral of TB_Instruction_Decoder is
    signal Inst   : std_logic_vector(11 downto 0) := (others => '0');
    signal Reg    : std_logic_vector(3 downto 0)  := "0000";
    signal LSB    : std_logic_vector(3 downto 0);
    signal Reg_EN : std_logic_vector(2 downto 0);
    signal Mux_A  : std_logic_vector(2 downto 0);
    signal LD     : std_logic;
    signal Mux_B  : std_logic_vector(2 downto 0);
    signal Sub    : std_logic;
    signal JMP    : std_logic;
begin
    UUT : entity work.INSTRUCTION_DEC
        port map (Inst => Inst, Reg => Reg, LSB => LSB,
                  Reg_EN => Reg_EN, Mux_A => Mux_A, LD => LD,
                  Mux_B => Mux_B, Sub => Sub, JMP => JMP);

    process begin
        -- MOVI R1, 2  →  10 001 0000 0010
        Reg <= "0000"; Inst <= "100010000010"; wait for 50 ns;
        assert Reg_EN = "001" report "T1: Reg_EN=001" severity error;
        assert LD     = '1'   report "T1: LD=1"       severity error;
        assert Sub    = '0'   report "T1: Sub=0"       severity error;
        assert JMP    = '0'   report "T1: JMP=0"       severity error;
        assert LSB    = "0010" report "T1: LSB=0010"   severity error;

        -- MOVI R2, 1  →  10 010 0000 0001
        Inst <= "100100000001"; wait for 50 ns;
        assert Reg_EN = "010" report "T2: Reg_EN=010" severity error;
        assert LD     = '1'   report "T2: LD=1"        severity error;
        assert LSB    = "0001" report "T2: LSB=0001"   severity error;

        -- NEG R2      →  01 010 000000000
        Inst <= "010100000000"; wait for 50 ns;
        assert Reg_EN = "010" report "T3: Reg_EN=010"     severity error;
        assert Sub    = '1'   report "T3: Sub=1 (NEG)"    severity error;
        assert LD     = '0'   report "T3: LD=0"           severity error;
        assert Mux_B  = "010" report "T3: Mux_B=010 (R2)" severity error;

        -- ADD R1, R2  →  00 001 010 0000
        Inst <= "000010100000"; wait for 50 ns;
        assert Reg_EN = "001" report "T4: Reg_EN=001"  severity error;
        assert Mux_A  = "001" report "T4: Mux_A=001"   severity error;
        assert Mux_B  = "010" report "T4: Mux_B=010"   severity error;
        assert Sub    = '0'   report "T4: Sub=0"        severity error;
        assert LD     = '0'   report "T4: LD=0"         severity error;

        -- JZR R1, 7  →  11 001 0000 0111  (Reg=0 → jump)
        Reg <= "0000"; Inst <= "110010000111"; wait for 50 ns;
        assert Reg_EN = "000" report "T5: Reg_EN=000"  severity error;
        assert JMP    = '1'   report "T5: JMP=1"       severity error;
        assert LSB    = "0111" report "T5: LSB=0111"   severity error;
        assert Mux_A  = "001" report "T5: Mux_A=001"   severity error;

        -- JZR R1, 7  (Reg/=0 → no jump)
        Reg <= "0100"; wait for 50 ns;
        assert JMP = '0' report "T6: JMP=0 when Reg/=0" severity error;

        -- JZR R7, 3  →  11 111 0000 0011  (Reg=0 → jump)
        Reg <= "0000"; Inst <= "111110000011"; wait for 50 ns;
        assert JMP   = '1'    report "T7: JMP=1"      severity error;
        assert Mux_A = "111"  report "T7: Mux_A=111"  severity error;
        assert LSB   = "0011" report "T7: LSB=0011"   severity error;

        assert false report "TB_Instruction_Decoder: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
