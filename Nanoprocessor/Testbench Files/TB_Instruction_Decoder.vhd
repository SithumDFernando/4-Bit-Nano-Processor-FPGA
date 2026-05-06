library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for the optimised INSTRUCTION_DEC.
-- Tests all 4 opcodes: MOVI, ADD, NEG, JZR (with Reg=0 and Reg/=0).
entity TB_Instruction_Decoder is
end TB_Instruction_Decoder;

architecture Behavioral of TB_Instruction_Decoder is
    component INSTRUCTION_DEC
        port (Inst   : in  std_logic_vector(11 downto 0);
              Reg    : in  std_logic_vector(3 downto 0);
              LSB    : out std_logic_vector(3 downto 0);
              Reg_EN : out std_logic_vector(2 downto 0);
              Mux_A  : out std_logic_vector(2 downto 0);
              LD     : out std_logic;
              Mux_B  : out std_logic_vector(2 downto 0);
              Sub    : out std_logic;
              JMP    : out std_logic);
    end component;

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
    UUT : INSTRUCTION_DEC port map (
        Inst => Inst, Reg => Reg, LSB => LSB, Reg_EN => Reg_EN,
        Mux_A => Mux_A, LD => LD, Mux_B => Mux_B, Sub => Sub, JMP => JMP);

    process begin
        -- ── Test 1: MOVI R1, 2 → 10 001 0000 0010 ───────────────────
        Reg <= "0000";
        Inst <= "100010000010";
        wait for 50 ns;
        assert Reg_EN = "001" report "T1: Reg_EN should be 001" severity error;
        assert LD = '1'       report "T1: LD should be 1 (MOVI)" severity error;
        assert Sub = '0'      report "T1: Sub should be 0" severity error;
        assert JMP = '0'      report "T1: JMP should be 0" severity error;
        assert LSB = "0010"   report "T1: LSB should be 0010" severity error;

        -- ── Test 2: MOVI R2, 1 → 10 010 0000 0001 ───────────────────
        Inst <= "100100000001";
        wait for 50 ns;
        assert Reg_EN = "010" report "T2: Reg_EN should be 010" severity error;
        assert LD = '1'       report "T2: LD should be 1" severity error;

        -- ── Test 3: NEG R2 → 01 010 0000 0000 ───────────────────────
        Inst <= "010100000000";
        wait for 50 ns;
        assert Reg_EN = "010" report "T3: Reg_EN should be 010" severity error;
        assert Sub = '1'      report "T3: Sub should be 1 (NEG)" severity error;
        assert LD = '0'       report "T3: LD should be 0" severity error;
        assert Mux_B = "010"  report "T3: Mux_B should be 010 (NEG target)" severity error;

        -- ── Test 4: ADD R1, R2 → 00 001 010 0000 ────────────────────
        Inst <= "000010100000";
        wait for 50 ns;
        assert Reg_EN = "001" report "T4: Reg_EN should be 001" severity error;
        assert Mux_A = "001"  report "T4: Mux_A should be 001 (Ra)" severity error;
        assert Mux_B = "010"  report "T4: Mux_B should be 010 (Rb)" severity error;
        assert Sub = '0'      report "T4: Sub should be 0 (ADD)" severity error;
        assert LD = '0'       report "T4: LD should be 0" severity error;

        -- ── Test 5: JZR R1, 7 → 11 001 0000 0111 (Reg=0 → jump) ────
        Reg <= "0000";
        Inst <= "110010000111";
        wait for 50 ns;
        assert Reg_EN = "000" report "T5: Reg_EN should be 000 (JZR)" severity error;
        assert JMP = '1'      report "T5: JMP should be 1 (Reg=0)" severity error;
        assert LSB = "0111"   report "T5: LSB should be 0111" severity error;

        -- ── Test 6: JZR R1, 7 (Reg/=0 → no jump) ────────────────────
        Reg <= "0100";
        wait for 50 ns;
        assert JMP = '0'      report "T6: JMP should be 0 (Reg/=0)" severity error;

        -- ── Test 7: JZR R7, 3 → 11 111 0000 0011 ────────────────────
        Reg <= "0000";
        Inst <= "111110000011";
        wait for 50 ns;
        assert JMP = '1'      report "T7: JMP should be 1" severity error;
        assert Mux_A = "111"  report "T7: Mux_A should be 111" severity error;

        assert false report "TB_Instruction_Decoder: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
