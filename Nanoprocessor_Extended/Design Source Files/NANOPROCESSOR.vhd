library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity NANOPROCESSOR is
    Port ( Clr : in STD_LOGIC;
           Clk : in STD_LOGIC;
           R : out STD_LOGIC_VECTOR (3 downto 0);
           Overflow : out STD_LOGIC;
           Zero : out STD_LOGIC;
           Seven_Seg : out std_logic_vector (6 downto 0));
end NANOPROCESSOR;

architecture Behavioral of NANOPROCESSOR is
    component SLOW_CLK is 
        Port (  Clk_in : in std_logic;
                Clk_out : out std_logic);
    end component;
    component MUX_8_1_4B is
        Port ( S : in STD_LOGIC_VECTOR;
               R0 : in STD_LOGIC_VECTOR;
               R1 : in STD_LOGIC_VECTOR;
               R2 : in STD_LOGIC_VECTOR;
               R3 : in STD_LOGIC_VECTOR;
               R4 : in STD_LOGIC_VECTOR;
               R5 : in STD_LOGIC_VECTOR;
               R6 : in STD_LOGIC_VECTOR;
               R7 : in STD_LOGIC_VECTOR;
               Q : out STD_LOGIC_VECTOR);
    end component;
    component REG_BANK is
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
    end component;
    component INSTRUCTION_DEC is
        Port ( Inst : in STD_LOGIC_VECTOR (13 downto 0);
               Reg : in STD_LOGIC_VECTOR (3 downto 0);
               LSB : out STD_LOGIC_VECTOR (3 downto 0);
               Reg_EN : out STD_LOGIC_VECTOR (2 downto 0);
               Mux_A : out STD_LOGIC_VECTOR (2 downto 0);
               LD : out STD_LOGIC;
               Mux_B : out STD_LOGIC_VECTOR (2 downto 0);
               Sub : out STD_LOGIC;
               JMP : out STD_LOGIC);
    end component;
    component MUX_2_1_4B is
        Port ( A : in STD_LOGIC_VECTOR (3 downto 0);
               B : in STD_LOGIC_VECTOR (3 downto 0);
               S : in STD_LOGIC;
               Q : out STD_LOGIC_VECTOR (3 downto 0));
    end component;
    component MUX_2_1_3B is
        Port ( A : in STD_LOGIC_VECTOR (2 downto 0);
               B : in STD_LOGIC_VECTOR (2 downto 0);
               S : in STD_LOGIC;
               Q : out STD_LOGIC_VECTOR (2 downto 0));
    end component;
    component ROM is
        Port ( S : in STD_LOGIC_VECTOR (2 downto 0);
               Q : out STD_LOGIC_VECTOR (13 downto 0));
    end component;
    component PC is 
         Port ( D : in STD_LOGIC_VECTOR (2 downto 0);
                Clr : in STD_LOGIC;
                Clk : in STD_LOGIC;
                Q : out STD_LOGIC_VECTOR (2 downto 0));
    end component;
    component ADDER_3 is
        Port (  A : in STD_LOGIC_VECTOR (2 downto 0); 
                S : out STD_LOGIC_VECTOR(2 downto 0);
                carry : out STD_LOGIC); 
    end component;
    component ADD_SUB_4 is
        Port ( A : in STD_LOGIC_VECTOR (3 downto 0); 
               B : in STD_LOGIC_VECTOR (3 downto 0); 
               S : out STD_LOGIC_VECTOR (3 downto 0);
               M : in STD_LOGIC;
               overflow : out STD_LOGIC);
    end component;
    
    component LUT_7_SEG is
            Port ( address : in STD_LOGIC_VECTOR (3 downto 0);
                    data : out STD_LOGIC_VECTOR (6 downto 0));
    end component;
    signal PC_ROM, Add3_MuxC, PC_MuxC : std_logic_vector(2 downto 0);
    signal ROM_Decoder : std_logic_vector(13 downto 0);
    signal Decoder_MuxD : std_logic_vector(3 downto 0);
    signal Decoder_MuxC, Decoder_MuxDSelc, Decoder_Adder : std_logic;
    signal Decoder_RegBank, Decoder_MuxA, Decoder_MuxB : std_logic_vector(2 downto 0);
    signal MuxD_Adder, MuxD_RegBank : std_logic_vector(3 downto 0);
    signal R0,R1,R2,R3,R4,R5,R6,R7 : std_logic_vector(3 downto 0);
    signal MuxA_Adder, MuxB_Adder : std_logic_vector(3 downto 0);
    signal Slw_Clk : std_logic;
    signal Adder_Cout : std_logic;
    
begin
    LUT : LUT_7_SEG
        Port map(
            address => R7,
            data => Seven_Seg);
            
    Slow_Clk_0 : Slow_Clk
        Port map(
            Clk_in => Clk,
            Clk_out => Slw_Clk);

    Adder : ADD_SUB_4
        Port map(
            A => MuxA_Adder,
            B => MuxB_Adder,
            M => Decoder_Adder,
            overflow => overflow,
            S => MuxD_Adder);
    MuxA : MUX_8_1_4B
        Port map (
            R0 => R0,
            R1 => R1,
            R2 => R2,
            R3 => R3,
            R4 => R4, 
            R5 => R5,
            R6 => R6,
            R7 => R7,
            S => Decoder_MuxA,
            Q => MuxA_Adder);
    MuxB : MUX_8_1_4B
        Port map (
            R0 => R0,
            R1 => R1,
            R2 => R2,
            R3 => R3,
            R4 => R4, 
            R5 => R5,
            R6 => R6,
            R7 => R7,
            S => Decoder_MuxB,
            Q => MuxB_Adder);
    Register_Bank_0 : REG_BANK
        Port map (
            D => MuxD_RegBank,
            Clk => Slw_Clk,
            I => Decoder_RegBank,
            Clr => Clr,
            R0 => R0,
            R1 => R1,
            R2 => R2,
            R3 => R3,
            R4 => R4, 
            R5 => R5,
            R6 => R6,
            R7 => R7);
    MuxC : MUX_2_1_3B
        Port map (
            A => Add3_MuxC,
            B => Decoder_MuxD(2 downto 0),
            S => Decoder_MuxC,
            Q => PC_MuxC);
    Adder_3bit_0 : ADDER_3
        Port map (
            A => PC_ROM,
            Carry => Adder_Cout,
            S => Add3_MuxC);
    Instruction_Decoder_0 : INSTRUCTION_DEC
        Port map (
            Inst => ROM_Decoder,
            Reg => MuxA_Adder,
            LSB => Decoder_MuxD,
            Reg_EN => Decoder_RegBank,
            Mux_A => Decoder_MuxA,
            Mux_B => Decoder_MuxB,
            LD => Decoder_MuxDSelc,
            Sub => Decoder_Adder,
            JMP => Decoder_MuxC);
    MuxD : MUX_2_1_4B
        Port map (
            A => MuxD_Adder,
            B => Decoder_MuxD,
            S => Decoder_MuxDSelc,
            Q => MuxD_RegBank);
    Program_Counter_0 : PC
        Port map ( 
            D => PC_MuxC,
            Clr => Clr,
            Clk => Slw_Clk,
            Q => PC_ROM);
    ROM_0 : ROM
        Port map (
            S => PC_ROM,
            Q => ROM_Decoder);
    R <= R7;
    Zero <= (NOT MuxD_Adder(0)) AND (NOT MuxD_Adder(1)) AND (NOT MuxD_Adder(2)) AND (NOT MuxD_Adder(3));
end Behavioral;
