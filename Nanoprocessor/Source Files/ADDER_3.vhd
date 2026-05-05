library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimization: removed 6 dead signal declarations (FA0_S, FA1_S, FA2_S,
-- FA2_C, FA3_S, FA3_C) that were declared but never driven or read.
-- Only the two carry-chain signals FA0_C and FA1_C are actually needed.
entity ADDER_3 is
    Port ( A     : in  STD_LOGIC_VECTOR (2 downto 0);
           S     : out STD_LOGIC_VECTOR (2 downto 0);
           carry : out STD_LOGIC);
end ADDER_3;

architecture Behavioral of ADDER_3 is
    component FA
        port (A, B, C_in : in std_logic; S, C_out : out std_logic);
    end component;

    signal FA0_C, FA1_C : std_logic;
begin
    FA_0 : FA port map (A => A(0), B => '1', C_in => '0',   S => S(0), C_out => FA0_C);
    FA_1 : FA port map (A => A(1), B => '0', C_in => FA0_C, S => S(1), C_out => FA1_C);
    FA_2 : FA port map (A => A(2), B => '0', C_in => FA1_C, S => S(2), C_out => carry);
end Behavioral;
