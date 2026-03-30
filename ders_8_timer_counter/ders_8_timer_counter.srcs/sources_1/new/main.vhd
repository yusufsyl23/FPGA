library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity main is
	generic (
		c_clkfreq : integer := 100_000_000  -- 1 saniyede 100 milyon vuruş yapıyor
		
	);
	port ( 
		clk 		: in STD_LOGIC;
		sw 			: in STD_LOGIC_VECTOR (1 downto 0);
		counter		: out STD_LOGIC_VECTOR (7 downto 0)
	);
end main;

architecture Behavioral of main is

-- timer duruma göre swich lerin 2 sn, 1 sn, 500 ms veya 250 ms de bir tekrar edecek
	
	constant c_timer2seclim 	: integer := c_clkfreq*2;		-- 2 saniye
	constant c_timer1seclim 	: integer := c_clkfreq;			-- 1 saniye
	constant c_timer500mslim 	: integer := c_clkfreq/2;		-- 500 milisaniye
	constant c_timer250mslim 	: integer := c_clkfreq/4;		-- 250 milisaniye
	signal timer 				: integer range 0 to c_timer2seclim := 0;   -- Kaça kadar sayabileceğini tanımladık. En büyük değer c_timer2seclim
	signal timerlim 			: integer range 0 to c_timer2seclim := 0;	-- Seçime göre timerlim e kadar sayacak
	signal counter_ic			: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

begin
	
	-- Combinational logic assignment
	timerlim		<=	c_timer2seclim when sw = "00" else
						c_timer1seclim when sw = "01" else
						c_timer500mslim when sw = "10" else
						c_timer250mslim; 
						
	process (clk) begin -- clk dediğimiz zaman içeride atanan sinyallar artık bir flip flop olacak yani register şekilde çalışacak
		-- Bu kısma yazacağımız şeyler sequantial (Ardışıl) logic oalcak.
		if (rising_edge(clk)) then -- Yükselen Kenar
			
			-- Her clock da timer 1 artıyor limite eşit veya büyük olursa counter 1 artıyor
			-- timer 150 milyonda ama limiti 100 milyona düşürdük eşit olmadığı için over flow olana kadar sayar sonra tekrar 0 olup olması gerekn yere gelir.
			-- Bunun için >= kullanırız ve bu şekilde timer 0 lanır ve artmaya devam eder.
			if (timer >= timerlim - 1) then 		-- Bir şeyi karşılaştırırken bakılan şey sinyal veya input olmalı olmalı 
				counter_ic <= counter_ic + 1;
				timer 	   <= 0;
				-- counter <= counter + 1  Bu kullanım a-mantıken dopru ama hata verir çünkü output olan bir şey input olarak kullanılamaz
			
			else
				timer <= timer + 1;
			
			end if;
		end if;
	end process;
	
	counter <= counter_ic;

end Behavioral;
