library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity mux2x1 is
	port (
		a_i 	: in std_logic;
		b_i 	: in std_logic;
		s1_i 	: in std_logic;
		
		c_i 	: in std_logic;
		d_i 	: in std_logic;
		s2_i 	: in std_logic;
		
		e_i 	: in std_logic;
		f_i 	: in std_logic;
		s3_i 	: in std_logic;
		
		q1_o 	: out std_logic;
		q2_o 	: out std_logic;
		q3_o 	: out std_logic
	);
end mux2x1;

architecture Behavioral of mux2x1 is

	signal temp1 : std_logic := '0';
	signal temp2 : std_logic := '0';
	

begin
----------------------------------------------------
-- GATE LEVEL COMBINATIONAL DESIGN
-- YÖNTEM 1
-- Kombinasyonel devrelerde girişlerden herhangi birisinde bir değişiklik olursa bu değişikliğin sonucu çıkışa anında yansır.
-- Hafıza durumu yoktur anlık çalışır.
----------------------------------------------------
	
	temp1 <= not (a_i and s1_i);
	temp2 <= not (not (s1_i) and b_i);
	q1_o  <= not (temp1 and temp2);
	
----------------------------------------------------
-- CONCURRENT ASSIGMENT COMBINATIONAL DESIGN
-- YÖNTEM 2
----------------------------------------------------
	
	q2_o <= c_i when s2_i = '1' else  d_i; -- Eğer s2_i = '1' ise, q2_o <= c_i olur. Aksi halde (yani s2_i = '0' ise), q2_o <= d_i olur.

----------------------------------------------------
-- PROCESS COMBINATIONAL DESIGN
-- YÖNTEM 3
----------------------------------------------------

-- process, VHDL'de sinyal değişimlerine tepki veren mantıksal işlem bloğudur.Yani yazdığın her process gerçekte bir devre elemanına dönüşür.
-- s3_i, e_i, f_i sinyallerinden herhangi biri değiştiğinde bu process tetiklenir (çalışır). Bu sinyaller duyarlılık listesi olarak adlandırılır.
	P_LABEL : process (s3_i, e_i, f_i) begin 
		
		if (s3_i = '1') then
			q3_o <= e_i;
		else 
			q3_o <= f_i;
		end if;
		
	end process P_LABEL;
 
end Behavioral;
