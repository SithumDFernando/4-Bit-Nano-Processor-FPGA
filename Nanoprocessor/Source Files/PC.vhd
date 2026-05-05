library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Optimization: replaced 3 D_FF component instances with a single behavioural
-- process. Same 3 FDRE flip-flops inferred; eliminates the hierarchy overhead
-- and the latent Qbar-port mismatch in the original component declaration.
entity PC is
    Port ( D   : in  STD_LOGIC_VECTOR (2 downto 0);
           Clr : in  STD_LOGIC;
           Clk : in  STD_LOGIC;
           Q   : out STD_LOGIC_VECTOR (2 downto 0));
end PC;

architecture Behavioral of PC is
begin
    process (Clk) begin
        if rising_edge(Clk) then
            if Clr = '1' then
                Q <= "000";
            else
                Q <= D;
            end if;
        end if;
    end process;
end Behavioral;
