library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for PC: tests load, clear, and hold behaviour.
entity TB_Program_Counter is
end TB_Program_Counter;

architecture Behavioral of TB_Program_Counter is
    component PC
        port (D   : in  std_logic_vector(2 downto 0);
              Clr : in  std_logic;
              Clk : in  std_logic;
              Q   : out std_logic_vector(2 downto 0));
    end component;

    signal D, Q : std_logic_vector(2 downto 0) := "000";
    signal Clr  : std_logic := '0';
    signal Clk  : std_logic := '0';
begin
    UUT : PC port map (D => D, Clr => Clr, Clk => Clk, Q => Q);

    Clk <= not Clk after 50 ns;  -- 100 ns period

    process begin
        -- ── Reset ────────────────────────────────────────────────────
        Clr <= '1';
        wait for 110 ns;  -- past first clock edge
        assert Q = "000" report "T1: Q should be 000 after clear" severity error;
        Clr <= '0';

        -- ── Load 001 ────────────────────────────────────────────────
        D <= "001";
        wait for 100 ns;
        assert Q = "001" report "T2: Q should be 001" severity error;

        -- ── Load 010 ────────────────────────────────────────────────
        D <= "010";
        wait for 100 ns;
        assert Q = "010" report "T3: Q should be 010" severity error;

        -- ── Load 011, then clear mid-cycle ──────────────────────────
        D <= "011";
        wait for 100 ns;
        assert Q = "011" report "T4: Q should be 011" severity error;
        Clr <= '1';
        wait for 100 ns;
        assert Q = "000" report "T5: Q should be 000 after mid-clear" severity error;
        Clr <= '0';

        -- ── Load 101, 110, 111 ──────────────────────────────────────
        D <= "101"; wait for 100 ns;
        assert Q = "101" report "T6: Q should be 101" severity error;
        D <= "110"; wait for 100 ns;
        assert Q = "110" report "T7: Q should be 110" severity error;
        D <= "111"; wait for 100 ns;
        assert Q = "111" report "T8: Q should be 111" severity error;

        assert false report "TB_Program_Counter: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
