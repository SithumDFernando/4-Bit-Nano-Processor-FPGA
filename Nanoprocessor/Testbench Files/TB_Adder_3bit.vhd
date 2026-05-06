library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Adder_3bit is
end TB_Adder_3bit;

architecture Behavioral of TB_Adder_3bit is
    signal A, S : std_logic_vector(2 downto 0) := "000";
    signal carry : std_logic;
begin
    UUT : entity work.ADDER_3 port map (A => A, S => S, carry => carry);

    process begin
        A <= "000"; wait for 50 ns;
        assert S = "001" report "T1: 0+1=1" severity error;
        assert carry = '0' report "T1: no carry" severity error;

        A <= "001"; wait for 50 ns;
        assert S = "010" report "T2: 1+1=2" severity error;

        A <= "011"; wait for 50 ns;
        assert S = "100" report "T3: 3+1=4" severity error;

        A <= "101"; wait for 50 ns;
        assert S = "110" report "T4: 5+1=6" severity error;

        A <= "110"; wait for 50 ns;
        assert S = "111" report "T5: 6+1=7" severity error;

        -- Wrap: 7+1 = 0 with carry
        A <= "111"; wait for 50 ns;
        assert S = "000" report "T6: 7+1 wraps to 000" severity error;
        assert carry = '1' report "T6: carry should be 1" severity error;

        assert false report "TB_Adder_3bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
