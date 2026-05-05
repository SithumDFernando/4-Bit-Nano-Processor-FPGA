library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Optimization: changed `signal ROM` to `constant MEM`.
-- A signal initialiser on an array infers a register array (flip-flops);
-- a constant tells Vivado this is read-only, mapping directly to a
-- distributed ROM in the LUT fabric — cheaper and faster.
-- Removed the commented-out countdown program to reduce noise.
--
-- Program: sum 3+2+1 = 6, result in R7.
-- ISA encoding (12 bits):  MOVI R,d = 10 RRR 0000 dddd
--                          ADD Ra,Rb= 00 Ra  Rb   0000
--                          NEG R    = 01 RRR 000000000
--                          JZR R,d  = 11 RRR 0000 0ddd
entity ROM is
    Port ( S : in  STD_LOGIC_VECTOR (2 downto 0);
           Q : out STD_LOGIC_VECTOR (11 downto 0));
end ROM;

architecture Behavioral of ROM is
    type rom_type is array (0 to 7) of std_logic_vector(11 downto 0);
    constant MEM : rom_type := (
        "100010000011",  -- 0: MOVI R1, 3
        "100100000001",  -- 1: MOVI R2, 1
        "010100000000",  -- 2: NEG  R2        (R2 = -1)
        "001110010000",  -- 3: ADD  R7, R1    (R7 += R1)
        "000010100000",  -- 4: ADD  R1, R2    (R1 -= 1)
        "110010000111",  -- 5: JZR  R1, 7     (if R1=0 goto 7)
        "110000000011",  -- 6: JZR  R0, 3     (always goto 3)
        "110000000111"   -- 7: JZR  R0, 7     (halt)
    );
begin
    Q <= MEM(to_integer(unsigned(S)));
end Behavioral;
