library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Slow_Clk is
--  Port ( );
end TB_Slow_Clk;

architecture Behavioral of TB_Slow_Clk is
    component SLOW_CLK is
        Port ( Clk_in  : in  STD_LOGIC;
               Clk_out : out STD_LOGIC);
    end component;

    signal Clk_in  : STD_LOGIC := '0';
    signal Clk_out : STD_LOGIC;

    -- Fast input clock period: 10 ns  (100 MHz)
    constant CLK_PERIOD : time := 40 ns;

begin
    -- Instantiate the Unit Under Test
    uut : SLOW_CLK
        port map (
            Clk_in  => Clk_in,
            Clk_out => Clk_out);

    -- Generate a continuous fast clock
    process
    begin
        Clk_in <= '0';
        wait for CLK_PERIOD / 2;
        Clk_in <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Stimulus: run for enough cycles to observe several Clk_out toggles.
    -- In simulation mode (count = 1), Clk_out toggles on every rising edge
    -- of Clk_in, so each period of Clk_out = 2 x CLK_PERIOD = 20 ns.
    -- We let the simulation run for 20 input cycles to see ~10 output toggles.
    process
    begin
        wait for CLK_PERIOD * 20;
        -- Simulation ends after 20 fast-clock cycles (200 ns)
        wait;
    end process;

end Behavioral;
