library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity TB_Register_4bit is
end TB_Register_4bit;

architecture Behavioral of TB_Register_4bit is
    signal Clk     : std_logic := '0';
    signal Val     : std_logic_vector(3 downto 0) := "0000";
    signal Sel     : std_logic := '0';
    signal Clr     : std_logic := '0';
    signal Reg_out : std_logic_vector(3 downto 0);
begin
    UUT : entity work.REG_4
        port map (Clk => Clk, Val => Val, Sel => Sel,
                  Clr => Clr, Reg_out => Reg_out);

    Clk <= not Clk after 50 ns;  -- 100 ns period

    process begin
        -- Reset
        Clr <= '1'; Sel <= '0'; wait for 110 ns;
        assert Reg_out = "0000" report "T1: 0000 after reset" severity error;
        Clr <= '0';

        -- Load 1111 when Sel=1
        Val <= "1111"; Sel <= '1'; wait for 100 ns;
        assert Reg_out = "1111" report "T2: load 1111" severity error;

        -- Load 1001
        Val <= "1001"; wait for 100 ns;
        assert Reg_out = "1001" report "T3: load 1001" severity error;

        -- Hold: Sel=0, Val change must be ignored
        Val <= "1010"; Sel <= '0'; wait for 100 ns;
        assert Reg_out = "1001" report "T4: hold 1001 (Sel=0)" severity error;

        -- Resume load
        Sel <= '1'; Val <= "0110"; wait for 100 ns;
        assert Reg_out = "0110" report "T5: load 0110" severity error;

        -- Clear overrides Sel
        Clr <= '1'; wait for 100 ns;
        assert Reg_out = "0000" report "T6: clear overrides Sel" severity error;

        assert false report "TB_Register_4bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
