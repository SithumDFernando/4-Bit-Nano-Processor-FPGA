library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Mux_2_to_1_3bit is
end TB_Mux_2_to_1_3bit;

architecture Behavioral of TB_Mux_2_to_1_3bit is
    signal A, B, Q : std_logic_vector(2 downto 0) := "000";
    signal S : std_logic := '0';
begin
    UUT : entity work.MUX_2_1_3B port map (A => A, B => B, S => S, Q => Q);

    process begin
        A <= "010"; B <= "101"; S <= '0'; wait for 50 ns;
        assert Q = "010" report "T1: S=0 selects A" severity error;

        S <= '1'; wait for 50 ns;
        assert Q = "101" report "T2: S=1 selects B" severity error;

        A <= "110"; B <= "011"; S <= '0'; wait for 50 ns;
        assert Q = "110" report "T3: S=0 selects A" severity error;

        S <= '1'; wait for 50 ns;
        assert Q = "011" report "T4: S=1 selects B" severity error;

        A <= "111"; B <= "000"; S <= '0'; wait for 50 ns;
        assert Q = "111" report "T5: S=0 selects A=111" severity error;

        S <= '1'; wait for 50 ns;
        assert Q = "000" report "T6: S=1 selects B=000" severity error;

        assert false report "TB_Mux_2_to_1_3bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
