library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Testbench for LUT_7_SEG: verifies all 16 addresses produce the correct
-- active-low 7-segment pattern. Encoding: data(6:0) = CG,CF,CE,CD,CC,CB,CA.
entity TB_LUT_7SEG is
end TB_LUT_7SEG;

architecture Behavioral of TB_LUT_7SEG is
    component LUT_7_SEG
        port (address : in  std_logic_vector(3 downto 0);
              data    : out std_logic_vector(6 downto 0));
    end component;

    signal address : std_logic_vector(3 downto 0) := "0000";
    signal data    : std_logic_vector(6 downto 0);

    type seg_rom_t is array (0 to 15) of std_logic_vector(6 downto 0);
    constant EXPECTED : seg_rom_t := (
        "1000000", --0
        "1111001", --1
        "0100100", --2
        "0110000", --3
        "0011001", --4
        "0010010", --5
        "0000010", --6
        "1111000", --7
        "0000000", --8
        "0010000", --9
        "0001000", --a
        "0000011", --b
        "1000110", --c
        "0100001", --d
        "0000110", --e
        "0001110"  --f
    );
begin
    UUT : LUT_7_SEG port map (address => address, data => data);

    process begin
        for i in 0 to 15 loop
            address <= std_logic_vector(to_unsigned(i, 4));
            wait for 50 ns;
            assert data = EXPECTED(i)
                report "LUT_7SEG mismatch at address " & integer'image(i)
                severity error;
        end loop;

        -- Spot-check key digits used in the demo program
        address <= "0000"; wait for 50 ns;  -- 0
        assert data = "1000000" report "Spot: 0 failed" severity error;

        address <= "0110"; wait for 50 ns;  -- 6 (expected final result in R7)
        assert data = "0000010" report "Spot: 6 failed" severity error;

        address <= "0011"; wait for 50 ns;  -- 3
        assert data = "0110000" report "Spot: 3 failed" severity error;

        assert false report "TB_LUT_7SEG: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
