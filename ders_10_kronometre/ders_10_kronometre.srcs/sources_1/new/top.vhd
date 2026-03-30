library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
	generic (
		c_clkfreq : integer := 100_000_000
	);
	
	port (
		clk 		: in std_logic;							
		start_i 	: in std_logic;							-- Kartta iki düğme olacak. Biri start biri reset
		reset_i 	: in std_logic;
		seven_seg_o : out std_logic_vector (7 downto 0);	-- katot sinyalleri
		anodes_o 	: out std_logic_vector (7 downto 0)
	);
	
end top;

architecture Behavioral of top is
--------------------------------------------------------------------
-- COMPONENET DECLERATIONS
--------------------------------------------------------------------
	
	-- Debounce
	component debounce
		generic (
			c_clkfreq 		: integer := 100_000_000;
			c_deboune_time 	: integer := 1000;
			ilk_deger 		: std_logic := '0'
		);
		
		port (
			clk 	 : in std_logic;
			signal_i : in std_logic;
			signal_o : out std_logic	
		);
	end component;
	
	-- Bcd incrementor
	component bcd_incrementor
		generic (
			birlerlim 	: integer := 9;
			onlarlim 	: integer := 5
		);
	
		port (
			clk 		: STD_LOGIC;
			increment_i : STD_LOGIC;
			reset_i		: STD_LOGIC;
			birler_o	: STD_LOGIC_VECTOR (3 downto 0);
			onlar_o		: STD_LOGIC_VECTOR (3 downto 0)
		);
	end component;
	
	-- bcd_to_sevenseg
	component bcd_to_sevenseg
		port (
			bcd_i 		: in std_logic_vector(3 downto 0);
			sevenseg_o 	: out std_logic_vector(7 downto 0)
		);
	end component;
	
	--------------------------------------------------------------
	-- CONSTANT DEFINITIONS
	--------------------------------------------------------------
	
	constant timer1mslim 			: integer := c_clkfreq/1000;
	constant c_salise_counter_lim 	: integer := c_clkfreq/100;	-- 1 salise = 10 mili saniye. Burda 100 e bölmemizin sebebi. Saat 1 saniyede 100 milyon vuruyor. Onun için 100 e böldük
	constant c_saniye_counter_lim 	: integer := 100;			-- 100 saliseye kadar sayacak ve saniye 1 artacak
	constant c_dakika_counter_lim 	: integer := 60;			-- 60 saniyeye kadar sayacak ve dakika 1 artacak
	
	--------------------------------------------------------------
	-- SIGNAL DEFINITIONS
	--------------------------------------------------------------
	signal salise_increment 	: std_logic := '0';
	signal saniye_increment 	: std_logic := '0';
	signal dakika_increment 	: std_logic := '0';
	
	signal start_deb 			: std_logic := '0';
	signal reset_deb 			: std_logic := '0';
	signal continue  			: std_logic := '0';
	signal start_deb_prev 		: std_logic := '0';
	
	signal salise_birler 		: std_logic_vector(3 downto 0) := (others => '0');
	signal salise_onlar 		: std_logic_vector(3 downto 0) := (others => '0');
	signal saniye_birler 		: std_logic_vector(3 downto 0) := (others => '0');
	signal saniye_onlar 		: std_logic_vector(3 downto 0) := (others => '0');
	signal dakika_birler 		: std_logic_vector(3 downto 0) := (others => '0');
	signal dakika_onlar 		: std_logic_vector(3 downto 0) := (others => '0');
	
	signal salise_birler_7seg 	: std_logic_vector(7 downto 0) := (others => '1');
	signal salise_onlar_7seg 	: std_logic_vector(7 downto 0) := (others => '1');
	signal saniye_birler_7seg 	: std_logic_vector(7 downto 0) := (others => '1');
	signal saniye_onlar_7seg 	: std_logic_vector(7 downto 0) := (others => '1');
	signal dakika_birler_7seg 	: std_logic_vector(7 downto 0) := (others => '1');
	signal dakika_onlar_7seg 	: std_logic_vector(7 downto 0) := (others => '1');
	
	signal anodes 				: std_logic_vector(7 downto 0) := "11111110";  -- ilk başta en sağdaki led yanacak. Sağdan sola döngü olacak
	
	signal timer1ms 			: integer range 0 to timer1mslim := 0;	
	signal salise_counter		: integer range 0 to c_salise_counter_lim := 0;	
	signal saniye_counter		: integer range 0 to c_saniye_counter_lim := 0;	
	signal dakika_counter		: integer range 0 to c_dakika_counter_lim := 0;	
	
begin

--------------------------------------------------------------
-- DEBOUNCE INSTANTIATIOS
--------------------------------------------------------------

	i_start_deb : debounce
	generic map (
		c_clkfreq 		=> c_clkfreq,
		c_deboune_time 	=> 1000,
		ilk_deger 		=> '0'
	)
		
	port map(
		clk 	 => clk,
		signal_i => start_i,
		signal_o => start_deb
	);
	
	i_reset_deb : debounce
	generic map (
		c_clkfreq 		=> c_clkfreq,
		c_deboune_time 	=> 1000,
		ilk_deger 		=> '0'
	)
	
	port map (
		clk 	 => clk,
		signal_i => reset_i,
		signal_o => reset_deb
	);
	
--------------------------------------------------------------
-- BCD_INCREMENTOR INSTANTIATIOS
--------------------------------------------------------------
	i_salise_incrementor : bcd_incrementor
	generic map (
		birlerlim 	=> 9,
		onlarlim 	=> 5
	)
	
	port map (
		clk 		=> clk,
		increment_i => salise_increment,
		reset_i 	=> reset_deb,
		birler_o 	=> salise_birler,
		onlar_o		=> salise_onlar
	);
	
	i_saniye_incrementor : bcd_incrementor
	generic map (
		birlerlim 	=> 9,
		onlarlim 	=> 5
	)
	
	port map (
		clk 		=> clk,
		increment_i => saniye_increment,
		reset_i 	=> reset_deb,
		birler_o	=> saniye_birler,
		onlar_o 	=> saniye_onlar
	);
	
	i_dakika_incrementor : bcd_incrementor
	generic map (
		birlerlim 	=> 9,
		onlarlim 	=> 5
	)
	
	port map (
		clk 		=> clk,
		increment_i => dakika_increment,
		reset_i 	=> reset_deb,
		birler_o	=> dakika_birler,
		onlar_o 	=> dakika_onlar
	);
	
--------------------------------------------------------------
-- bcd_to_sevenseg INSTANTIATIOS
-- girişler zaten bcd_icrementor dan geldi çıkış için hemen yukarıda sinyal tanımladık
--------------------------------------------------------------
	-- salise
	i_salise_birler : bcd_to_sevenseg
	port map(
		bcd_i 		=> salise_birler,
		sevenseg_o 	=> salise_birler_7seg
	);
	
	i_salise_onlar : bcd_to_sevenseg
	port map(
		bcd_i 		=> salise_onlar,
		sevenseg_o 	=> salise_onlar_7seg
	);
	
	-- saniye
	i_saniye_birler : bcd_to_sevenseg
	port map(
		bcd_i 		=> saniye_birler,
		sevenseg_o 	=> saniye_birler_7seg
	);
	
	i_saniye_onlar : bcd_to_sevenseg
	port map(
		bcd_i 		=> saniye_onlar,
		sevenseg_o 	=> saniye_onlar_7seg
	);
	
	-- dakika
	i_dakika_birler : bcd_to_sevenseg
	port map(
		bcd_i 		=> dakika_birler,
		sevenseg_o 	=> dakika_birler_7seg
	);
	
	i_dakika_onlar : bcd_to_sevenseg
	port map(
		bcd_i 		=> dakika_onlar,
		sevenseg_o 	=> dakika_onlar_7seg
	);
	
--------------------------------------------------------------
-- ANODE PROCESS
--------------------------------------------------------------
	P_ANODES : process (clk) begin
		if (rising_edge(clk)) then
			anodes (7 downto 6) <= "11"; -- En soldaki 2 seven segmen ile işimiz yok. Bize sağdan 6 tane lazım
		
		-- Anodların hepsini aynı anda yakamayız 6 tanesinde gezdirmemiz gerek. Refresh period = 1-16 ms arası. Bu aralıkta olursa göz bunu anlayamaz.
			if (timer1ms = timer1mslim - 1) then
				timer1ms 			<= 0;
				anodes(5 downto 1) 	<= anodes(4 downto 0);	-- bir sola kaydır
				anodes(0) 			<= anodes(5);			-- döngü sağlanıyor (kaydırılan en soldaki sağa geliyor)
				
			else
				timer1ms			<= timer1ms + 1;
				
			end if;
		end if;
		
	end process;
	
--------------------------------------------------------------
-- CATHODES PROCESS
--------------------------------------------------------------
	P_CATHODES : process (clk) begin
		if (rising_edge(clk)) then
			
			-- Anotta PNP transistör olduğu için 0 olunca akımı geçiriyor 1 olunca kesiyor
			-- anot = '0' ise -> transistör iletimde -> VCC bağlanır -> Display aktif olur
 			-- anot = '1' ise -> transistör kesimde -> VCC kesilir -> Display pasif olur
			
			if (anodes(0) = '0') then
				seven_seg_o <= salise_birler_7seg;
			
			elsif (anodes(1) = '0') then
				seven_seg_o <= salise_onlar_7seg;
				
			elsif (anodes(2) = '0') then
				seven_seg_o <= saniye_birler_7seg;
				
			elsif (anodes(3) = '0') then
				seven_seg_o <= saniye_onlar_7seg;
				
			elsif (anodes(4) = '0') then
				seven_seg_o <= dakika_birler_7seg;
				
			elsif (anodes(5) = '0') then
				seven_seg_o <= dakika_onlar_7seg;
				
			else
				seven_seg_o <= (others => '1');
			
			end if;
		end if;
	
	end process;
	
	P_MAIN : process (clk) begin
		if (rising_edge(clk)) then
			
			start_deb_prev  <= start_deb;
			
			-- start_deb eğer birse start_deb_prev (bir önceki durum) de sıfırsa bu bir rise edge dir
			if (start_deb = '1' and start_deb_prev = '0') then
				continue <= not continue; -- Eğer basıldıysa tam tersi olsun. Start\Stop
				
			end if;
			
			salise_increment	<= '0';
			saniye_increment	<= '0';
			dakika_increment	<= '0';
			
			if (continue = '1') then
				-- Aslına bu mantık çark sistemi gibi geriden geliyor.
				if (salise_counter = c_salise_counter_lim - 1) then
					salise_counter 		<= 0;
					salise_increment 	<= '1';
					saniye_counter		<= saniye_counter + 1; -- 1 salise geçti. Saniye 100 e kadar sayacak 100 olunca 1 artacak.
				
				else
					salise_counter		<= salise_counter + 1;
				
				end if;
				
				if (saniye_counter = c_saniye_counter_lim - 1) then		-- c_saniye_counter_lim 100 salise olur
					saniye_counter 		<= 0;
					saniye_increment 	<= '1';
					dakika_counter		<= dakika_counter + 1; 			-- 1 saniye geçti
				
				else
					saniye_counter		<= saniye_counter + 1;
				
				end if;
				
				if (dakika_counter = c_dakika_counter_lim - 1) then		-- c_dakika_counter_lim 60 saniye olur
					dakika_counter 		<= 0;
					dakika_increment 	<= '1';
				
				end if;
			end if;
			
			if (reset_deb = '1') then
				salise_counter <= 0;
				saniye_counter <= 0;
				dakika_counter <= 0;
				
			end if;
		end if; 
	
	end process;
	

end Behavioral;
