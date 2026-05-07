library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NANOPROCESSOR is
    Port ( Clr : in STD_LOGIC;
           Clk : in STD_LOGIC;
           R : out STD_LOGIC_VECTOR (3 downto 0);
           Overflow : out STD_LOGIC;
           Zero : out STD_LOGIC;
           Seven_Seg : out std_logic_vector (6 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0));
end NANOPROCESSOR;

architecture Behavioral of NANOPROCESSOR is

    component SLOW_CLK is
        Port ( Clk_in  : in  std_logic;
               Clk_out : out std_logic);
    end component;

    -- PC now merges the old PC register + ADDER_3 + MUX_2_1_3B into one entity
    component PC is
        Port ( Clk      : in  STD_LOGIC;
               Clr      : in  STD_LOGIC;
               JMP      : in  STD_LOGIC;
               JMP_Addr : in  STD_LOGIC_VECTOR (2 downto 0);
               Q        : out STD_LOGIC_VECTOR (2 downto 0));
    end component;

    component ROM is
        Port ( S : in  STD_LOGIC_VECTOR (2 downto 0);
               Q : out STD_LOGIC_VECTOR (11 downto 0));
    end component;

    component INSTRUCTION_DEC is
        Port ( Inst   : in  STD_LOGIC_VECTOR (11 downto 0);
               Reg    : in  STD_LOGIC_VECTOR (3 downto 0);
               LSB    : out STD_LOGIC_VECTOR (3 downto 0);
               Reg_EN : out STD_LOGIC_VECTOR (2 downto 0);
               Mux_A  : out STD_LOGIC_VECTOR (2 downto 0);
               LD     : out STD_LOGIC;
               Mux_B  : out STD_LOGIC_VECTOR (2 downto 0);
               Sub    : out STD_LOGIC;
               JMP    : out STD_LOGIC);
    end component;

    component REG_BANK is
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
    end component;

    component MUX_8_1_4B is
        Port ( S  : in  STD_LOGIC_VECTOR;
               R0 : in  STD_LOGIC_VECTOR;
               R1 : in  STD_LOGIC_VECTOR;
               R2 : in  STD_LOGIC_VECTOR;
               R3 : in  STD_LOGIC_VECTOR;
               R4 : in  STD_LOGIC_VECTOR;
               R5 : in  STD_LOGIC_VECTOR;
               R6 : in  STD_LOGIC_VECTOR;
               R7 : in  STD_LOGIC_VECTOR;
               Q  : out STD_LOGIC_VECTOR);
    end component;

    component MUX_2_1_4B is
        Port ( A : in  STD_LOGIC_VECTOR (3 downto 0);
               B : in  STD_LOGIC_VECTOR (3 downto 0);
               S : in  STD_LOGIC;
               Q : out STD_LOGIC_VECTOR (3 downto 0));
    end component;

    component ADD_SUB_4 is
        Port ( A        : in  STD_LOGIC_VECTOR (3 downto 0);
               B        : in  STD_LOGIC_VECTOR (3 downto 0);
               S        : out STD_LOGIC_VECTOR (3 downto 0);
               M        : in  STD_LOGIC;
               overflow : out STD_LOGIC);
    end component;

    component LUT_7_SEG is
        Port ( address : in  STD_LOGIC_VECTOR (3 downto 0);
               data    : out STD_LOGIC_VECTOR (6 downto 0));
    end component;

    -- Removed: ADDER_3, MUX_2_1_3B (merged into PC)
    -- Removed signals: Add3_MuxC, PC_MuxC, Adder_Cout

    signal PC_ROM           : std_logic_vector(2 downto 0);
    signal ROM_Decoder      : std_logic_vector(11 downto 0);
    signal Decoder_MuxD     : std_logic_vector(3 downto 0);
    signal Decoder_MuxC     : std_logic;
    signal Decoder_MuxDSelc : std_logic;
    signal Decoder_Adder    : std_logic;
    signal Decoder_RegBank  : std_logic_vector(2 downto 0);
    signal Decoder_MuxA     : std_logic_vector(2 downto 0);
    signal Decoder_MuxB     : std_logic_vector(2 downto 0);
    signal MuxD_Adder       : std_logic_vector(3 downto 0);
    signal MuxD_RegBank     : std_logic_vector(3 downto 0);
    signal R0,R1,R2,R3,R4,R5,R6,R7 : std_logic_vector(3 downto 0);
    signal MuxA_Adder       : std_logic_vector(3 downto 0);
    signal MuxB_Adder       : std_logic_vector(3 downto 0);
    signal Slw_Clk          : std_logic;

begin

    LUT : LUT_7_SEG
        port map (address => R7, data => Seven_Seg);

    Slow_Clk_0 : SLOW_CLK
        port map (Clk_in => Clk, Clk_out => Slw_Clk);

    -- PC now internally handles +1 and jump mux; ADDER_3 and MUX_2_1_3B removed
    Program_Counter_0 : PC
        port map (
            Clk      => Slw_Clk,
            Clr      => Clr,
            JMP      => Decoder_MuxC,
            JMP_Addr => Decoder_MuxD(2 downto 0),
            Q        => PC_ROM);

    ROM_0 : ROM
        port map (S => PC_ROM, Q => ROM_Decoder);

    Instruction_Decoder_0 : INSTRUCTION_DEC
        port map (
            Inst   => ROM_Decoder,
            Reg    => MuxA_Adder,
            LSB    => Decoder_MuxD,
            Reg_EN => Decoder_RegBank,
            Mux_A  => Decoder_MuxA,
            Mux_B  => Decoder_MuxB,
            LD     => Decoder_MuxDSelc,
            Sub    => Decoder_Adder,
            JMP    => Decoder_MuxC);

    MuxA : MUX_8_1_4B
        port map (
            R0 => R0, R1 => R1, R2 => R2, R3 => R3,
            R4 => R4, R5 => R5, R6 => R6, R7 => R7,
            S  => Decoder_MuxA, Q => MuxA_Adder);

    MuxB : MUX_8_1_4B
        port map (
            R0 => R0, R1 => R1, R2 => R2, R3 => R3,
            R4 => R4, R5 => R5, R6 => R6, R7 => R7,
            S  => Decoder_MuxB, Q => MuxB_Adder);

    Adder : ADD_SUB_4
        port map (
            A        => MuxA_Adder,
            B        => MuxB_Adder,
            M        => Decoder_Adder,
            overflow => Overflow,
            S        => MuxD_Adder);

    MuxD : MUX_2_1_4B
        port map (
            A => MuxD_Adder,
            B => Decoder_MuxD,
            S => Decoder_MuxDSelc,
            Q => MuxD_RegBank);

    Register_Bank_0 : REG_BANK
        port map (
            D   => MuxD_RegBank,
            Clk => Slw_Clk,
            I   => Decoder_RegBank,
            Clr => Clr,
            R0  => R0, R1 => R1, R2 => R2, R3 => R3,
            R4  => R4, R5 => R5, R6 => R6, R7 => R7);

    R    <= R7;
    -- NOR4 is more efficient than 4 NOTs + 3 ANDs for the zero flag
    Zero <= NOT (MuxD_Adder(0) OR MuxD_Adder(1) OR MuxD_Adder(2) OR MuxD_Adder(3));
    -- Enable only the rightmost 7-seg digit (active-low anodes)
    an   <= "1110";

end Behavioral;
