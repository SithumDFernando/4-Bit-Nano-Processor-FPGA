library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_Mux_8_to_1_4bit is
end TB_Mux_8_to_1_4bit;

architecture Behavioral of TB_Mux_8_to_1_4bit is
    signal S              : std_logic_vector(2 downto 0) := "000";
    signal Q              : std_logic_vector(3 downto 0);
    signal R0, R1, R2, R3 : std_logic_vector(3 downto 0);
    signal R4, R5, R6, R7 : std_logic_vector(3 downto 0);
begin
    UUT : entity work.MUX_8_1_4B
        port map (S => S,
                  R0 => R0, R1 => R1, R2 => R2, R3 => R3,
                  R4 => R4, R5 => R5, R6 => R6, R7 => R7,
                  Q  => Q);

    process begin
        -- Each input gets a unique 4-bit value equal to its index
        R0 <= "0000"; R1 <= "0001"; R2 <= "0010"; R3 <= "0011";
        R4 <= "0100"; R5 <= "0101"; R6 <= "0110"; R7 <= "0111";

        for i in 0 to 7 loop
            S <= std_logic_vector(to_unsigned(i, 3));
            wait for 50 ns;
            assert Q = std_logic_vector(to_unsigned(i, 4))
                report "MUX8: mismatch at S=" & integer'image(i)
                severity error;
        end loop;

        assert false report "TB_Mux_8_to_1_4bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
