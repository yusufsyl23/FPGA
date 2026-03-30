library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_uart_tx is
	generic (
		tb_g_clfreq 	 : integer := 100_000_000;
		tb_g_bauderrate  : integer := 10_000_000;  -- Simülasyon için 10 Megabit yaptık
		tb_g_stopbit	 : integer := 2				
	);
end tb_uart_tx;

architecture Behavioral of tb_uart_tx is
	
	component uart_tx is
		
		generic (
		c_clfreq 	 : integer := 100_000_000;
		c_bauderrate : integer := 115_200;
		c_stopbit	 : integer := 2			
		);
	
		port (
		clk 			: in std_logic;
		din_i		 	: in std_logic_vector (7 downto 0);
		tx_start_i 		: in std_logic;
		tx_done_tick_o  : out std_logic;
		tx_o 			: out std_logic
		);
		
	end component;
	
	signal tb_clk 				: std_logic := '0';
	signal tb_din_i		 		: std_logic_vector (7 downto 0) := (others => '0');
	signal tb_tx_start_i 		: std_logic := '0';
	signal tb_tx_done_tick_o	: std_logic;
	signal tb_tx_o 				: std_logic;
	
	constant tb_clkpreiod		: time := (1_000_000_000 / tb_g_clfreq)* 1 ns; -- Bu kart saniyede 100 milyon kez vurur. Yani ferakansı 100 Mhz. 
																			-- Bir tam vuruş yani bir periyordu 10 ns sürer.

begin

	DUT : uart_tx -- DUT : Design Under Test (Test Edilen Tasarım) 
	generic map(
		c_clfreq 	 => tb_g_clfreq,
		c_bauderrate => tb_g_bauderrate,
		c_stopbit	 =>	tb_g_stopbit	
		)
	
		port map(
		clk 			=> tb_clk,
		din_i		 	=> tb_din_i,
		tx_start_i 		=> tb_tx_start_i,
		tx_done_tick_o  =>tb_tx_done_tick_o,
		tx_o 			=> tb_tx_o
		);
		
	-- Şimdi 100 Mhz clock üretmek lazım
	P_CLKGEN : process begin
		tb_clk <= '0';
		wait for tb_clkpreiod / 2;
		
		tb_clk <= '1';
		wait for tb_clkpreiod / 2;
		
	end process P_CLKGEN;

-- Process lerin çalışma mantığı nedir her an hepsi paralel çalışıyor mu	
	
	P_STIMULI :process begin	-- TEST SİNYALİ ÜRETİCİ
		
		-- tx = 0 anı
		
		tb_din_i		<= x"00";		
	    tb_tx_start_i	<= '0';

-- Burda beklerken niye vuruş saymadık ta zaman sayıyoruz
		wait for tb_clkpreiod * 10; -- 10 clock kadar beklesin
		
		tb_din_i		<= x"51";		
	    tb_tx_start_i	<= '1';		-- tx_start_i 1 clock kadar 1 olursa göndermeye başlar. 
-- Bence burda bir terslik var. 1 clock kadar 0 olursa göndermeye başlaması gerek.

		wait for tb_clkpreiod; -- 1 clock geçti
		tb_tx_start_i	<= '0';
	
	-- 10_000_000 = 10 Megabit = 100 ns. 2 tane stop bit ile toplam 11 bit gidecek. 11 x 100 ns = 1,1 µs
	
		wait for 1.2 us; -- 1.2 mikro saniye de işlem bitmiş olur 
		
		-- Yeni veri gönderme
		tb_din_i		<= x"A8";		
	    tb_tx_start_i	<= '1';
		wait for tb_clkpreiod; -- 1 clock geçti
		tb_tx_start_i	<= '0';
		
		-- Simülasyon olduğu için wait until kullandık Simülasyonda hoca kullanmıyormuş
		wait until (rising_edge(tb_tx_done_tick_o)); -- tb_tx_done_tick_o yükselen kenar olana kadar  
		
		wait for 1 us;
		
		assert false
		report "SIMULASYON BITTI"
		severity failure;
		
	end process P_STIMULI;

end Behavioral;
