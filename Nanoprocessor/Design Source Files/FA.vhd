library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FA is
    Port ( A : in STD_LOGIC;
           B : in STD_LOGIC;
           C_in : in STD_LOGIC;
           S : out STD_LOGIC;
           C_out : out STD_LOGIC);
end FA;

architecture Behavioral of FA is
begin
    -- Direct SOP equations remove the HA hierarchy so Vivado can infer
    -- CARRY4 primitives across the ADD_SUB_4 carry chain.
    -- G = A AND B (carry generate), P = A XOR B (carry propagate)
    S     <= A XOR B XOR C_in;
    C_out <= (A AND B) OR (C_in AND (A XOR B));
end Behavioral;
