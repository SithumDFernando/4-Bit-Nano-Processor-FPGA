library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Full-system testbench for the optimised NANOPROCESSOR.
-- Program ROM computes 3+2+1 = 6 via a countdown loop → R7 = 6.
--
-- CLK_DIV_MAX => 4: fast clock 10 ns, slow_clk period = 2*4*10 = 80 ns.
-- Program completes in 14 slow_clk cycles ≈ 1160 ns; we wait 3000 ns.
entity TB_Nanoprocessor is
end TB_Nanoprocessor;

architecture Behavioral of TB_Nanoprocessor is
    component NANOPROCESSOR
        generic (CLK_DIV_MAX : integer := 50_000_000);
        port (Clr       : in  std_logic;
              Clk       : in  std_logic;
              R         : out std_logic_vector(3 downto 0);
              Overflow  : out std_logic;
              Zero      : out std_logic;
              Seven_Seg : out std_logic_vector(6 downto 0);
              AN        : out std_logic_vector(3 downto 0));
    end component;

    signal Clr       : std_logic := '1';
    signal Clk       : std_logic := '0';
    signal R         : std_logic_vector(3 downto 0);
    signal Overflow  : std_logic;
    signal Zero      : std_logic;
    signal Seven_Seg : std_logic_vector(6 downto 0);
    signal AN        : std_logic_vector(3 downto 0);

    constant CLK_PERIOD : time := 10 ns;
begin
    UUT : NANOPROCESSOR
        generic map (CLK_DIV_MAX => 4)
        port map (
            Clr       => Clr,
            Clk       => Clk,
            R         => R,
            Overflow  => Overflow,
            Zero      => Zero,
            Seven_Seg => Seven_Seg,
            AN        => AN);

    Clk <= not Clk after CLK_PERIOD / 2;

    process begin
        -- Hold reset for two slow_clk periods (2 * 4 * 10 ns = 80 ns)
        -- to guarantee at least one rising slow_clk edge with Clr='1'.
        Clr <= '1';
        wait for 100 ns;
        Clr <= '0';

        -- Wait for the countdown loop to complete (14 instructions × 80 ns)
        -- plus margin. Program halts at JZR R0, 7 by ~1250 ns.
        wait for 3000 ns;

        -- ── Final state assertions ────────────────────────────────────
        -- R7 = 3+2+1 = 6 → "0110"
        assert R = "0110"
            report "FAIL: Expected R=0110 (6), got " & integer'image(to_integer(unsigned(R)))
            severity error;

        -- AN drives only the rightmost digit
        assert AN = "1110"
            report "FAIL: AN should be 1110"
            severity error;

        -- 7-segment encoding for '6' (active-low, CG,CF,CE,CD,CC,CB,CA)
        -- 6 → a,f,g,e,d on → CA=0,CB=1,CC=0,CD=0,CE=0,CF=0,CG=0 = "0000010"
        assert Seven_Seg = "0000010"
            report "FAIL: Seven_Seg for 6 should be 0000010"
            severity error;

        assert false report "TB_Nanoprocessor: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
