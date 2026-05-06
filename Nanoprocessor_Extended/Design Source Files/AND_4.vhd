library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity AND_4 is
    Port ( A : in STD_LOGIC_VECTOR (3 downto 0);
           B : in STD_LOGIC_VECTOR (3 downto 0);
           Y : out STD_LOGIC_VECTOR (3 downto 0));
end AND_4;

architecture Behavioral of AND_4 is
begin
    Y <= A AND B;
end Behavioral;
