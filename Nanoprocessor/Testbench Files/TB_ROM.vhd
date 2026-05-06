library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_ROM is
end TB_ROM;

architecture Behavioral of TB_ROM is
    signal S : std_logic_vector(2 downto 0) := "000";
    signal Q : std_logic_vector(11 downto 0);
begin
    UUT : entity work.ROM port map (S => S, Q => Q);

    process begin
        -- Scan all 8 addresses
        for i in 0 to 7 loop
            S <= std_logic_vector(to_unsigned(i, 3));
            wait for 50 ns;
        end loop;

        -- 0: MOVI R1, 3  → 10 001 0000 0011
        S <= "000"; wait for 50 ns;
        assert Q = "100010000011" report "ROM[0] mismatch" severity error;

        -- 1: MOVI R2, 1  → 10 010 0000 0001
        S <= "001"; wait for 50 ns;
        assert Q = "100100000001" report "ROM[1] mismatch" severity error;

        -- 2: NEG R2       → 01 010 000000000
        S <= "010"; wait for 50 ns;
        assert Q = "010100000000" report "ROM[2] mismatch" severity error;

        -- 3: ADD R7, R1   → 00 111 001 0000
        S <= "011"; wait for 50 ns;
        assert Q = "001110010000" report "ROM[3] mismatch" severity error;

        -- 5: JZR R1, 7   → 11 001 0000 0111
        S <= "101"; wait for 50 ns;
        assert Q = "110010000111" report "ROM[5] mismatch" severity error;

        -- 7: JZR R0, 7   → 11 000 0000 0111 (halt)
        S <= "111"; wait for 50 ns;
        assert Q = "110000000111" report "ROM[7] mismatch" severity error;

        assert false report "TB_ROM: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
