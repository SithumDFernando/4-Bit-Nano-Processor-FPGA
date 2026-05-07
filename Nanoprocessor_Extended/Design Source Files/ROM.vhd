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

        -- Program showcasing all supported opcodes mutating R7 (visible on 7-segment display)
        "00101110000111", -- 0: MOVI R7, 7  (0010 111 000 0111) | R7 = 7
        "00101100001001", -- 1: MOVI R6, 9  (0010 110 000 1001) | R7 = 7   (R6 = 9)
        "00001111110000", -- 2: ADD R7, R7  (0000 111 111 0000) | R7 = 14  (7 + 7 = 14)
        "01001110000000", -- 3: SUB R7, R0  (0100 111 000 0000) | R7 = 14  (14 - 0 = 14)
        "01101111100000", -- 4: XOR R7, R6  (0110 111 110 0000) | R7 = 7   (14 XOR 9 = 1110 XOR 1001 = 0111 = 7)
        "01011111100000", -- 5: AND R7, R6  (0101 111 110 0000) | R7 = 1   (7 AND 9 = 0111 AND 1001 = 0001 = 1)
        "01111110000000", -- 6: CMP R7, R0  (0111 111 000 0000) | R7 = 1   (Updates flags only)
        "00111110000000"  -- 7: JZR R7, 0   (0011 111 000 0000) | R7 = 1   (No jump since CMP result was non-zero)
              );
begin
    Q <= ROM(to_integer(unsigned(S)));
end Behavioral;
