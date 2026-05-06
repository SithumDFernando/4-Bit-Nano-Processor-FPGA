library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for MUX_2_1_3B: tests S=0 selects A, S=1 selects B.
entity TB_Mux_2_to_1_3bit is
end TB_Mux_2_to_1_3bit;

architecture Behavioral of TB_Mux_2_to_1_3bit is
    component MUX_2_1_3B
        port (A, B : in  std_logic_vector(2 downto 0);
              S    : in  std_logic;
              Q    : out std_logic_vector(2 downto 0));
    end component;

    signal A, B, Q : std_logic_vector(2 downto 0) := "000";
    signal S : std_logic := '0';
begin
    UUT : MUX_2_1_3B port map (A => A, B => B, S => S, Q => Q);

    process begin
        -- S=0 → Q=A
        A <= "010"; B <= "101"; S <= '0';
        wait for 50 ns;
        assert Q = "010" report "T1: S=0 should select A=010" severity error;

        -- S=1 → Q=B
        S <= '1';
        wait for 50 ns;
        assert Q = "101" report "T2: S=1 should select B=101" severity error;

        -- New values
        A <= "110"; B <= "011"; S <= '0';
        wait for 50 ns;
        assert Q = "110" report "T3: S=0 should select A=110" severity error;

        S <= '1';
        wait for 50 ns;
        assert Q = "011" report "T4: S=1 should select B=011" severity error;

        assert false report "TB_Mux_2_to_1_3bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
