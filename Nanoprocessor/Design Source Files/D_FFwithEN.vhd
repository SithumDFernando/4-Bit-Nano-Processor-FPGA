library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity D_FFwithEN is
    Port ( D   : in  STD_LOGIC;
           Res : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
           EN  : in  STD_LOGIC;
           Q   : out STD_LOGIC);
end D_FFwithEN;

-- Qbar removed: REG_4 never connects it, so Vivado was synthesising a
-- dead NOT gate per flip-flop (28 wasted gates across 7 registers × 4 bits).
architecture Behavioral of D_FFwithEN is
begin
    process (Clk) begin
        if rising_edge(Clk) then
            if Res = '1' then
                Q <= '0';
            elsif EN = '1' then
                Q <= D;
            end if;
        end if;
    end process;
end Behavioral;