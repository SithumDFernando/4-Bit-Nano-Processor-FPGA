library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Optimizations vs original:
-- 1. Replaced 3-level component hierarchy (DEC_3_8 → REG_4 → D_FFwithEN × 28)
--    with a single behavioural process using a reg_file_t array
-- 2. Vivado infers the same 7 × 4-bit FDRE primitives directly, enabling
--    automatic retiming and SRL optimizations
-- 3. R0 is permanently "0000" — no flip-flop allocated
-- 4. DEC_3_8, DEC_2_4, REG_4, D_FFwithEN components eliminated
entity REG_BANK is
    Port ( D   : in  STD_LOGIC_VECTOR (3 downto 0);
           Clk : in  STD_LOGIC;
           I   : in  STD_LOGIC_VECTOR (2 downto 0);
           Clr : in  STD_LOGIC;
           R1  : out STD_LOGIC_VECTOR (3 downto 0);
           R2  : out STD_LOGIC_VECTOR (3 downto 0);
           R3  : out STD_LOGIC_VECTOR (3 downto 0);
           R4  : out STD_LOGIC_VECTOR (3 downto 0);
           R5  : out STD_LOGIC_VECTOR (3 downto 0);
           R6  : out STD_LOGIC_VECTOR (3 downto 0);
           R7  : out STD_LOGIC_VECTOR (3 downto 0);
           R0  : out STD_LOGIC_VECTOR (3 downto 0));
end REG_BANK;

architecture Behavioral of REG_BANK is
    type reg_file_t is array (1 to 7) of std_logic_vector(3 downto 0);
    signal regs : reg_file_t := (others => (others => '0'));
begin
    R0 <= "0000";   -- R0 hardwired to zero, no FF

    process (Clk) begin
        if rising_edge(Clk) then
            if Clr = '1' then
                regs <= (others => (others => '0'));
            elsif unsigned(I) /= 0 then
                regs(to_integer(unsigned(I))) <= D;
            end if;
        end if;
    end process;

    R1 <= regs(1);  R2 <= regs(2);  R3 <= regs(3);  R4 <= regs(4);
    R5 <= regs(5);  R6 <= regs(6);  R7 <= regs(7);
end Behavioral;
