library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Program_Counter is
end TB_Program_Counter;

architecture Behavioral of TB_Program_Counter is
    signal D, Q : std_logic_vector(2 downto 0) := "000";
    signal Clr  : std_logic := '0';
    signal Clk  : std_logic := '0';
begin
    UUT : entity work.PC port map (D => D, Clr => Clr, Clk => Clk, Q => Q);

    Clk <= not Clk after 50 ns;  -- 100 ns period, rising edges at 50,150,250,...

    process begin
        -- Reset: hold Clr for 2 clock edges
        Clr <= '1'; wait for 110 ns;
        assert Q = "000" report "T1: Q=000 after reset" severity error;
        Clr <= '0';

        D <= "001"; wait for 100 ns;
        assert Q = "001" report "T2: Q=001" severity error;

        D <= "010"; wait for 100 ns;
        assert Q = "010" report "T3: Q=010" severity error;

        D <= "011"; wait for 100 ns;
        assert Q = "011" report "T4: Q=011" severity error;

        -- Clear mid-run
        Clr <= '1'; wait for 100 ns;
        assert Q = "000" report "T5: Q=000 after mid-clear" severity error;
        Clr <= '0';

        D <= "101"; wait for 100 ns;
        assert Q = "101" report "T6: Q=101" severity error;

        D <= "110"; wait for 100 ns;
        assert Q = "110" report "T7: Q=110" severity error;

        D <= "111"; wait for 100 ns;
        assert Q = "111" report "T8: Q=111" severity error;

        assert false report "TB_Program_Counter: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
