library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Kartta ortadaki butona basınca switch ile ayarladığımız 8 bitlik veriyi bilgisayar gönderir.
entity top is
	generic (
		top_c_clkfreq  	: integer := 100_000_000;
		top_c_baudrate 	: integer := 115_200;
		top_c_stopbit	: integer := 2
	);
	
	port (
		top_clk			: in std_logic ;
		top_sw_i		: in std_logic_vector (7 downto 0);  -- Bu data in (din) olacak.
		top_ortbuton_i	: in std_logic;
		top_tx_o		: out std_logic  					 -- Bilgisayara sırayla gidecek olan 1 bitlik veri
	);
end top;

architecture Behavioral of top is

	component debounce is
	
		generic (
			c_clkfreq       : integer := 100_000_000;     -- Saat frekansı (Hz), örneğin 100 MHz. 1 saniyede 100 milyon vuruyor.
			c_debounce_time : integer := 1000;            -- Debounce süresi (1ms), clock frekansı / debounce_time = sayacın limit değeri
			ilk_deger       : std_logic := '0'            -- Başlangıç değeri, çıkış ilk güç verildiğinde hangi durumda başlasın
		);
    
		port ( 
			clk         : in std_logic;                    -- Saat sinyali (clock)
			signal_i    : in std_logic;                    -- Giriş sinyali (örneğin buton)
			signal_o    : out std_logic                    -- Debounce edilmiş çıkış sinyali
		);
	
	end component;
	
	component uart_tx is
	
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
	
	end component;
	
	signal top_ortbuton_deb 	: std_logic := '0';
	signal top_ort_buton_next 	: std_logic := '0';
	signal top_tx_start			: std_logic := '0';
	signal top_tx_done_tick		: std_logic := '0';

begin

	ort_buton : debounce
	
		generic map(
			c_clkfreq       => top_c_clkfreq,     
			c_debounce_time => 1000,		-- Buna karışmadık. 1 Khz yani 1 ms olacak 
			ilk_deger       => '0'            
		)
    
		port map( 
			clk         => top_clk,                   
			signal_i    => top_ortbuton_i,                    
			signal_o    => top_ortbuton_deb                    
		);
		
	i_uart_tx : uart_tx
	
		generic map (
			c_clfreq 	 	=> top_c_clkfreq,
			c_bauderrate 	=> top_c_baudrate,
			c_stopbit	 	=> top_c_stopbit				
		)
	
		port map(
			clk 				=> top_clk,
			din_i		 		=> top_sw_i,
			tx_start_i 			=> top_tx_start,
			tx_done_tick_o  	=> top_tx_done_tick,
			tx_o 				=> top_tx_o
		);
		
	process (top_clk) begin
		if (rising_edge(top_clk)) then
	
			top_ort_buton_next 	<= top_ortbuton_deb;
			top_tx_start 		<= '0';				-- Yoksa top_tx_start hep 1 de kalır. 
			
			-- Butona basıldıysa ve bir sonra olması gereken 0 ise
			if (top_ortbuton_deb = '1' and top_ort_buton_next = '0') then -- Ne zaman bu if olursa start verir ve switch lerin değerini göndermeye başlar
				top_tx_start <= '1';
			end if;
		end if;
	end process;
	
	
	


end Behavioral;
