
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce is
	generic (
		c_clkfreq 		: integer := 100_000_000;
		c_debounce_time : integer := 1000;	-- c_clkfreq/c_debounce_time = 1 kiloherz yani 1 mili saniye. Sayaç bu kadar sayınca 1 ms kadar saymış olacak
		-- Örneğin 1 ms boyunca sıfırda kalırsa sinyali sıfıra çekeriz
		ilk_deger		: std_logic := '0'	-- ilk güç verildiğinde 0 da başlıyacak. Sinyal en başta 1 gelse bile 1 ms 0 da kalır.
	);
	
	port ( 
		clk 		: in std_logic;
		signal_i	: in std_logic;
		signal_o	: out std_logic
		--sw_i 		: in std_logic_vector (1 downto 0);
		--button_i	: in std_logic;		-- yükselen kenar sayarken resetleyici buton
		--select_i 	: in std_logic;		-- ledlerde hangi swicth in hareketini göstersin
		--led_o		: out std_logic_vector (15 downto 0)
	);
	
end debounce;

architecture Behavioral of debounce is
-- timer olacak. Bu timer swicth 0 dan 1 e geçince saymaya başlıyacak ve c_clkfreq/s_debounce_time e kadar sayacak. 
-- Eğer bu süre boyunca 0 yada 1 oluşursa state değiştirecek. Bunun için bir limit belirlemeliyiz.
	
	constant c_timerlim : integer := c_clkfreq / c_debounce_time;
	
	signal timer 		: integer range 0 to c_timerlim := 0;	-- Butonun HIGH veya LOW sinyali ne kadar süre boyunca sabit kaldığını ölçer.Eğer timer_en = '1':Timer saymaya başlar. Eğer timer_en = '0':Timer sıfırlanır ve durur.
	signal timer_en		: std_logic := '0';						-- Timer’ın çalışıp çalışmayacağını kontrol eder (Enable sinyali).
	signal timer_tick	: std_logic := '0';						-- Timer süresi dolduğunda bir clock boyunca 1 olur.
	
	type t_state is (S_INITIAL, S_ZERO, S_ZEROTOONE, S_ONE, S_ONETOZERO); -- t_state tipi sadece bu 4 değerden birini alabilir.
	-- (ilk değer, 0, 0-->1, 1, 1-->0)
	
	signal state : t_state := S_INITIAL;

begin

	process (clk) begin
		if (rising_edge(clk)) then
		
			case state is
				-- Tek tek bu durumlarda neler olacak
				
				when S_INITIAL =>				-- Burası 1 clock sürer. Sonra bir daha dönülmez.
					if (ilk_deger = '0') then
						state <= S_ZERO;		-- Çünkü 0 durumunda 
					else
						state <= S_ONE;
					end if;
				
				when S_ZERO =>		-- 0 dayım sinyal girişi 1 oldu 
					-- Sinyal LOW durumdayken, sinyalin değişip değişmediğini kontrol eder.
					signal_o <= '0';
				
					if (signal_i = '1') then
						state <= S_ZEROTOONE;
					end if;
				
				when S_ZEROTOONE =>
				
					signal_o <= '0';	-- belki sinyal 1 den 0 a geçecek. Belki de bu bir gürültüydü
					timer_en <= '1';	-- Burda timer ı başlatalım.
					
					if (timer_tick = '1') then	-- her şey yolunda gider ve timer tick 1 ös boyunca 1 de kalırsa artık bu sinyalin 1 olduğundan eminiz
						state <= S_ONE;
						timer_en <= '0';		-- Buraya gelir gelmez timer ı 1 verdik. Eğer 0 a geri dönüyorsa timer da 0 olmalı
					end if;
					
					if (signal_i = '0') then	-- Herhangi bir durumda bir gürültü olursa 1 e çıkacak ve bir ms dolmadan 0 a geçecek
						state <= S_ZERO;
						timer_en <= '0';		-- Buraya gelir gelmez timer ı 1 verdik. Eğer 0 a geri dönüyorsa timer da 0 olmalı
					
					end if;
					
				
				when S_ONE =>
					signal_o <= '1';
				
					if (signal_i = '0') then
						state <= S_ONETOZERO;
					end if;
				
				when S_ONETOZERO =>
				
					signal_o <= '1';	-- belki sinyal 1 den 0 a geçecek. Belki de bu bir gürültüydü
					timer_en <= '1';	-- Burda timer ı başlatalım.
					
					if (timer_tick = '1') then	-- her şey yolunda gider ve timer tick 1 ös boyunca 1 de kalırsa artık bu sinyalin 1 olduğundan eminiz
						state <= S_ZERO;
						timer_en <= '0';		-- Buraya gelir gelmez timer ı 1 verdik. Eğer 0 a geri dönüyorsa timer da 0 olmalı
					end if;
					
					if (signal_i = '1') then	-- Herhangi bir durumda bir gürültü olursa 1 e çıkacak ve bir ms dolmadan 0 a geçecek
						state <= S_ONE;
						timer_en <= '0';		-- Buraya gelir gelmez timer ı 1 verdik. Eğer 0 a geri dönüyorsa timer da 0 olmalı
					
					end if;
			
			end case;
		end if;
	end process;
	
	P_TIMER : process(clk) begin
		if (rising_edge(clk)) then
			if (timer_en = '1') then
				if (timer = c_timerlim-1) then
					timer_tick 	<= '1';
					timer 		<= 0;
					
				else
					timer_tick 	<= '0';
					timer 		<= timer + 1;
					
				end if;
				
			
			else -- time enable değilse
			
				timer 		<= 0; -- timer counter ı 0 olsun 
				timer_tick 	<= '0';
			
			end if;
		end if;
	end process;
end Behavioral;
