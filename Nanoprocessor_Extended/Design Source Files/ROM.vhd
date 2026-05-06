library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ROM is
    Port ( S : in STD_LOGIC_VECTOR (2 downto 0);
           Q : out STD_LOGIC_VECTOR (13 downto 0));
end ROM;

architecture Behavioral of ROM is
    type rom_type is array (0 to 7) of std_logic_vector(13 downto 0);
        signal ROM  : rom_type := (
-------------- Countdown from 7 to 1.---------------------------
--            "00100010000111", -- MOVI R1, 111 (0010 001 000 0111)
--            "00100100000001", -- MOVI R2, 1   (0010 010 000 0001)
--            "00010100000000", -- NEG R2        (0001 010 000 0000)
--            "00000010100000", -- ADD R1, R2    (0000 001 010 0000)
--            "00110010000111", -- JZR R1, 7     (0011 001 000 0111)
--            "111110000011",    -- (Original invalid instruction length snippet)
--            "00110000000111", -- JZR R0, 7     (0011 000 000 0111)
--            "00110000000111"  -- JZR R0, 7     (0011 000 000 0111)
--            );

--------------- Add numbers from 3 to 1-----------------------------
              "00100010000011", -- MOVI R1, 3 (0010 001 000 0011)
              "00100100000001", -- MOVI R2, 1 (0010 010 000 0001)
              "00010100000000", -- NEG R2      (0001 010 000 0000)
              "00001110010000", -- ADD R7, R1  (0000 111 001 0000)   
              "00000010100000", -- ADD R1, R2  (0000 001 010 0000)
              "00110010000111", -- JZR R1, 7   (0011 001 000 0111)
              "00110000000011", -- JZR R0, 3   (0011 000 000 0011)
              "00110000000111"  -- JZR R0, 7   (0011 000 000 0111)
              );
begin
    Q <= ROM(to_integer(unsigned(S)));
end Behavioral;
