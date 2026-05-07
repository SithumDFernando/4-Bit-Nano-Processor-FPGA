library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Merged entity: replaces the original PC register + standalone ADDER_3 + MUX_2_1_3B.
-- Those three components used ~6 LUTs and 3 FFs total.
-- A single loadable counter uses ~2 LUTs and 3 FFs, and lets Vivado infer CARRY4
-- for the +1 increment rather than instantiating discrete gates.
entity PC is
    Port ( Clk      : in  STD_LOGIC;
           Clr      : in  STD_LOGIC;
           JMP      : in  STD_LOGIC;
           JMP_Addr : in  STD_LOGIC_VECTOR (2 downto 0);
           Q        : out STD_LOGIC_VECTOR (2 downto 0));
end PC;

architecture Behavioral of PC is
begin
    process (Clk, Clr) begin
        if Clr = '1' then
            -- Asynchronous reset matches original behaviour
            Q <= "000";
        elsif rising_edge(Clk) then
            if JMP = '1' then
                -- Synchronous load of jump target address
                Q <= JMP_Addr;
            else
                -- Increment: Vivado infers CARRY4 for this pattern
                Q <= std_logic_vector(unsigned(Q) + 1);
            end if;
        end if;
    end process;
end Behavioral;
