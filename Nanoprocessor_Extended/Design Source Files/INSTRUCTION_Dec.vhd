library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity INSTRUCTION_DEC is
    Port ( Inst : in STD_LOGIC_VECTOR (13 downto 0);
--           Clk : in STD_LOGIC;
           Reg : in STD_LOGIC_VECTOR (3 downto 0);
           LSB : out STD_LOGIC_VECTOR (3 downto 0);
           Reg_EN : out STD_LOGIC_VECTOR (2 downto 0);
           Mux_A : out STD_LOGIC_VECTOR (2 downto 0);
           LD : out STD_LOGIC;
           Mux_B : out STD_LOGIC_VECTOR (2 downto 2);
           Sub : out STD_LOGIC;
           Logic_Sel : out STD_LOGIC;
           JMP : out STD_LOGIC);
end INSTRUCTION_DEC;

architecture Behavioral of INSTRUCTION_DEC is
    component D_FF
        port(
            D : in std_logic;
            Res : in std_logic;
            Clk : in std_logic;
            Q : out std_logic;
            Qbar : out std_logic);
    end component;
    -- Instruction Opcode: Inst(13 downto 10)
    -- Extendable to 16 instructions using 4 bits
    signal sig_move, sig_and, sig_neg, sig_jump, sig_sub, sig_bitwise_and : std_logic;
    signal sig_move2, sig_and2, sig_neg2, sig_jump2, sig_sub2, sig_bitwise_and2 : std_logic_vector (2 downto 0);
    signal sig_move3, sig_and3, sig_neg3, sig_jump3, sig_sub3, sig_bitwise_and3 : std_logic_vector( 3 downto 0);
    signal m_LSB, a_LSB, n_LSB, j_LSB, s_LSB, l_LSB, LSB0 : std_logic_vector(3 downto 0);
    signal m_Reg_EN, a_Reg_EN, n_Reg_EN, j_Reg_EN, s_Reg_EN, l_Reg_EN, Reg_EN0 : std_logic_vector (2 downto 0);
    signal m_Mux_A, a_Mux_A, n_Mux_A, j_Mux_A, s_Mux_A, l_Mux_A, Mux_A0 : std_logic_vector (2 downto 0);
    signal m_LD, a_LD, n_LD, j_LD, s_LD, l_LD, LD0 : std_logic;
    signal m_Mux_B, a_Mux_B, n_Mux_B, j_Mux_B, s_Mux_B, l_Mux_B, Mux_B0 : std_logic_vector ( 2 downto 0);
    signal m_Sub, a_Sub, n_Sub, j_Sub, s_Sub, l_Sub, Sub0 : std_logic;
    signal m_Logic_Sel, a_Logic_Sel, n_Logic_Sel, j_Logic_Sel, s_Logic_Sel, l_Logic_Sel : std_logic;
    signal m_JMP, a_JMP, n_JMP, j_JMP, s_JMP, l_JMP, JMP0 : std_logic;
    signal Res : std_logic;

begin

            
    sig_move <= (NOT Inst(13)) AND (NOT Inst(12)) AND (Inst(11)) AND (NOT Inst(10));
    sig_and <= (NOT Inst(13)) AND (NOT Inst(12)) AND (NOT Inst(11)) AND (NOT Inst(10));
    sig_neg <= (NOT Inst(13)) AND (NOT Inst(12)) AND (NOT Inst(11)) AND (Inst(10));
    sig_jump <= (NOT Inst(13)) AND (NOT Inst(12)) AND (Inst(11)) AND (Inst(10));
    sig_sub <= (NOT Inst(13)) AND (Inst(12)) AND (NOT Inst(11)) AND (NOT Inst(10));
    sig_bitwise_and <= (NOT Inst(13)) AND (Inst(12)) AND (NOT Inst(11)) AND (Inst(10));
    
    -- To add new instructions:
    -- 1. Define sig_new_instr <= (logic for Inst(13 downto 10));
    -- 2. Create sig_new_instr2 and sig_new_instr3 vectors (for masking);
    -- 3. Define control signals (m_LSB, m_Reg_EN, etc.) for the new instruction;
    -- 4. OR the new signals into the final output assignments at the end.
    
    sig_move2(0) <= sig_move; sig_move2(1) <= sig_move; sig_move2(2) <= sig_move;
    sig_and2(0) <= sig_and; sig_and2(1) <= sig_and; sig_and2(2) <= sig_and;
    sig_neg2(0) <= sig_neg; sig_neg2(1) <= sig_neg; sig_neg2(2) <= sig_neg;
    sig_jump2(0) <= sig_jump; sig_jump2(1) <= sig_jump; sig_jump2(2) <= sig_jump;
    sig_sub2(0) <= sig_sub; sig_sub2(1) <= sig_sub; sig_sub2(2) <= sig_sub;
    sig_bitwise_and2(0) <= sig_bitwise_and; sig_bitwise_and2(1) <= sig_bitwise_and; sig_bitwise_and2(2) <= sig_bitwise_and;
    
    sig_move3(0) <= sig_move; sig_move3(1) <= sig_move; sig_move3(2) <= sig_move; sig_move3(3) <= sig_move;
    sig_and3(0) <= sig_and; sig_and3(1) <= sig_and; sig_and3(2) <= sig_and; sig_and3(3) <= sig_and;
    sig_neg3(0) <= sig_neg; sig_neg3(1) <= sig_neg; sig_neg3(2) <= sig_neg; sig_neg3(3) <= sig_neg;
    sig_jump3(0) <= sig_jump; sig_jump3(1) <= sig_jump; sig_jump3(2) <= sig_jump; sig_jump3(3) <= sig_jump;
    sig_sub3(0) <= sig_sub; sig_sub3(1) <= sig_sub; sig_sub3(2) <= sig_sub; sig_sub3(3) <= sig_sub;
    sig_bitwise_and3(0) <= sig_bitwise_and; sig_bitwise_and3(1) <= sig_bitwise_and; sig_bitwise_and3(2) <= sig_bitwise_and; sig_bitwise_and3(3) <= sig_bitwise_and;
    
    --move instruction
    m_LSB <= Inst(3 downto 0);
    m_Reg_EN <= Inst(9 downto 7);
    m_Mux_A <= "000";
    m_LD <= '1';
    m_Mux_B <= "000";
    m_Sub <= '0';
    m_Logic_Sel <= '0';
    m_JMP <= '0';
    
    --add instruction (arithmetic)
    a_LSB <= "0000";
    a_Reg_EN <= Inst(9 downto 7);
    a_Mux_A <= Inst(9 downto 7);
    a_LD <= '0';
    a_Mux_B <= Inst(6 downto 4);
    a_Sub <= '0';
    a_Logic_Sel <= '0';
    a_JMP <= '0';
    
    --neg instruction
    n_LSB <= "0000";
    n_Reg_EN <= Inst(9 downto 7);
    n_Mux_A <= "000";
    n_LD <= '0';
    n_Mux_B <= Inst(9 downto 7);
    n_Sub <= '1';
    n_Logic_Sel <= '0';
    n_JMP <= '0';
    
    --jump instruction
    j_LSB <= Inst(3 downto 0);
    j_Reg_EN <= "000";
    j_Mux_A <= Inst(9 downto 7);
    j_LD <= '1';
    j_Mux_B <= "000";
    j_Sub <= '0';
    j_Logic_Sel <= '0';
    j_JMP <= (NOT Reg(0)) AND (NOT Reg(1)) AND (NOT Reg(2)) AND (NOT Reg(3));
    
    --sub instruction
    s_LSB <= "0000";
    s_Reg_EN <= Inst(9 downto 7);
    s_Mux_A <= Inst(9 downto 7);
    s_LD <= '0';
    s_Mux_B <= Inst(6 downto 4);
    s_Sub <= '1';
    s_Logic_Sel <= '0';
    s_JMP <= '0';
    
    --bitwise and instruction
    l_LSB <= "0000";
    l_Reg_EN <= Inst(9 downto 7);
    l_Mux_A <= Inst(9 downto 7);
    l_LD <= '0';
    l_Mux_B <= Inst(6 downto 4);
    l_Sub <= '0';
    l_Logic_Sel <= '1';
    l_JMP <= '0';
    
    
    
    LSB <= (m_LSB AND sig_move3) OR (a_LSB AND sig_and3) OR (n_LSB AND sig_neg3) OR (j_LSB AND sig_jump3) OR (s_LSB AND sig_sub3) OR (l_LSB AND sig_bitwise_and3);
    Reg_EN <= (m_Reg_EN AND sig_move2) OR (a_Reg_EN AND sig_and2) OR (n_Reg_EN AND sig_neg2) OR (j_Reg_EN AND sig_jump2) OR (s_Reg_EN AND sig_sub2) OR (l_Reg_EN AND sig_bitwise_and2);
    Mux_A <= (m_Mux_A AND sig_move2) OR (a_Mux_A AND sig_and2) OR (n_Mux_A AND sig_neg2) OR (j_Mux_A AND sig_jump2) OR (s_Mux_A AND sig_sub2) OR (l_Mux_A AND sig_bitwise_and2);
    LD <= (m_LD AND sig_move) OR (a_LD AND sig_and) OR (n_LD AND sig_neg) OR (j_LD AND sig_jump) OR (s_LD AND sig_sub) OR (l_LD AND sig_bitwise_and);
    Mux_B <= (m_Mux_B AND sig_move2) OR (a_Mux_B AND sig_and2) OR (n_Mux_B AND sig_neg2) OR (j_Mux_B AND sig_jump2) OR (s_Mux_B AND sig_sub2) OR (l_Mux_B AND sig_bitwise_and2);
    Sub <= (m_Sub AND sig_move) OR (a_Sub AND sig_and) OR (n_Sub AND sig_neg) OR (j_Sub AND sig_jump) OR (s_Sub AND sig_sub) OR (l_Sub AND sig_bitwise_and);
    Logic_Sel <= (m_Logic_Sel AND sig_move) OR (a_Logic_Sel AND sig_and) OR (n_Logic_Sel AND sig_neg) OR (j_Logic_Sel AND sig_jump) OR (s_Logic_Sel AND sig_sub) OR (l_Logic_Sel AND sig_bitwise_and);
    JMP <= (m_JMP AND sig_move) OR (a_JMP AND sig_and) OR (n_JMP AND sig_neg) OR (j_JMP AND sig_jump) OR (s_JMP AND sig_sub) OR (l_JMP AND sig_bitwise_and);
end Behavioral;
