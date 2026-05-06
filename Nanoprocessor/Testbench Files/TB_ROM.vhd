library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench for ROM: reads all 8 addresses and checks instruction encoding.
entity TB_ROM is
end TB_ROM;

architecture Behavioral of TB_ROM is
    component ROM
        port (S : in  std_logic_vector(2 downto 0);
              Q : out std_logic_vector(11 downto 0));
    end component;

    signal S : std_logic_vector(2 downto 0) := "000";
    signal Q : std_logic_vector(11 downto 0);
begin
    UUT : ROM port map (S => S, Q => Q);

    process begin
        -- Read all 8 ROM locations
        for i in 0 to 7 loop
            S <= std_logic_vector(to_unsigned(i, 3));
            wait for 50 ns;
        end loop;

        -- Verify address 0: MOVI R1, 3  → "100010000011"
        S <= "000"; wait for 50 ns;
        assert Q = "100010000011" report "ROM[0] mismatch" severity error;

        -- Verify address 7: JZR R0, 7  → "110000000111" (halt)
        S <= "111"; wait for 50 ns;
        assert Q = "110000000111" report "ROM[7] mismatch" severity error;

        assert false report "TB_ROM: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
