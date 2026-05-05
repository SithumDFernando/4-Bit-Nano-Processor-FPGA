library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimization: replaced two HA component instances and four intermediate signals
-- (HA0_S, HA0_C, HA1_S, HA1_C) with direct XOR/AND equations.
-- Vivado folds both into a single LUT4 carry-chain entry — one logic level
-- instead of two, and removes the HA component hierarchy overhead.
entity FA is
    Port ( A     : in  STD_LOGIC;
           B     : in  STD_LOGIC;
           C_in  : in  STD_LOGIC;
           S     : out STD_LOGIC;
           C_out : out STD_LOGIC);
end FA;

architecture Behavioral of FA is
begin
    S     <= A xor B xor C_in;
    C_out <= (A and B) or (C_in and (A xor B));
end Behavioral;
