library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimizations vs original:
-- 1. Added CLK_DIV_MAX generic: testbenches can override with
--    generic map(CLK_DIV_MAX => 4) without editing source.
--    Default 50_000_000 → toggles every 500 ms → 1 Hz slow clock on board.
-- 2. Fixed count initialisation bug: original set count := 1 and reset to 1,
--    so the comparator (count = 1) fired on the very first clock edge,
--    producing double-speed toggling. Now starts and resets at 0.
-- 3. Moved Clk_out outside the process as a concurrent assignment: original
--    only drove Clk_out on the count = N branch, which caused Vivado to infer
--    an unintended latch and generate a warning.
entity SLOW_CLK is
    generic (CLK_DIV_MAX : integer := 50_000_000);
    Port ( Clk_in  : in  STD_LOGIC;
           Clk_out : out STD_LOGIC);
end SLOW_CLK;

architecture Behavioral of SLOW_CLK is
    signal count      : integer range 0 to CLK_DIV_MAX - 1 := 0;
    signal clk_status : std_logic := '0';
begin
    process (Clk_in) begin
        if rising_edge(Clk_in) then
            if count = CLK_DIV_MAX - 1 then
                clk_status <= not clk_status;
                count <= 0;
            else
                count <= count + 1;
            end if;
        end if;
    end process;

    Clk_out <= clk_status;
end Behavioral;
