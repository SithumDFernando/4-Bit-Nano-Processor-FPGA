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

        -- Program showcasing all 8 supported opcodes across different registers
        "00100100000011", -- 0: MOVI R2, 3  (0010 010 000 0011) | R2 = 3
        "00010100000000", -- 1: NEG R2      (0001 010 000 0000) | R2 = -3 (13 in 4-bit)
        "00000110100000", -- 2: ADD R3, R2  (0000 011 010 0000) | R3 = R3(0) + 13 = 13
        "01001000100000", -- 3: SUB R4, R2  (0100 100 010 0000) | R4 = R4(0) - 13 = 3
        "01101011000000", -- 4: XOR R5, R4  (0110 101 100 0000) | R5 = R5(0) XOR 3 = 3
        "01011010000000", -- 5: AND R5, R0  (0101 101 000 0000) | R5 = 3 AND 0 = 0
        "01110111000000", -- 6: CMP R3, R4  (0111 011 100 0000) | Compare R3(13) and R4(3) (Updates flags only)
        "00111010000000"  -- 7: JZR R5, 0   (0011 101 000 0000) | Jump to 0 since R5=0 (Infinite Loop)
              );
begin
    Q <= ROM(to_integer(unsigned(S)));
end Behavioral;
