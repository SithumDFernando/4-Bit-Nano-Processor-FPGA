library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Optimizations vs original:
-- 1. Added AN output for 7-segment anode control
-- 2. Zero flag now comes from ALU output (correct), not from MuxD_Adder
-- 3. Component declarations updated for optimized sub-components
--    (REG_BANK behavioural, INSTRUCTION_DEC with/select, etc.)
entity NANOPROCESSOR is
    Port ( Clr       : in  STD_LOGIC;
           Clk       : in  STD_LOGIC;
           R         : out STD_LOGIC_VECTOR (3 downto 0);
           Overflow  : out STD_LOGIC;
           Zero      : out STD_LOGIC;
           Seven_Seg : out STD_LOGIC_VECTOR (6 downto 0);
           AN        : out STD_LOGIC_VECTOR (3 downto 0));
end NANOPROCESSOR;

architecture Behavioral of NANOPROCESSOR is
    component SLOW_CLK is
        generic (CLK_DIV_MAX : integer := 50_000_000);
        Port (Clk_in : in std_logic; Clk_out : out std_logic);
    end component;

    component MUX_8_1_4B is
        Port ( S  : in  STD_LOGIC_VECTOR (2 downto 0);
               R0, R1, R2, R3, R4, R5, R6, R7 : in STD_LOGIC_VECTOR (3 downto 0);
               Q  : out STD_LOGIC_VECTOR (3 downto 0));
    end component;

    component REG_BANK is
        Port ( D   : in  STD_LOGIC_VECTOR (3 downto 0);
               Clk : in  STD_LOGIC;
               I   : in  STD_LOGIC_VECTOR (2 downto 0);
               Clr : in  STD_LOGIC;
               R0, R1, R2, R3, R4, R5, R6, R7 : out STD_LOGIC_VECTOR (3 downto 0));
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

    component MUX_2_1_4B is
        Port ( A, B : in  STD_LOGIC_VECTOR (3 downto 0);
               S    : in  STD_LOGIC;
               Q    : out STD_LOGIC_VECTOR (3 downto 0));
    end component;

    component MUX_2_1_3B is
        Port ( A, B : in  STD_LOGIC_VECTOR (2 downto 0);
               S    : in  STD_LOGIC;
               Q    : out STD_LOGIC_VECTOR (2 downto 0));
    end component;

    component ROM is
        Port ( S : in  STD_LOGIC_VECTOR (2 downto 0);
               Q : out STD_LOGIC_VECTOR (11 downto 0));
    end component;

    component PC is
        Port ( D   : in  STD_LOGIC_VECTOR (2 downto 0);
               Clr : in  STD_LOGIC;
               Clk : in  STD_LOGIC;
               Q   : out STD_LOGIC_VECTOR (2 downto 0));
    end component;

    component ADDER_3 is
        Port ( A     : in  STD_LOGIC_VECTOR (2 downto 0);
               S     : out STD_LOGIC_VECTOR (2 downto 0);
               carry : out STD_LOGIC);
    end component;

    component ADD_SUB_4 is
        Port ( A, B     : in  STD_LOGIC_VECTOR (3 downto 0);
               S        : out STD_LOGIC_VECTOR (3 downto 0);
               M        : in  STD_LOGIC;
               overflow : out STD_LOGIC);
    end component;

    component LUT_7_SEG is
        Port ( address : in  STD_LOGIC_VECTOR (3 downto 0);
               data    : out STD_LOGIC_VECTOR (6 downto 0));
    end component;

    signal PC_ROM, Add3_MuxC, PC_MuxC         : std_logic_vector(2 downto 0);
    signal ROM_Decoder                         : std_logic_vector(11 downto 0);
    signal Decoder_MuxD                        : std_logic_vector(3 downto 0);
    signal Decoder_MuxC, Decoder_MuxDSelc, Decoder_Adder : std_logic;
    signal Decoder_RegBank, Decoder_MuxA, Decoder_MuxB   : std_logic_vector(2 downto 0);
    signal MuxD_Adder, MuxD_RegBank            : std_logic_vector(3 downto 0);
    signal R0_s,R1_s,R2_s,R3_s,R4_s,R5_s,R6_s,R7_s : std_logic_vector(3 downto 0);
    signal MuxA_Adder, MuxB_Adder              : std_logic_vector(3 downto 0);
    signal Slw_Clk                             : std_logic;
    signal Adder_Cout                          : std_logic;

begin
    LUT : LUT_7_SEG
        port map (address => R7_s, data => Seven_Seg);

    Slow_Clk_0 : Slow_Clk
        generic map (CLK_DIV_MAX => 50_000_000)
        port map (Clk_in => Clk, Clk_out => Slw_Clk);

    Adder : ADD_SUB_4
        port map (A => MuxA_Adder, B => MuxB_Adder, M => Decoder_Adder,
                  overflow => Overflow, S => MuxD_Adder);

    MuxA : MUX_8_1_4B
        port map (R0 => R0_s, R1 => R1_s, R2 => R2_s, R3 => R3_s,
                  R4 => R4_s, R5 => R5_s, R6 => R6_s, R7 => R7_s,
                  S => Decoder_MuxA, Q => MuxA_Adder);

    MuxB : MUX_8_1_4B
        port map (R0 => R0_s, R1 => R1_s, R2 => R2_s, R3 => R3_s,
                  R4 => R4_s, R5 => R5_s, R6 => R6_s, R7 => R7_s,
                  S => Decoder_MuxB, Q => MuxB_Adder);

    Register_Bank_0 : REG_BANK
        port map (D => MuxD_RegBank, Clk => Slw_Clk, I => Decoder_RegBank,
                  Clr => Clr,
                  R0 => R0_s, R1 => R1_s, R2 => R2_s, R3 => R3_s,
                  R4 => R4_s, R5 => R5_s, R6 => R6_s, R7 => R7_s);

    MuxC : MUX_2_1_3B
        port map (A => Add3_MuxC, B => Decoder_MuxD(2 downto 0),
                  S => Decoder_MuxC, Q => PC_MuxC);

    Adder_3bit_0 : ADDER_3
        port map (A => PC_ROM, carry => Adder_Cout, S => Add3_MuxC);

    Instruction_Decoder_0 : INSTRUCTION_DEC
        port map (Inst => ROM_Decoder, Reg => MuxA_Adder,
                  LSB => Decoder_MuxD, Reg_EN => Decoder_RegBank,
                  Mux_A => Decoder_MuxA, Mux_B => Decoder_MuxB,
                  LD => Decoder_MuxDSelc, Sub => Decoder_Adder,
                  JMP => Decoder_MuxC);

    MuxD : MUX_2_1_4B
        port map (A => MuxD_Adder, B => Decoder_MuxD,
                  S => Decoder_MuxDSelc, Q => MuxD_RegBank);

    Program_Counter_0 : PC
        port map (D => PC_MuxC, Clr => Clr, Clk => Slw_Clk, Q => PC_ROM);

    ROM_0 : ROM
        port map (S => PC_ROM, Q => ROM_Decoder);

    R    <= R7_s;
    -- Zero flag: '1' when ALU result is all zeros
    Zero <= '1' when MuxD_Adder = "0000" else '0';
    -- Enable only rightmost 7-segment digit
    AN   <= "1110";
end Behavioral;
