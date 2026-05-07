library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ADDER_3 is
    Port (  A : in STD_LOGIC_VECTOR (2 downto 0); 
            S : out STD_LOGIC_VECTOR(2 downto 0);
            carry : out STD_LOGIC); 
end ADDER_3;

architecture Behavioral of ADDER_3 is
begin
    -- Dedicated +1 incrementer: A XOR 001 through a carry chain.
    -- Replaces 3 full adders (15 gates) with 5 gates.
    S(0)  <= NOT A(0);                   -- bit 0 always flips
    S(1)  <= A(1) XOR A(0);             -- half-adder sum
    S(2)  <= A(2) XOR (A(1) AND A(0));  -- half-adder sum with carry
    carry <= A(2) AND A(1) AND A(0);    -- carry out only when all bits were '1'
end Behavioral;
