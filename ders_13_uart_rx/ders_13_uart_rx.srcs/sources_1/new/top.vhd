library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
	generic (
		c_clfreq 	: integer := 100_000_000;
		c_baudrate	: integer := 115_200
	);
	
	port (
		tp_clk		: in std_logic;
		tp_rx_i		: in std_logic;
		tp_leds_o	: out std_logic_vector (15 downto 0) -- 2 bayt haberleşme yapıcaz 
	);
end top;

architecture Behavioral of top is

	component uart_rx is
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
	end component; 
	
	signal tp_led			: std_logic_vector (15 downto 0) := (others => '0');
	signal tp_dout			: std_logic_vector (7 downto 0) := (others => '0');  -- PC den gelen 1 byte verinin durduğu register
	signal tp_rx_done_tick 	: std_logic := '0';

begin

	i_uart_rx : uart_rx 
		generic map(
			c_clfreq 	 	=> c_clfreq,
			c_baudrate 		=> c_baudrate
		)
		
		port map(
			clk 				=> tp_clk,
			rx_i 				=> tp_rx_i,
			dout_o		 		=> tp_dout,
			rx_done_tick_o  	=> tp_rx_done_tick
		);
		
	P_MAIN : process (tp_clk) begin
		if (rising_edge(tp_clk)) then
			
			-- PC den gelen ilk baytı LSB 8 bitime (ledlere) yazsın. Sonra gelen olursa 8 biti shift etsin. 
			-- Yani her veri geldiğinde LSB deki bitini most bitine shift etsin gelen veriyi de LSB bitine yazsın.
			
			if (tp_rx_done_tick = '1') then
				-- Bana her veri geldiğinde ledin ilk 8 bitine gelen veriyi yaz ledin üst kısmına da shift et. Yani 8 bit kaydır
				tp_led(15 downto 8) <= tp_led(7 downto 0);
				tp_led(7 downto 0)	<= tp_dout;
			
			end if;
		
		end if;
	end process;
	
	tp_leds_o <= tp_led;


end Behavioral;

--https://chatgpt.com/share/687645fc-44b0-8002-9cfa-761e94eec26c
