library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_LUT_7SEG is
end TB_LUT_7SEG;

architecture Behavioral of TB_LUT_7SEG is
    signal address : std_logic_vector(3 downto 0) := "0000";
    signal data    : std_logic_vector(6 downto 0);

    type seg_rom_t is array (0 to 15) of std_logic_vector(6 downto 0);
    constant EXPECTED : seg_rom_t := (
        "1000000", "1111001", "0100100", "0110000",
        "0011001", "0010010", "0000010", "1111000",
        "0000000", "0010000", "0001000", "0000011",
        "1000110", "0100001", "0000110", "0001110");
begin
    UUT : entity work.LUT_7_SEG port map (address => address, data => data);

    process begin
        for i in 0 to 15 loop
            address <= std_logic_vector(to_unsigned(i, 4));
            wait for 50 ns;
            assert data = EXPECTED(i)
                report "LUT_7SEG mismatch at addr=" & integer'image(i)
                severity error;
        end loop;

        -- Spot-check: digit 6 (expected result of demo program)
        address <= "0110"; wait for 50 ns;
        assert data = "0000010" report "Spot: digit 6 = 0000010" severity error;

        assert false report "TB_LUT_7SEG: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
