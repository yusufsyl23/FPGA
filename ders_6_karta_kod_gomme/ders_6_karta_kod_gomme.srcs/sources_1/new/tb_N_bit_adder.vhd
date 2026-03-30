library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity testbench is
end testbench;

architecture Behavioral of testbench is

    signal a_i     : std_logic_vector(3 downto 0) := (others => '0');
    signal b_i     : std_logic_vector(3 downto 0) := (others => '0');
    signal carry_i : std_logic := '0';
    signal sum_o   : std_logic_vector(3 downto 0);
    signal carry_o : std_logic;

begin

    uut: entity work.N_bit_adder
        generic map (n => 4)  -- ← BURASI ŞART
        port map (
            a_i => a_i,
            b_i => b_i,
            carry_i => carry_i,
            sum_o => sum_o,
            carry_o => carry_o
        );

    stim_proc: process
    begin
        wait for 100 ns;
        a_i <= "0001"; b_i <= "0010"; carry_i <= '0'; wait for 100 ns;		-- 1 + 2 = 3     c = 0 		sum_o = 0011 (3)
        a_i <= "0110"; b_i <= "0011"; carry_i <= '0'; wait for 100 ns;		-- 6 + 3 = 9	 c = 0		sum_o = 1001 (9)
        a_i <= "1111"; b_i <= "0001"; carry_i <= '0'; wait for 100 ns;		-- 15 + 1 = 16   c = 0 		sum_o = 0000, carry_o = 1
        a_i <= "1111"; b_i <= "1111"; carry_i <= '1'; wait for 100 ns;		-- 15 + 15 = 30  c = 1		sum_o = 1111, carry_o = 1
        wait;
    end process;

end Behavioral;
