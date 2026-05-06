library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for ADDER_3: PC+1 incrementer, tests all 8 values including wrap.
entity TB_Adder_3bit is
end TB_Adder_3bit;

architecture Behavioral of TB_Adder_3bit is
    component ADDER_3
        port (A     : in  std_logic_vector(2 downto 0);
              S     : out std_logic_vector(2 downto 0);
              carry : out std_logic);
    end component;

    signal A, S : std_logic_vector(2 downto 0);
    signal carry : std_logic;
begin
    UUT : ADDER_3 port map (A => A, S => S, carry => carry);

    process begin
        -- 0+1=1
        A <= "000"; wait for 50 ns;
        assert S = "001" report "T1: 0+1=1" severity error;
        assert carry = '0' report "T1: no carry" severity error;

        -- 1+1=2
        A <= "001"; wait for 50 ns;
        assert S = "010" report "T2: 1+1=2" severity error;

        -- 5+1=6
        A <= "101"; wait for 50 ns;
        assert S = "110" report "T3: 5+1=6" severity error;

        -- 6+1=7
        A <= "110"; wait for 50 ns;
        assert S = "111" report "T4: 6+1=7" severity error;

        -- 7+1=0 with carry (wrap)
        A <= "111"; wait for 50 ns;
        assert S = "000" report "T5: 7+1 wraps to 0" severity error;
        assert carry = '1' report "T5: carry should be 1" severity error;

        assert false report "TB_Adder_3bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
