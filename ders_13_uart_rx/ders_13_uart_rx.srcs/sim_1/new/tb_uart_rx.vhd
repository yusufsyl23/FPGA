library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_uart_rx is
	generic (
		c_clfreq 	 	: integer := 100_000_000;
		c_baudrate 		: integer := 115_200
	);
end tb_uart_rx;

architecture Behavioral of tb_uart_rx is

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
	
	signal tb_clk 				: std_logic := '0';
	signal tb_rx_i 		        : std_logic := '1';  -- '1' çümkü ilk başta boş durumda
	signal tb_dout_o		    : std_logic_vector (7 downto 0) := (others => '0');
    signal tb_rx_done_tick_o    : std_logic;
	
	constant tb_clkpreiod		: time := (1_000_000_000 / c_clfreq)* 1 ns;		-- 10 ns
	constant tb_baudrate115200	: time := (1_000_000_000 ns) / c_baudrate;		-- 8680 ns
	constant tb_hex44			: std_logic_vector (9 downto 0) := "1" & x"44" & "0"; -- Sırası ile stop biti & veri & start biti 
	constant tb_hexA5			: std_logic_vector (9 downto 0) := "1" & x"A5" & "0"; -- Sırası ile stop biti & veri & start biti 
	-- Ters yazmamızın sebebi uart okumaya lsb den başlar
	-- tb_hex44 bu veriyi tb_baudrate115200 bu kadar bekleyip bekleyip sırayla gödericez. Böylece pc den bir sinyal geliyormuş gibi test yapmış olucaz
	
begin

	DUT : uart_rx
	generic map(
			c_clfreq 	 	=> c_clfreq,
			c_baudrate 		=> c_baudrate
		)
		
		port map(
			clk 				=> tb_clk,
			rx_i 				=> tb_rx_i,
			dout_o		 		=> tb_dout_o,
			rx_done_tick_o  	=> tb_rx_done_tick_o
			
		);
	
	-- Simülasyon için niye clock processi yapıyoruz
	P_CLKGEN : process begin
		
		tb_clk <= '0';
		wait for tb_clkpreiod / 2;
		
		tb_clk <= '1';
		wait for tb_clkpreiod / 2;

	end process;
	
	P_STIMULI : process begin
	
		wait for tb_clkpreiod * 10; -- 10 clock (10 x 10ns = 100 ns) bekle ama NİYE?
		
		-- Simülasyon başlarken sinyaller kararsız olabilir.
		-- Sistemin başlatılması için kısa bir zaman tanınır. (FSM S_BOSTA’ya otursun)
		-- Yani: “Saat sinyali bir süre dönsün, sistem otursun, sonra rx_i’ye veri göndermeye başla.”

		for i in 0 to 9 loop
			
			-- Burda kafam karıştı 43 ün niye 0. biti ilk önce gidiyor normal sıralamada 100101100 olması gerekmez mi?
			-- rx e önce 0 verir (start biti). Sonra i = 1 oluca 43 ün 0. bitini gönderir.
			-- Bunu 9 kere yapar veri gönderimi biter. En son 10. bit olan stop bitini gönderir ve iş biter.
			tb_rx_i <= tb_hex44(i);
			wait for tb_baudrate115200;
	
		end loop;
		
		wait for 10 us; -- niye burda böyle bekliyor? Muhtemelen kararlı bir sistem oluşması için
		
		for i in 0 to 9 loop
			
			tb_rx_i <= tb_hexA5(i);
			wait for tb_baudrate115200;
	
		end loop;
		
		wait for 20 us;
		
		assert false
		report "SIMULASYON BITTI"
		severity failure;
		
	end process;

end Behavioral;

-- https://chatgpt.com/share/687645e3-7c90-8002-a7bc-c09b96d4c9a8
