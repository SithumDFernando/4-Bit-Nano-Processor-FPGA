library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_2_1_3B is
    Port ( A : in STD_LOGIC_VECTOR (2 downto 0);
           B : in STD_LOGIC_VECTOR (2 downto 0);
           S : in STD_LOGIC;
           Q : out STD_LOGIC_VECTOR (2 downto 0));
end MUX_2_1_3B;

architecture Behavioral of MUX_2_1_3B is
    
begin
    Q(0) <= (A(0) AND NOT(S)) OR (B(0) AND S);
    Q(1) <= (A(1) AND NOT(S)) OR (B(1) AND S);
    Q(2) <= (A(2) AND NOT(S)) OR (B(2) AND S);
end Behavioral;
