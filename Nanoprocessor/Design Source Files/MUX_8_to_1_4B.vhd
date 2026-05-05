library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimization: removed DEC_3_8 component instance and 4 x 8-input OR trees
-- (~6 LUT levels). Replaced with a single with/select statement that Vivado
-- maps to a 2-LUT-level mux tree on Artix-7.
entity MUX_8_1_4B is
    Port ( S  : in  STD_LOGIC_VECTOR (2 downto 0);
           R0 : in  STD_LOGIC_VECTOR (3 downto 0);
           R1 : in  STD_LOGIC_VECTOR (3 downto 0);
           R2 : in  STD_LOGIC_VECTOR (3 downto 0);
           R3 : in  STD_LOGIC_VECTOR (3 downto 0);
           R4 : in  STD_LOGIC_VECTOR (3 downto 0);
           R5 : in  STD_LOGIC_VECTOR (3 downto 0);
           R6 : in  STD_LOGIC_VECTOR (3 downto 0);
           R7 : in  STD_LOGIC_VECTOR (3 downto 0);
           Q  : out STD_LOGIC_VECTOR (3 downto 0));
end MUX_8_1_4B;

architecture Behavioral of MUX_8_1_4B is
begin
    with S select Q <=
        R0 when "000",
        R1 when "001",
        R2 when "010",
        R3 when "011",
        R4 when "100",
        R5 when "101",
        R6 when "110",
        R7 when others;
end Behavioral;
