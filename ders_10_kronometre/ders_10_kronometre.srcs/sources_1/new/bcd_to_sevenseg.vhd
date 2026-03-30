
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity bcd_to_sevenseg is
	port (
		bcd_i 		: in std_logic_vector (3 downto 0);
		sevenseg_o  : out std_logic_vector (7 downto 0)
	);
end bcd_to_sevenseg;

architecture Behavioral of bcd_to_sevenseg is

begin

	process (bcd_i) begin
		
		case bcd_i is 
		
			-- Yanacak olanlar 0 olacak. Ardunioya göre ortak anot(+). Bütün çizgilerin bir ucu + ya bağlı. Yakmak istene led - verilir ve devre tamamlanır.
			when "0000" => -- 0
				sevenseg_o <= "00000011";	-- ABCDEFGP
			
			when "0001" => -- 1
				sevenseg_o <= "10011111";
				
			when "0010" => -- 2
				sevenseg_o <= "00100101";
				
			when "0011" => -- 3
				sevenseg_o <= "00001101";
				
			when "0100" => -- 4
				sevenseg_o <= "10011001";
				
			when "0101" => -- 5
				sevenseg_o <= "01001001";
				
			when "0110" => -- 6
				sevenseg_o <= "00000101";
				
			when "0111" => -- 7
				sevenseg_o <= "00011111";
				
			when "1000" => -- 8
				sevenseg_o <= "00000001";
				
			when "1001" => -- 9
				sevenseg_o <= "00001001";
			
			when others =>
				sevenseg_o <= "11111111";
				
		end case;
	
	end process;


end Behavioral;
