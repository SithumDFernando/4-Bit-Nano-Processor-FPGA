library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Register_Bank is
end TB_Register_Bank;

architecture Behavioral of TB_Register_Bank is
    signal D              : std_logic_vector(3 downto 0) := "0000";
    signal I              : std_logic_vector(2 downto 0) := "000";
    signal Clr, Clk       : std_logic := '0';
    signal R0, R1, R2, R3 : std_logic_vector(3 downto 0);
    signal R4, R5, R6, R7 : std_logic_vector(3 downto 0);
begin
    -- REG_BANK port order: D, Clk, I, Clr, R1, R2, R3, R4, R5, R6, R7, R0
    UUT : entity work.REG_BANK
        port map (D => D, Clk => Clk, I => I, Clr => Clr,
                  R0 => R0, R1 => R1, R2 => R2, R3 => R3,
                  R4 => R4, R5 => R5, R6 => R6, R7 => R7);

    Clk <= not Clk after 20 ns;  -- 40 ns period, rising edges at 20,60,100,...

    process begin
        -- Reset
        Clr <= '1'; wait for 50 ns;
        assert R0 = "0000" report "T1: R0=0000" severity error;
        assert R1 = "0000" report "T1: R1=0000" severity error;
        assert R7 = "0000" report "T1: R7=0000" severity error;
        Clr <= '0';

        -- Write 0001 to R1
        D <= "0001"; I <= "001"; wait for 40 ns;
        assert R1 = "0001" report "T2: R1=0001" severity error;

        -- Write 0101 to R2
        D <= "0101"; I <= "010"; wait for 40 ns;
        assert R2 = "0101" report "T3: R2=0101" severity error;

        -- Write 1010 to R5
        D <= "1010"; I <= "101"; wait for 40 ns;
        assert R5 = "1010" report "T4: R5=1010" severity error;

        -- Write 1100 to R7
        D <= "1100"; I <= "111"; wait for 40 ns;
        assert R7 = "1100" report "T5: R7=1100" severity error;

        -- Write to R0 (I=000) → R0 must stay 0000
        D <= "1111"; I <= "000"; wait for 40 ns;
        assert R0 = "0000" report "T6: R0 hardwired to 0000" severity error;

        -- Verify R1, R2 unchanged
        assert R1 = "0001" report "T7: R1 unchanged" severity error;
        assert R2 = "0101" report "T7: R2 unchanged" severity error;

        -- Reset clears R1-R7
        Clr <= '1'; wait for 40 ns;
        assert R1 = "0000" report "T8: R1=0000 after reset" severity error;
        assert R7 = "0000" report "T8: R7=0000 after reset" severity error;

        assert false report "TB_Register_Bank: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
