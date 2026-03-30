library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity uart_tx is
	generic (
		c_clfreq 	 	: integer := 100_000_000;
		c_bauderrate 	: integer := 115_200;
		c_stopbit	 	: integer := 2				-- 2 olunca 11 bitin 8 biti gönderilen veri 1 bit start 2 bit stop var.
												-- 2 Niye daha mantıklı?
	);
	
	port (
		clk 				: in std_logic;
		din_i		 		: in std_logic_vector (7 downto 0);
		tx_start_i 		: in std_logic;
		tx_done_tick_o  	: out std_logic;
		tx_o 				: out std_logic
	);
	
end uart_tx;

architecture Behavioral of uart_tx is
	
	constant bittimer_lim : integer := c_clfreq / c_bauderrate;
	constant stopbit_lim  : integer := bittimer_lim * c_stopbit;
	
	type states is (S_BOSTA, S_BASLA, S_VERI, S_DUR);
	
	-- Bunlar niye signal niye constant değil
	-- Çünkü bu değişkenlerin zamanla değişmesi ve clockla senkron çalışması gerekiyor. constant sabittir; bir kez tanımlanır, değişmez.
	signal state 		: states := S_BOSTA;
	signal bittimer 	: integer range 0 to stopbit_lim := 0; -- bunu değiştirdik önce bittimer_lim idi. Niye ?
	-- İlk başta bittimer bittimer_lim 1 birim olduğu için dur => başla olmuyordu çünkü stopbiti 2 aldık yani stopbite kadar sayamıyor.
	signal shreg		: std_logic_vector (7 downto 0) := (others => '0');		
	-- Shreg registerına input olan din_i verisini kopylamamızın sebebi vhdl de sadece signal veya veriable değerleri değiştirişebilir.
	-- Dışarıdan gelen inputu değiştiremezsin. Biz burda kaydırma yapıyoruz. 	
	signal bitcounter 	: integer range 0 to 7 := 0;

begin

	P_MAIN : process (clk) begin
		if (rising_edge(clk)) then
		
			-- Durum makineleri case yapısı ile oluşturulabilir.
			case state is
				
				-- Outputları duruma göre biz ayarlıyoruz
				when S_BOSTA	=>
					
					tx_o  			<= '1';
					tx_done_tick_o 	<= '0';
					bitcounter		<= 0;	-- Biraz gereksiz gibi. Yukarıda zaten 0
					
					if (tx_start_i = '1') then
						state <= S_BASLA;
						tx_o  <= '0';
						shreg <= din_i;
				    -- tx_o yu burda da 0 yapabilriz başlada da 0 yapabiliriz. BUrda 0 yaparsak bir sonraki clock vurduğunda tx_o 0 olmuş olacak ve 
					-- başla ya gelmiş olacak. Yani geldiği anda 0 olacak. Diğer durumda başlaya gelecek ama tx_o 1, bir clock vuracak ve tx_o 0 olacak.
					-- Burda bir clock geçikme olur.
					end if;
					
				when S_BASLA	=>
				
					if (bittimer = bittimer_lim - 1) then
						state 				<= S_VERI;
						tx_o  				<= shreg(0);
						-- Yazılan kodların sıra önemi var mı?
						-- Sağa kaydırma. Bu şekilde bir sonraki clock da veri hazır olmuş olacak.
						-- VHDL’de <= ile yapılan signal atamaları bir sonraki clock döngüsünde etkili olur. 
						-- Ve aynı clock döngüsündeki tüm <= atamaları paralel tanımlanır.
						shreg(7) 			<= shreg(0);
						shreg (6 downto 0) 	<= shreg (7 downto 1);
						--shreg (7 downto 1) 	<= shreg (6 downto 0); -- Bunları hatalı yazmışız bu şekilde il giden bir msb oluyor.
						--shreg(0) 			<= shreg(7);
						bittimer 			<= 0;
						
						else
							bittimer <= bittimer + 1;
					end if;
					
				when S_VERI		=>
				
					-- tx_o <= shreg(0) ;		-- Buna gerek var mı bilmiyorum. Zaten başladan buraya gelirken bu işlemi yaptıkta geldik
					-- FSM içinde aktif durumda olduğun sürece, çıkışları her döngüde yeniden üretmelisin.
					if (bitcounter = 7) then					-- Son bit gönderiliyorsa
						if (bittimer = bittimer_lim - 1) then	-- 1 bit gönderme süresi dolduysa	
							state 	 	<= S_DUR;
							bitcounter 	<= 0;
							tx_o <= '1';
							bittimer 	<= 0;
							
						else
							bittimer <= bittimer + 1;
						end if;
					
					else	-- Eğer bitler bitmediyse
						if (bittimer = bittimer_lim - 1) then 
							-- Burda S_VERI durumuna geri dönmesi gerekmez miydi?
							-- Sonraki clockta FSM hâlâ S_VERI içinde olacağı için otomatik olarak döngüye devam eder.
							-- VHDL'de aynı durum içinde kalmak için ekstra bir atama gerekmez.
							shreg(7) 			<= shreg(0);
							shreg (6 downto 0) 	<= shreg (7 downto 1);
							tx_o 				<= shreg(0);
							-- Ben dedim yukarıdan gelirken zaten tx_o <= shreg(0) böyle yaptık diye. Eski şekilde bir clock fazla vurdu.
							bitcounter			<= bitcounter + 1;
							bittimer 			<= 0;
							
						else
							bittimer <= bittimer + 1;
						end if;
					end if;
				
				when S_DUR		=>
				
					if (bittimer = stopbit_lim - 1) then
						state 			<= S_BOSTA;
						tx_done_tick_o 	<= '1';
						bittimer 		<= 0;
						
					else
						bittimer <= bittimer + 1;
						
					end if;
			
			end case;
		end if;
	end process;
end Behavioral;
