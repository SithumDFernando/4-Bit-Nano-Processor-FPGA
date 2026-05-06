library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Mux_2_to_1_4bit is
end TB_Mux_2_to_1_4bit;

architecture Behavioral of TB_Mux_2_to_1_4bit is
    signal A, B, Q : std_logic_vector(3 downto 0) := "0000";
    signal S : std_logic := '0';
begin
    UUT : entity work.MUX_2_1_4B port map (A => A, B => B, S => S, Q => Q);

    process begin
        A <= "1010"; B <= "0101"; S <= '0'; wait for 50 ns;
        assert Q = "1010" report "T1: S=0 selects A" severity error;

        S <= '1'; wait for 50 ns;
        assert Q = "0101" report "T2: S=1 selects B" severity error;

        A <= "1100"; B <= "0011"; S <= '0'; wait for 50 ns;
        assert Q = "1100" report "T3: S=0 selects A" severity error;

        S <= '1'; wait for 50 ns;
        assert Q = "0011" report "T4: S=1 selects B" severity error;

        A <= "1111"; B <= "0000"; S <= '0'; wait for 50 ns;
        assert Q = "1111" report "T5: S=0 selects A=1111" severity error;

        S <= '1'; wait for 50 ns;
        assert Q = "0000" report "T6: S=1 selects B=0000" severity error;

        assert false report "TB_Mux_2_to_1_4bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
