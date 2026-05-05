library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimization: removed 4 dead signal declarations (FA0_S, FA1_S, FA2_S, FA3_S)
-- that were declared but never read — the FA S outputs were already wired directly
-- to port S(). Only the carry-chain signals FA0_C..FA2_C and final C_out are kept.
-- overflow = FA2_C xor C_out  (carry into sign bit differs from carry out of it).
entity ADD_SUB_4 is
    Port ( A        : in  STD_LOGIC_VECTOR (3 downto 0);
           B        : in  STD_LOGIC_VECTOR (3 downto 0);
           S        : out STD_LOGIC_VECTOR (3 downto 0);
           M        : in  STD_LOGIC;
           overflow : out STD_LOGIC);
end ADD_SUB_4;

architecture Behavioral of ADD_SUB_4 is
    component FA
        port (A, B, C_in : in std_logic; S, C_out : out std_logic);
    end component;

    signal FA0_C, FA1_C, FA2_C, C_out : std_logic;
    signal B0x, B1x, B2x, B3x         : std_logic;
begin
    B0x <= B(0) xor M;
    B1x <= B(1) xor M;
    B2x <= B(2) xor M;
    B3x <= B(3) xor M;

    FA_0 : FA port map (A => A(0), B => B0x, C_in => M,    S => S(0), C_out => FA0_C);
    FA_1 : FA port map (A => A(1), B => B1x, C_in => FA0_C, S => S(1), C_out => FA1_C);
    FA_2 : FA port map (A => A(2), B => B2x, C_in => FA1_C, S => S(2), C_out => FA2_C);
    FA_3 : FA port map (A => A(3), B => B3x, C_in => FA2_C, S => S(3), C_out => C_out);

    overflow <= FA2_C xor C_out;
end Behavioral;
