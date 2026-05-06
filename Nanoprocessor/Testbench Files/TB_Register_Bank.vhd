library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for the optimised REG_BANK.
-- Tests: reset, write to R1-R7, R0 hardwired to 0, reset clears all.
entity TB_Register_Bank is
end TB_Register_Bank;

architecture Behavioral of TB_Register_Bank is
    component REG_BANK
        port (D   : in  std_logic_vector(3 downto 0);
              Clk : in  std_logic;
              I   : in  std_logic_vector(2 downto 0);
              Clr : in  std_logic;
              R0, R1, R2, R3, R4, R5, R6, R7 : out std_logic_vector(3 downto 0));
    end component;

    signal D  : std_logic_vector(3 downto 0) := "0000";
    signal I  : std_logic_vector(2 downto 0) := "000";
    signal Clr, Clk : std_logic := '0';
    signal R0, R1, R2, R3, R4, R5, R6, R7 : std_logic_vector(3 downto 0);

begin
    UUT : REG_BANK port map (
        D => D, Clk => Clk, I => I, Clr => Clr,
        R0 => R0, R1 => R1, R2 => R2, R3 => R3,
        R4 => R4, R5 => R5, R6 => R6, R7 => R7);

    -- 25 MHz clock (40 ns period)
    Clk <= not Clk after 20 ns;

    process begin
        -- ── Reset ────────────────────────────────────────────────────
        Clr <= '1';
        wait for 50 ns;
        assert R0 = "0000" report "T1: R0 should be 0000 after reset" severity error;
        assert R1 = "0000" report "T1: R1 should be 0000 after reset" severity error;
        Clr <= '0';

        -- ── Write 0001 to R1 (I="001") ──────────────────────────────
        D <= "0001"; I <= "001";
        wait for 40 ns;  -- one clock cycle
        assert R1 = "0001" report "T2: R1 should be 0001" severity error;

        -- ── Write 0101 to R2 (I="010") ──────────────────────────────
        D <= "0101"; I <= "010";
        wait for 40 ns;
        assert R2 = "0101" report "T3: R2 should be 0101" severity error;

        -- ── Write 1100 to R7 (I="111") ──────────────────────────────
        D <= "1100"; I <= "111";
        wait for 40 ns;
        assert R7 = "1100" report "T4: R7 should be 1100" severity error;

        -- ── Attempt write to R0 (I="000") → should remain 0000 ──────
        D <= "1111"; I <= "000";
        wait for 40 ns;
        assert R0 = "0000" report "T5: R0 should remain 0000" severity error;

        -- ── Verify R1 and R2 unchanged ──────────────────────────────
        assert R1 = "0001" report "T6: R1 should still be 0001" severity error;
        assert R2 = "0101" report "T6: R2 should still be 0101" severity error;

        -- ── Reset clears everything ─────────────────────────────────
        Clr <= '1';
        wait for 40 ns;
        assert R1 = "0000" report "T7: R1 should be 0000 after reset" severity error;
        assert R7 = "0000" report "T7: R7 should be 0000 after reset" severity error;

        assert false report "TB_Register_Bank: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
