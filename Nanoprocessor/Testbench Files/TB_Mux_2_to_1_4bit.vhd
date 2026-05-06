library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Testbench for MUX_2_1_4B: tests S=0 selects A, S=1 selects B.
entity TB_Mux_2_to_1_4bit is
end TB_Mux_2_to_1_4bit;

architecture Behavioral of TB_Mux_2_to_1_4bit is
    component MUX_2_1_4B
        port (A, B : in  std_logic_vector(3 downto 0);
              S    : in  std_logic;
              Q    : out std_logic_vector(3 downto 0));
    end component;

    signal A, B, Q : std_logic_vector(3 downto 0) := "0000";
    signal S : std_logic := '0';
begin
    UUT : MUX_2_1_4B port map (A => A, B => B, S => S, Q => Q);

    process begin
        -- S=0 → Q=A
        A <= "1010"; B <= "0101"; S <= '0';
        wait for 50 ns;
        assert Q = "1010" report "T1: S=0 should select A=1010" severity error;

        -- S=1 → Q=B
        S <= '1';
        wait for 50 ns;
        assert Q = "0101" report "T2: S=1 should select B=0101" severity error;

        -- Change values
        A <= "1100"; B <= "0011"; S <= '0';
        wait for 50 ns;
        assert Q = "1100" report "T3: S=0 should select A=1100" severity error;

        S <= '1';
        wait for 50 ns;
        assert Q = "0011" report "T4: S=1 should select B=0011" severity error;

        assert false report "TB_Mux_2_to_1_4bit: ALL TESTS PASSED" severity note;
        wait;
    end process;
end Behavioral;
