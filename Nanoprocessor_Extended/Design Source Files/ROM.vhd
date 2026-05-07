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

-- --------------- Add numbers from 3 to 1-----------------------------
--               "00100010000011", -- MOVI R1, 3 (0010 001 000 0011)
--               "00100100000001", -- MOVI R2, 1 (0010 010 000 0001)
--               "00010100000000", -- NEG R2      (0001 010 000 0000)
--               "00001110010000", -- ADD R7, R1  (0000 111 001 0000)   
--               "00000010100000", -- ADD R1, R2  (0000 001 010 0000)
--               "00110010000111", -- JZR R1, 7   (0011 001 000 0111)
--               "00110000000011", -- JZR R0, 3   (0011 000 000 0011)
--               "00110000000111"  -- JZR R0, 7   (0011 000 000 0111)

        -- Program showcasing all 8 supported opcodes mutating R7 (visible on 7-segment display)
        "00101110000111", -- 0: MOVI R7, 7  (0010 111 000 0111) | R7 = 7
        "00011110000000", -- 1: NEG R7      (0001 111 000 0000) | R7 = -7 (9 in 4-bit)
        "00001111110000", -- 2: ADD R7, R7  (0000 111 111 0000) | R7 = 9 + 9 = 18 -> 2 in 4-bit
        "01001110000000", -- 3: SUB R7, R0  (0100 111 000 0000) | R7 = 2 - 0 = 2
        "01101111110000", -- 4: XOR R7, R7  (0110 111 111 0000) | R7 = 2 XOR 2 = 0
        "01011110000000", -- 5: AND R7, R0  (0101 111 000 0000) | R7 = 0 AND 0 = 0
        "01111110000000", -- 6: CMP R7, R0  (0111 111 000 0000) | Compare R7(0) and R0(0) (Updates flags only)
        "00111110000000"  -- 7: JZR R7, 0   (0011 111 000 0000) | Jump to 0 since R7=0 (Infinite Loop)
              );
begin
    Q <= ROM(to_integer(unsigned(S)));
end Behavioral;
