library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.Numeric_std.all;

entity TB_Mux_8_to_1_4bit is
--  Port ( );
end TB_Mux_8_to_1_4bit;

architecture Behavioral of TB_Mux_8_to_1_4bit is
    component MUX_8_1_4B is
        Port ( S : in STD_LOGIC_VECTOR (2 downto 0);
               R0 : in STD_LOGIC_VECTOR (3 downto 0);
               R1 : in STD_LOGIC_VECTOR (3 downto 0);
               R2 : in STD_LOGIC_VECTOR (3 downto 0);
               R3 : in STD_LOGIC_VECTOR (3 downto 0);
               R4 : in STD_LOGIC_VECTOR (3 downto 0);
               R5 : in STD_LOGIC_VECTOR (3 downto 0);
               R6 : in STD_LOGIC_VECTOR (3 downto 0);
               R7 : in STD_LOGIC_VECTOR (3 downto 0);
               Q : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    signal S : std_logic_vector(2 downto 0);
    signal Q,R0,R1,R2,R3,R4,R5,R6,R7 : std_logic_vector (3 downto 0);

begin
    uut: MUX_8_1_4B port map(
        S => S,
        R0 => R0,
        R1 => R1,
        R2 => R2,
        R3 => R3,
        R4 => R4,
        R5 => R5,
        R6 => R6,
        R7 => R7,
        Q => Q);
    process
    begin
        R0 <= "0000";
        R1 <= "0001";
        R2 <= "0010";
        R3 <= "0011";
        R4 <= "0100";
        R5 <= "0101";
        R6 <= "0110";
        R7 <= "0111";
        for i in 0 to 8 loop
            S <= std_logic_vector(to_unsigned(i,3));
            wait for 100ns;
        end loop;
        wait;
    end process;
end Behavioral;
