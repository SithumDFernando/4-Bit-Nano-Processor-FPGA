library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Add_Sub_4bit is
end TB_Add_Sub_4bit;

architecture Behavioral of TB_Add_Sub_4bit is
    signal A, B, S   : std_logic_vector(3 downto 0) := "0000";
    signal M         : std_logic := '0';
    signal overflow  : std_logic;
begin
    UUT : entity work.ADD_SUB_4
        port map (A => A, B => B, M => M, S => S, overflow => overflow);

    process begin
        -- 5 + 12 = 17 → wraps to 1 (0001)
        A <= "0101"; B <= "1100"; M <= '0'; wait for 50 ns;
        assert S = "0001" report "T1: 5+12 should be 0001" severity error;

        -- 2 - 14: 0010 + ~1110 + 1 = 0010 + 0010 = 0100
        A <= "0010"; B <= "1110"; M <= '1'; wait for 50 ns;
        assert S = "0100" report "T2: 2-14 should be 0100" severity error;

        -- 10 - 10 = 0
        A <= "1010"; B <= "1010"; M <= '1'; wait for 50 ns;
        assert S = "0000" report "T3: 10-10 should be 0000" severity error;

        -- 14 - 1 = 13 (1101)
        A <= "1110"; B <= "0001"; M <= '1'; wait for 50 ns;
        assert S = "1101" report "T4: 14-1 should be 1101" severity error;

        -- 0 + 0 = 0
        A <= "0000"; B <= "0000"; M <= '0'; wait for 50 ns;
        assert S = "0000" report "T5: 0+0 should be 0000" severity error;

        -- 6 + 10 = 16 → wraps to 0
        A <= "0110"; B <= "1010"; M <= '0'; wait for 50 ns;
        assert S = "0000" report "T6: 6+10 wraps to 0000" severity error;

        -- 7 + 1 = 8 (no overflow in unsigned, sign overflow)
        A <= "0111"; B <= "0001"; M <= '0'; wait for 50 ns;
        assert S = "1000" report "T7: 7+1 should be 1000" severity error;
        assert overflow = '1' report "T7: signed overflow expected" severity error;

        assert false report "TB_Add_Sub_4bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
