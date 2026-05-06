library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for REG_4: tests enable-gated load, clear, and hold behaviour.
entity TB_Register_4bit is
end TB_Register_4bit;

architecture Behavioral of TB_Register_4bit is
    component REG_4
        port (Clk     : in  std_logic;
              Val     : in  std_logic_vector(3 downto 0);
              Sel     : in  std_logic;
              Clr     : in  std_logic;
              Reg_out : out std_logic_vector(3 downto 0));
    end component;

    signal Clk, Sel, Clr : std_logic := '0';
    signal Val, Reg_out  : std_logic_vector(3 downto 0) := "0000";
begin
    UUT : REG_4 port map (Clk => Clk, Val => Val, Sel => Sel,
                          Clr => Clr, Reg_out => Reg_out);

    Clk <= not Clk after 50 ns;  -- 100 ns period, rising edges at 50,150,250,...

    process begin
        -- ── Reset ────────────────────────────────────────────────────
        Clr <= '1'; Sel <= '0';
        wait for 110 ns;  -- past first rising edge
        assert Reg_out = "0000" report "T1: should be 0000 after clear" severity error;
        Clr <= '0';

        -- ── Load 1111 with Sel=1 ─────────────────────────────────────
        Val <= "1111"; Sel <= '1';
        wait for 100 ns;
        assert Reg_out = "1111" report "T2: should be 1111" severity error;

        -- ── Load 1001 with Sel=1 ─────────────────────────────────────
        Val <= "1001";
        wait for 100 ns;
        assert Reg_out = "1001" report "T3: should be 1001" severity error;

        -- ── Hold: Sel=0, new Val ignored ─────────────────────────────
        Val <= "1010"; Sel <= '0';
        wait for 100 ns;
        assert Reg_out = "1001" report "T4: should hold 1001 when Sel=0" severity error;

        -- ── Resume load with Sel=1 ───────────────────────────────────
        Sel <= '1'; Val <= "0110";
        wait for 100 ns;
        assert Reg_out = "0110" report "T5: should load 0110" severity error;

        -- ── Clear overrides Sel ──────────────────────────────────────
        Clr <= '1';
        wait for 100 ns;
        assert Reg_out = "0000" report "T6: clear should override Sel" severity error;

        assert false report "TB_Register_4bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
