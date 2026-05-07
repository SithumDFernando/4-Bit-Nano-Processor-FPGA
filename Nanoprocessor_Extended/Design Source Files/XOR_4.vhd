library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity XOR_4 is
    Port ( A : in STD_LOGIC_VECTOR (3 downto 0);
           B : in STD_LOGIC_VECTOR (3 downto 0);
           Y : out STD_LOGIC_VECTOR (3 downto 0));
end XOR_4;

architecture Behavioral of XOR_4 is
begin
    Y <= A xor B;
end Behavioral;
