library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity half_adder is
    Port ( a_i 		: in STD_LOGIC;
           b_i 		: in STD_LOGIC;
           sum_o 	: out STD_LOGIC;
           carry_o  : out STD_LOGIC);
end half_adder;

architecture Behavioral of half_adder is

begin

-- VHDL büyük küçük harf duyarsızdır
sum_o <= A_i xor B_i;
carry_o <= A_i and B_i;


end Behavioral;
