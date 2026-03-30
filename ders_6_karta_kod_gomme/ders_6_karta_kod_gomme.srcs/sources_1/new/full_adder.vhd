library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity full_adder is
    Port ( a_i 		: in STD_LOGIC;
           b_i 		: in STD_LOGIC;
           carry_i 	: in STD_LOGIC;
           sum_o 	: out STD_LOGIC;
           carry_o 	: out STD_LOGIC);
end full_adder;

architecture Behavioral of full_adder is

---------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
-- Modülün iç işleyişini tanımlar.
-- Architecture kısmı ikiye ayrılır: Bildirim bölümü (is ile begin arası) ve İşlevsel bölüm (begin sonrası)
-- architecture ın begin e kadar olan kısmı bildiri kısmıdır. Yani ben bu tasarımda neler kullnacağım
-- Bu kısımda sabitler belirlenebilir
---------------------------------------------------------------------------------------------------------------------------
	
	-- COMPONENT DECLERATİON
	-- Donanımın içinde başka bir donanım kullanmak istiyorum
	-- Aslında tam toplayıcı yarım toplayıcılardan oluşur. Daha önce yaptığımız yarım toplayıcıyı burda kullandık.
	
	component half_adder is
		Port ( a_i 		: in STD_LOGIC;
			   b_i 		: in STD_LOGIC;
			   sum_o 	: out STD_LOGIC;
			   carry_o  : out STD_LOGIC);
	end component half_adder;
	
	-- SİNYALLER
	-- İç sinyallerdir, modül içindeki tel bağlantılarını veya flip-flopları temsil eder.
	-- Bu sinyaller gidip bir yere bağlanacak yani ucu açık değil. Bu yüzden 3 tane tanımladık. Second sum ucu açık bir teldir değeri direkt dışarı vericek.
	signal first_sum		: STD_LOGIC := '0'; 
	signal first_carry		: STD_LOGIC := '0'; 
	signal second_carry		: STD_LOGIC := '0'; 

begin

	-- COMPONENT INSTANTIATION (BILEŞEN ÖRNEKLEMESI)
	first_half_adder : half_adder
	port map ( 
				a_i => a_i,
				b_i => b_i,
				sum_o => first_sum,
				carry_o => first_carry
			);
	
	second_half_adder : half_adder
	port map ( 
				a_i => first_sum,
				b_i => carry_i,
				sum_o => sum_o,
				carry_o => second_carry
			);
	
	-- Eş zamanlı sinyal atamaları
	carry_o <= first_carry or second_carry;


end Behavioral;
