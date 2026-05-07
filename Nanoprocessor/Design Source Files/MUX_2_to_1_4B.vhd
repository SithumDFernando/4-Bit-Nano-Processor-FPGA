library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity MUX_2_1_4B is
    Port ( A : in STD_LOGIC_VECTOR (3 downto 0);
           B : in STD_LOGIC_VECTOR (3 downto 0);
           S : in STD_LOGIC;
           Q : out STD_LOGIC_VECTOR (3 downto 0));
end MUX_2_1_4B;

architecture Behavioral of MUX_2_1_4B is
begin
    -- Replaced 4x(NOT+AND+AND+OR) bit-slice logic with a single conditional.
    -- Synthesiser maps to FPGA MUX primitives; eliminates the repeated NOT S inversion.
    Q <= B when S = '1' else A;
end Behavioral;
