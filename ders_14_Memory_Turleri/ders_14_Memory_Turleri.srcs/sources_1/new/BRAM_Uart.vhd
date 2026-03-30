library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- RAM paket tanımı
package ram_pkg is
    -- Verilen derinliğe göre adres hattının kaç bit olacağını hesaplayan fonksiyon
    function clogb2 (depth : in natural) return integer; -- clogb2 : ceiling of log base 2
end ram_pkg;

package body ram_pkg is 
	-- Yeni bir fonksiyon tanımlıyoruz. İsmi: clogb2.Parametresi: depth (natural türünde, yani 0 veya pozitif tam sayı)Döndürdüğü değer: integer (bir tamsayı)
    function clogb2 (depth : in natural) return integer is 
        
		-- Bu değişken depth'i böle böle küçültmek için kullanılacak. Orijinal depth değişmesin diye ayrı bir değişken kullanılıyor.
		variable temp     : integer := depth;
		-- Amacı: RAM adres bit sayısını hesaplamak için kaç kere 2’ye böldüğümüzü saymak.
        variable ret_val  : integer := 0;
    
	begin 
        -- temp değeri 1'den büyük olduğu sürece 2'ye böl ve bit sayısını artır
        while temp > 1 loop 
            ret_val := ret_val + 1;
            temp    := temp / 2;
        
		end loop;
        return ret_val;
    end function;
end package body ram_pkg;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.ram_pkg.all;

entity BRAM_Uart is

	generic (
		t_clfreq 	 	: integer := 100_000_000;
		t_bauderrate 	: integer := 115_200;
		t_stopbit	 	: integer := 2;				-- 2 olunca 11 bitin 8 biti gönderilen veri 1 bit start 2 bit stop var.
	
		t_RAM_WIDTH       	: integer := 16;                 -- RAM veri genişliği (bit cinsinden). Her hücrede 16 bitlik veri var. Her veri 16 bit
        t_RAM_DEPTH       	: integer := 128;                -- RAM derinliği (adreslenebilir giriş sayısı). Yukarıdan aşşağıya 128 tane hücre var.
        t_RAM_PERFORMANCE 	: string  := "LOW_LATENCY";       -- RAM performans modu: "HIGH_PERFORMANCE" veya "LOW_LATENCY"
		t_C_RAM_TYPE		: string  := "block"
	);
	
	port ( 
		t_clk 	: in std_logic;
		t_rx_i 	: in std_logic;
		t_tx_o	: out std_logic
	);
	
end BRAM_Uart;

architecture Behavioral of BRAM_Uart is

	component block_ram is
		generic (
			RAM_WIDTH       : integer := 16;                 -- RAM veri genişliği (bit cinsinden). Her hücrede 16 bitlik veri var. Her veri 16 bit
			RAM_DEPTH       : integer := 128;                -- RAM derinliği (adreslenebilir giriş sayısı). Yukarıdan aşşağıya 128 tane hücre var.
			RAM_PERFORMANCE : string  := "LOW_LATENCY";       -- RAM performans modu: "HIGH_PERFORMANCE" veya "LOW_LATENCY"
			C_RAM_TYPE		: string  := "block"
		);
		port (
			addra : in  std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);  -- Adres hattı (RAM_DEPTH'e göre genişlik)
			dina  : in  std_logic_vector(RAM_WIDTH-1 downto 0);            -- RAM giriş verisi
			clka  : in  std_logic;                                         -- Saat (clock)
			wea   : in  std_logic;                                         -- Yazma etkinleştirme (write enable)
			douta : out std_logic_vector(RAM_WIDTH-1 downto 0)             -- RAM çıkış verisi
		);
	end component;
	
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
			tx_start_i 			: in std_logic;
			tx_done_tick_o  	: out std_logic;
			tx_o 				: out std_logic
		);
	
	end component;
	
	constant ADDR_WIDTH : integer := clogb2(t_RAM_DEPTH);

	
	signal t_dout_o 		: std_logic_vector (7 downto 0) := (others => '0');
	signal t_din_i 			: std_logic_vector (7 downto 0) := (others => '0');
	signal t_rx_done_tick_o : std_logic := '0';
	signal t_tx_start_i 	: std_logic := '0';
	signal t_tx_done_tick_o : std_logic := '0';
	
	-- BRAM Signals
	signal t_addra 			: std_logic_vector(ADDR_WIDTH - 1 downto 0);
	signal t_dina           : std_logic_vector(t_RAM_WIDTH-1 downto 0);  
	signal t_douta          : std_logic_vector(t_RAM_WIDTH-1 downto 0);                       
	signal t_wea            : std_logic;            
	
	type states is (S_IDLE, S_OKU, S_YAZ, S_TRANSMIT);
	signal state : states := S_IDLE;
	
	signal data_buffer : std_logic_vector (4*8-1 downto 0) := (others => '0'); -- 4 byte
	
	signal counter		: integer range 0 to 255 := 0;   -- 1 baytlık counter. Naıl oluyor?
                                
begin      

	i_uart_rx : uart_rx 
		generic map(
			c_clfreq 	 	=> t_clfreq,
			c_baudrate 		=> t_bauderrate
		)
		
		port map(
			clk 				=>	t_clk,
			rx_i 				=>	t_rx_i,
			dout_o		 		=>	t_dout_o,
			rx_done_tick_o  	=> 	t_rx_done_tick_o
		
		);
		
	i_uart_tx : uart_tx 
		generic map(
			c_clfreq 	 	=> t_clfreq,
			c_bauderrate 	=> t_bauderrate,
			c_stopbit	 	=> t_stopbit
		)
		
		port map(           
			clk 	        => t_clk,
			din_i		    => t_din_i,
			tx_start_i 		=> t_tx_start_i,
			tx_done_tick_o  => t_tx_done_tick_o,
			tx_o 	        => t_tx_o
		);
		
	ram128x16 : block_ram 
		generic map(
			RAM_WIDTH       => t_RAM_WIDTH,            
			RAM_DEPTH       => t_RAM_DEPTH,           
			RAM_PERFORMANCE => t_RAM_PERFORMANCE,     
			C_RAM_TYPE		=> t_C_RAM_TYPE		
		)
		
		port map(
			addra =>  t_addra,
			dina  =>  t_dina,
			clka  =>  t_clk,
			wea   =>  t_wea,  
			douta =>  t_douta 
		);
		
	P_MAIN : process (t_clk) begin
		if (rising_edge(t_clk)) then
		
			case state is
			
				when S_IDLE  	=>
				
					t_wea 	<= '0';
					counter <= 0;
					
					if (t_rx_done_tick_o = '1') then 							-- Fpga e bir veri geldiyse
						-- 4 baytlık buffer a veri geldikçe shift edicez
						data_buffer (7 downto 0) 		<= t_dout_o; 			-- Buffer ın en soluna ilk gelen 8 bit (1 byte) veriyi yazacak
						data_buffer (4*8-1 downto 1*8) 	<= data_buffer(3*8-1 downto 0*8); 	-- Sola öteleme
					end if;
					
					if (data_buffer (4*8-1 downto 3*8) = x"0A") then 			-- ilk byte x"0A" ise yaz durumuna git
						state <= S_YAZ;
					end if;
					
					if (data_buffer (4*8-1 downto 3*8) = x"0B") then			-- ilk byte x"0B" ise oku durumuna git
						state <= S_OKU;
					end if;
			
				when S_YAZ  	=>
						
					t_addra <= data_buffer (3*8-2 downto 2*8); -- Burda -2 yapmamızın nedeni. Toplam 128 adres var ve bu 6 bit ile kodlanır diğer 2 bite gerek yok
					t_dina	<= data_buffer (2*8-1 downto 0*8);
					t_wea  	<= '1';								-- Burda wea 1 olunca blok ram componentinde otomotik yazma gerçekleşiyor mu?
					-- t_douta	<= data_buffer (2*8-1 downto 0*8); Niye dout ayarlanmadı?
					state 	<= S_IDLE; -- Idle state ine geçerken yukarıdaki işlemleri yapmış olacak ve ıdle ın başında hemen wea 0 a çekilmiş oldu
				
				when S_OKU  	=>		-- Önce blok ramden ilgili veri okunur. Okunan veri data bufferın son iki baytına yazılacak
				
				-- Blok ramdan veriyi alabilmek için bir clock bekliyoruz ama niye? HIGH_PERFORMANCE desek 2 clock bekliyyecez
					
					t_addra <= data_buffer (3*8-2 downto 2*8);
					t_dina	<= data_buffer (2*8-1 downto 0*8);
					counter <= counter + 1; -- Bu şekilde bir clock beklemiş olduk
					
					if (counter = 1) then
						data_buffer (2*8-1 downto 0*8) 	<= t_douta;
						counter							<= 3;
						t_din_i							<= data_buffer(4*8-1 downto 3*8); 	-- Göndereceğimiz veriye ilk veriyi verdik
						t_tx_start_i				 	<= '1';								-- Sonra başlat dedik
						state   						<= S_TRANSMIT;						-- Başlat dediğimiz için transmit gönderiyor
					end if;
				
				when S_TRANSMIT =>		-- verilerimizi pc ye göndericez
					
					if (counter = 0) then	-- Burda artık 4 baytı göndermiş olduk
						t_tx_start_i <= '0';
						
						if (t_tx_done_tick_o = '1') then
							state <= S_IDLE;
						end if;
					
					else
						-- Burda counter 1 değil. Yukarda ilk baytı göndermeye başladı ve burya geldiğinde hemen sonraki datayı göndermek için hazırlamış oldu. 
						-- Herhalde de bunu amacı fazladan bir clock gitmemesi için?
						t_din_i <= data_buffer (counter*8-1 downto (counter - 1)*8);
						
						if (t_tx_done_tick_o = '1') then   -- Eğer t_tx_done_tick_o 1 olursa 1 byte veri hazır onu pc ye gönder counter ı 1 azalt
							counter <= counter - 1;
						end if;
					end if;
				
			end case;
		end if;
	end process;

end Behavioral;
