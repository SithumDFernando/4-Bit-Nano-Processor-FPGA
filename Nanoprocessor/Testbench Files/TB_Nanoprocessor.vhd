library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Full-system testbench.
-- CLK_DIV_MAX => 4: slow_clk period = 2 * 4 * 10 ns = 80 ns.
-- Program (3+2+1=6) completes in 14 slow_clk cycles ≈ 1120 ns.
-- We wait 3000 ns then assert R7 = "0110".
entity TB_Nanoprocessor is
end TB_Nanoprocessor;

architecture Behavioral of TB_Nanoprocessor is
    signal Clr       : std_logic := '1';
    signal Clk       : std_logic := '0';
    signal R         : std_logic_vector(3 downto 0);
    signal Overflow  : std_logic;
    signal Zero      : std_logic;
    signal Seven_Seg : std_logic_vector(6 downto 0);
    signal AN        : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 10 ns;
begin
    UUT : entity work.NANOPROCESSOR
        generic map (CLK_DIV_MAX => 4)
        port map (Clr       => Clr,
                  Clk       => Clk,
                  R         => R,
                  Overflow  => Overflow,
                  Zero      => Zero,
                  Seven_Seg => Seven_Seg,
                  AN        => AN);

    Clk <= not Clk after CLK_PERIOD / 2;

    process begin
        -- Hold reset for 2 full slow_clk periods (160 ns) to ensure
        -- at least one rising slow_clk edge sees Clr='1'.
        Clr <= '1'; wait for 160 ns;
        Clr <= '0';

        -- Wait for countdown loop to complete with margin
        wait for 3000 ns;

        -- R7 = 3+2+1 = 6
        assert R = "0110"
            report "FAIL: R7 expected 0110 (6), got " &
                   integer'image(to_integer(unsigned(R)))
            severity error;

        -- Only rightmost 7-seg digit enabled
        assert AN = "1110"
            report "FAIL: AN should be 1110" severity error;

        -- 7-seg for '6': CG=0,CF=0,CE=0,CD=0,CC=0,CB=1,CA=0 = "0000010"
        assert Seven_Seg = "0000010"
            report "FAIL: Seven_Seg for 6 should be 0000010" severity error;

        assert false report "TB_Nanoprocessor: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
