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
           Mux_B : out STD_LOGIC_VECTOR (2 downto 0);
           Sub : out STD_LOGIC;
           Logic_Sel : out STD_LOGIC;
           JMP : out STD_LOGIC);
end INSTRUCTION_DEC;

architecture Behavioral of INSTRUCTION_DEC is
    signal Opcode : std_logic_vector(3 downto 0);
begin
    Opcode <= Inst(13 downto 10);

    process(Opcode, Inst, Reg)
    begin
        -- Default values (Reset/Idle state)
        LSB       <= "0000";
        Reg_EN    <= "000";
        Mux_A     <= "000";
        Mux_B     <= "000";
        LD        <= '0';
        Sub       <= '0';
        Logic_Sel <= '0';
        JMP       <= '0';

        case Opcode is
            when "0000" => -- ADD Ra, Rb
                Reg_EN <= Inst(9 downto 7);
                Mux_A  <= Inst(9 downto 7);
                Mux_B  <= Inst(6 downto 4);

            when "0001" => -- NEG Ra
                Reg_EN <= Inst(9 downto 7);
                Mux_B  <= Inst(9 downto 7);
                Sub    <= '1';

            when "0010" => -- MOVI Ra, Imm
                LSB    <= Inst(3 downto 0);
                Reg_EN <= Inst(9 downto 7);
                LD     <= '1';

            when "0011" => -- JZR Ra, Addr
                Mux_A  <= Inst(9 downto 7);
                LSB    <= Inst(3 downto 0);
                if Reg = "0000" then
                    JMP <= '1';
                end if;

            when "0100" => -- SUB Ra, Rb
                Reg_EN <= Inst(9 downto 7);
                Mux_A  <= Inst(9 downto 7);
                Mux_B  <= Inst(6 downto 4);
                Sub    <= '1';

            when "0101" => -- AND Ra, Rb
                Reg_EN    <= Inst(9 downto 7);
                Mux_A     <= Inst(9 downto 7);
                Mux_B     <= Inst(6 downto 4);
                Logic_Sel <= '1';

            when others =>
                null; -- Keep default values
        end case;
    end process;

end Behavioral;
