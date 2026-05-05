library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimization: replaced 3 bitwise AND/OR/NOT expressions with a single
-- with/select concurrent statement — same function, 1 LUT level vs 2.
entity MUX_2_1_3B is
    Port ( A : in  STD_LOGIC_VECTOR (2 downto 0);
           B : in  STD_LOGIC_VECTOR (2 downto 0);
           S : in  STD_LOGIC;
           Q : out STD_LOGIC_VECTOR (2 downto 0));
end MUX_2_1_3B;

architecture Behavioral of MUX_2_1_3B is
begin
    with S select Q <=
        A when '0',
        B when others;
end Behavioral;
