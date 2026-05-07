library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Instruction_Decoder is
--  Port ( );
end TB_Instruction_Decoder;

architecture Behavioral of TB_Instruction_Decoder is
    component Instruction_Decoder is
        Port (  Inst : in std_logic_vector (13 downto 0);
--                Clk : in std_logic;
                Reg : in std_logic_vector (3 downto 0);
                LSB : out std_logic_vector (3 downto 0);
                Reg_EN : out std_logic_vector (2 downto 0);
                Mux_A : out std_logic_vector (2 downto 0);
                LD : out std_logic;
                Mux_B : out std_logic_vector (2 downto 0);
                Sub : out std_logic;
                Logic_Sel : out std_logic;
                JMP : out std_logic);
    end component;
    signal Inst : std_logic_vector (13 downto 0);
    signal LD, Sub, JMP, Logic_Sel : std_logic; 
    signal Reg, LSB : std_logic_vector (3 downto 0);
    signal Mux_A, Mux_B, Reg_EN : std_logic_vector (2 downto 0);

begin
    uut: Instruction_Decoder port map(
        Inst => Inst,
        Reg => Reg,
        LSB => LSB,
        Reg_EN => Reg_EN,
        Mux_A => Mux_A,
        LD => LD,
        Mux_B => Mux_B,
        Sub => Sub,
        Logic_Sel => Logic_Sel,
        JMP => JMP);

    process
    begin
        wait for 5ns;
        Reg <= "0000";
        Inst <= "00100010000010"; -- MOVI R1, 2
        wait for 80ns;
        Inst <= "00100100000001"; -- MOVI R2, 1
        wait for 80ns;
        Inst <= "00010100000000"; -- NEG R2
        wait for 80ns;
        Inst <= "00000010100000"; -- ADD R1, R2
        wait for 80ns;
        Inst <= "00110010000111"; -- JZR R1, 7
        wait for 80ns;
        Reg <= "0100";
        wait for 80ns;
        Inst <= "01000010100000"; -- SUB R1, R2
        wait for 80ns;
        Inst <= "01010010100000"; -- AND R1, R2
        wait;
    end process;
end Behavioral;
