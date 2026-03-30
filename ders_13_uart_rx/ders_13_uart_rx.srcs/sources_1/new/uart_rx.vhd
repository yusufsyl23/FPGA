library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity uart_rx is
	generic (
		c_clfreq 	 	: integer := 100_000_000;
		c_baudrate 		: integer := 115_200
	);
	
	port (
		clk 				: in std_logic;
		rx_i 				: in std_logic;
		dout_o		 		: out std_logic_vector (7 downto 0);
		rx_done_tick_o  	: out std_logic
	
	);
	
end uart_rx;

architecture Behavioral of uart_rx is

	constant c_bittimer_lim : integer := c_clfreq / c_baudrate;	-- 868 clock döngüsü. 868 × 10 ns = 8680 ns ≈ 8.68 us

	type states is (S_BOSTA, S_BASLA, S_VERI, S_DUR);
	
	signal state 		: states := S_BOSTA;
	signal bittimer 	: integer range 0 to c_bittimer_lim := 0; 
	signal shreg		: std_logic_vector (7 downto 0) := (others => '0');		 	
	signal bitcounter 	: integer range 0 to 7 := 0;

begin

	P_MAIN : process (clk) begin
		if (rising_edge(clk)) then
		
			case state is 
			
				when S_BOSTA =>
				
					rx_done_tick_o 	<= '0';
					bittimer 		<= 0; -- gerekte yok. Zaten yukarıda 0
					
					if (rx_i = '0') then
						state <= S_BASLA;
					end if;
				
				when S_BASLA =>
				
					if (bittimer = c_bittimer_lim / 2 - 1) then
						state 	 <= S_VERI;
						bittimer <= 0;
					else
						bittimer <= bittimer + 1;
					end if; 
				
				when S_VERI =>
				
					if (bittimer = c_bittimer_lim) then
						if (bitcounter = 7) then
							state 		<= S_DUR;
							bitcounter 	<= 0;
						else
							bitcounter <= bitcounter + 1;
						end if;
						-- Bu şekilde yeni gelen bir veriyi shift registerinin en anlamlı bitine yazdı sonra sağa kaydırdı.
						-- Bunu 8 defa yağınca ilk gelen veri en anlamsız bitte (en solda) olur
						-- a & b   -->  a'nın bitleri sola, b'nin bitleri sağa gelir
						shreg 	 <= rx_i & shreg (7 downto 1); -- VHDL’de & operatörü, bit birleştirme (concatenation) operatörüdür.
						bittimer <= 0;
						else
							bittimer <= bittimer + 1;
					end if;
				
				when S_DUR =>
					
					-- Burda da olabilir ama stopa gelir gelmez t kadar beklemeden veri hazır olmuş olacaktı. 
					-- Buraya gelir gelmez daha T süre geçtimi kontrolü yapılmadan veri hazır diyecekti.
					--rx_done_tick_o 	<= '1';
					
					if (bittimer = c_bittimer_lim - 1) then
						state 			<= S_BOSTA;
						bittimer		<= 0;
						rx_done_tick_o 	<= '0';
					else
						bittimer 		<= bittimer + 1;
					end if;
			
			end case;
		
		end if;
	end process;
	
	-- Nedern dout u içerde kullanmadıkta shreg oluşturup onu içerde döndürdük?
	-- Çünkü eşitliğin sağ tarafına bir output yazamayız
	dout_o <= shreg;


end Behavioral;
