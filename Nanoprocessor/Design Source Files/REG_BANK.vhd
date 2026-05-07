library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity REG_BANK is
    Port ( D : in STD_LOGIC_VECTOR (3 downto 0);
           Clk : in STD_LOGIC;
           I : in STD_LOGIC_VECTOR (2 downto 0);
           Clr : in STD_LOGIC;
           R1 : out STD_LOGIC_VECTOR (3 downto 0);
           R2 : out STD_LOGIC_VECTOR (3 downto 0);
           R3 : out STD_LOGIC_VECTOR (3 downto 0);
           R4 : out STD_LOGIC_VECTOR (3 downto 0);
           R5 : out STD_LOGIC_VECTOR (3 downto 0);
           R6 : out STD_LOGIC_VECTOR (3 downto 0);
           R7 : out STD_LOGIC_VECTOR (3 downto 0);
           R0 : out STD_LOGIC_VECTOR (3 downto 0));
end REG_BANK;

architecture Behavioral of REG_BANK is
    component REG_4
        port(
            Clk     : in  std_logic;
            Val     : in  std_logic_vector;
            Sel     : in  std_logic;
            Clr     : in  std_logic;
            Reg_out : out std_logic_vector);
    end component;
    signal Sel : std_logic_vector(7 downto 0);
begin
    -- Replaced cascaded DEC_2_4 + DEC_3_8 hierarchy with a single with/select.
    -- Vivado can now see the full 3-input truth table and pack multiple decode
    -- outputs per 6-LUT using the O5/O6 dual-output feature, saving ~2 LUTs.
    with I select Sel <=
        "00000010" when "001",   -- R1
        "00000100" when "010",   -- R2
        "00001000" when "011",   -- R3
        "00010000" when "100",   -- R4
        "00100000" when "101",   -- R5
        "01000000" when "110",   -- R6
        "10000000" when "111",   -- R7
        "00000001" when others;  -- R0 (never written; R0 is hardwired to "0000")

    R0 <= "0000";
    Register_1 : REG_4 port map(Clk => Clk, Val => D, Sel => Sel(1), Clr => Clr, Reg_out => R1);
    Register_2 : REG_4 port map(Clk => Clk, Val => D, Sel => Sel(2), Clr => Clr, Reg_out => R2);
    Register_3 : REG_4 port map(Clk => Clk, Val => D, Sel => Sel(3), Clr => Clr, Reg_out => R3);
    Register_4 : REG_4 port map(Clk => Clk, Val => D, Sel => Sel(4), Clr => Clr, Reg_out => R4);
    Register_5 : REG_4 port map(Clk => Clk, Val => D, Sel => Sel(5), Clr => Clr, Reg_out => R5);
    Register_6 : REG_4 port map(Clk => Clk, Val => D, Sel => Sel(6), Clr => Clr, Reg_out => R6);
    Register_7 : REG_4 port map(Clk => Clk, Val => D, Sel => Sel(7), Clr => Clr, Reg_out => R7);
end Behavioral;
