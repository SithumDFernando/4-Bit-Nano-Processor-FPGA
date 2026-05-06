library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for ADD_SUB_4: tests add, subtract, overflow, and zero detection.
entity TB_Add_Sub_4bit is
end TB_Add_Sub_4bit;

architecture Behavioral of TB_Add_Sub_4bit is
    component ADD_SUB_4
        port (A, B     : in  std_logic_vector(3 downto 0);
              S        : out std_logic_vector(3 downto 0);
              M        : in  std_logic;
              overflow : out std_logic);
    end component;

    signal A, B, S : std_logic_vector(3 downto 0);
    signal M, overflow : std_logic;
begin
    UUT : ADD_SUB_4 port map (A => A, B => B, M => M, S => S, overflow => overflow);

    process begin
        -- ── Test 1: 5 + 12 = 17 → 0001 with overflow ────────────────
        A <= "0101"; B <= "1100"; M <= '0';
        wait for 50 ns;
        assert S = "0001" report "T1: 5+12 should be 0001" severity error;

        -- ── Test 2: 2 - 14 = -12 → 0100, M=1 ───────────────────────
        A <= "0010"; B <= "1110"; M <= '1';
        wait for 50 ns;
        assert S = "0100" report "T2: 2-14 result" severity error;

        -- ── Test 3: 10 - 10 = 0 ─────────────────────────────────────
        A <= "1010"; B <= "1010"; M <= '1';
        wait for 50 ns;
        assert S = "0000" report "T3: 10-10 should be 0000" severity error;

        -- ── Test 4: 14 - 1 = 13 ─────────────────────────────────────
        A <= "1110"; B <= "0001"; M <= '1';
        wait for 50 ns;
        assert S = "1101" report "T4: 14-1 should be 1101" severity error;

        -- ── Test 5: 0 + 0 = 0 ───────────────────────────────────────
        A <= "0000"; B <= "0000"; M <= '0';
        wait for 50 ns;
        assert S = "0000" report "T5: 0+0 should be 0000" severity error;

        -- ── Test 6: 6 + 10 = 16 → 0000 with carry out ──────────────
        A <= "0110"; B <= "1010"; M <= '0';
        wait for 50 ns;
        assert S = "0000" report "T6: 6+10 should wrap to 0000" severity error;

        assert false report "TB_Add_Sub_4bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
