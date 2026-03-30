library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity N_bit_adder is
	generic(
			n : integer := 4		-- Kaç bitlik toplama yapacağız
			);
			
    Port ( a_i 			: in STD_LOGIC_VECTOR (n-1 downto 0);
           b_i 			: in STD_LOGIC_VECTOR (n-1 downto 0);
           carry_i 		: in STD_LOGIC;
           sum_o 		: out STD_LOGIC_VECTOR (n-1 downto 0);
           carry_o 		: out STD_LOGIC
		   );
end N_bit_adder;

architecture Behavioral of N_bit_adder is
	
	-- COMPONENT DECLERATİONS
	component full_adder is
    Port ( a_i 		: in STD_LOGIC;
           b_i 		: in STD_LOGIC;
           carry_i 	: in STD_LOGIC;
           sum_o 	: out STD_LOGIC;
           carry_o 	: out STD_LOGIC);
	end component;
	
	-- temp sinyali carry leri tam toplayıcılara iletecek. Hangi tam toplayıcının carry si hangisi olacak. (others => "0") diyerek bütün bitleri 0 oldu
	signal temp : STD_LOGIC_VECTOR (n downto 0) := (others => '0');

begin
	
	temp(0) <= carry_i;		-- tempin ilk değeri dışarıdan gelen carry_i
	carry_o <= temp(n);		-- tempin son değeri carry_o
	
	-- Aradakiler ise birbirine bağlanacak
	
	-- n bit toplama için n defa instantion yapmak yerine for ile yapacağız.
	-- Burda 4 defa full adder örneklemek yerine for döngüsü ile yaptık. Burdaki k değerleri k. full adder demek.
	FULL_ADDER_GEN : for k in 0 to n-1 generate
		full_adder_k : full_adder
		port map(
					a_i 		=> a_i(k),
					b_i 		=> b_i(k),
					carry_i 	=> temp(k),
					sum_o 		=> sum_o(k),
					carry_o 	=> temp(k+1)
				);
	end generate;

end Behavioral;
