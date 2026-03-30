library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity top is
	generic (
		c_clkfreq : integer := 100_000_000;	-- Frekans : 1 saniyede 100 milyon kez vuruyor (100 Mhz). Her bir clock (periyot)10 ns sürer
		c_pwmfreq : integer := 10_000		-- Burda 10 kilo herz aldık
	);
	
	port (
		clk 		: in std_logic;
		led_color_i : in std_logic_vector (5 downto 0);		-- 6 led için 6 switch kullanıcaz
		led_color_o : out std_logic_vector (5 downto 0)
		
	);
end top;

architecture Behavioral of top is

-----------------------------------------------------------
-- COMPONENET DECLERATION
-----------------------------------------------------------
	component pwm is
	
	generic (
		c_clkfreq : integer := 100_000_000;
		c_pwmfreq : integer := 1000		
	);
	
	port (
		clk 			: in STD_LOGIC; 
		duty_cycle_i 	: in STD_LOGIC_VECTOR (6 downto 0);	
		pwm_o 			: out STD_LOGIC
	);
	
	end component;
	
-----------------------------------------------------------
-- CONSTANT DEFINITIONS
-----------------------------------------------------------
	constant c_counterlim 	: integer := 100;				-- PWM duty_cycle değeri 0–50 arasında gidip gelmek için 100 adım kullanılacak.
	constant c_timer50hzlim : integer := c_clkfreq / 50;
	
-----------------------------------------------------------
-- SIGNAL DEFINITIONS
-----------------------------------------------------------
	signal duty_cycle_ld17 	: std_logic_vector (6 downto 0) := (others => '0');
	signal duty_cycle_ld16 	: std_logic_vector (6 downto 0) := (others => '0');
	signal pwm_ld17			: std_logic := '0';
	signal pwm_ld16			: std_logic := '0';
	signal counter 			: integer range 0 to c_counterlim 	:= 0;
	signal timer50hz 		: integer range 0 to c_timer50hzlim := 0;		-- 20 ms de bir 1 azalt veya arttır
	
begin

-----------------------------------------------------------
-- COMPONENENT INSTANTIATIONS
-----------------------------------------------------------
	i_pwm_ld17 : pwm
	generic map (
		c_clkfreq => c_clkfreq,
		c_pwmfreq => c_pwmfreq
	)
	
	port map (
		clk 		 => clk,
		duty_cycle_i => duty_cycle_ld17,
		pwm_o		 => pwm_ld17
	);
	
	i_pwm_ld16 : pwm
	generic map (
		c_clkfreq => c_clkfreq,
		c_pwmfreq => c_pwmfreq
	)
	
	port map (
		clk 		 => clk,
		duty_cycle_i => duty_cycle_ld16,
		pwm_o		 => pwm_ld16
	);
	
-----------------------------------------------------------
-- CONCURRENT SIGNAL ASSIGMENTS
-----------------------------------------------------------
-- Aşağıdaki şekilde yazınca "0 definitions of operator '-' match here" hatası aldım.
-- Çünkü duty_cycle_ld16 'std_logic_vector' tipinde, eşitliğin sağ tarafı ise integer tipinde.
-- Sonuç olarak STD_LOGIC_ARITH paketi içindeki CONV_STD_LOGIC_VECTOR fonksiyonunu kullandık.

-- duty_cycle_ld16 <= 50 - CON_INTEGER(duty_cycle_ld17);
	
duty_cycle_ld16 <= CONV_STD_LOGIC_VECTOR((50 - CONV_INTEGER(duty_cycle_ld17)),7);

-----------------------------------------------------------
-- MAIN PROCESS
-----------------------------------------------------------	
-- duty_cycle 1 saniye boyunca 0 dan 50 ye çıkacak. Bunu %1 lik adımlar ile çıkıcaz. %0 dan %50 ye kadar ker 20 ms de bir duty_cycle ı 1 arttır
-- %50 den sonra geriye doğru her 20 ms de bir 1 azaltıcaz
	P_MAIN : process (clk) begin
		if (rising_edge(clk)) then
		-- Ardışıl (sequantial) devrelerde eşitliğin sol tarafı hep bir flip-flop yani register yani hafıza
		
			if (counter < c_counterlim / 2) then				-- 50 den küçükse. Burası yaklaşık 1 saniye çünkü 20 ms x 50 1000 ms oda 11 saniye eder
				if (timer50hz = c_timer50hzlim - 1) then		-- 20 ms geçtiyse
					duty_cycle_ld17 <= duty_cycle_ld17 + 1;
					timer50hz		<= 0;
					counter			<= counter + 1;
				else 
					timer50hz <= timer50hz + 1;
				end if;
				
			else
			
				if (timer50hz = c_timer50hzlim - 1) then		-- 20 ms geçtiyse 
					if (counter = c_counterlim) then			-- counter 100 e eşit mi yani 2. saniye doldu mu
						counter <= 0;
					else 
						counter 		<= counter + 1;
						duty_cycle_ld17 <= duty_cycle_ld17 - 1;
					end if;
					
					timer50hz <= 0;
					
				else
					timer50hz <= timer50hz + 1;
					
				end if;	
			end if;
		end if;
	end process;
	
-----------------------------------------------------------
-- COMBINATIONAL OUTPUT PROCESS
-----------------------------------------------------------	
	--P_COMB_OUT : process (led_color_i,pwm_ld17,pwm_ld16) begin
		
		-- Burda led_color_i ve pwm_ld17 bir flip-flop. Bu iki flip-flop u alıp bir look up table a koyuyor ve çıktısını direkt dışarı veriyor.
		-- Bu istenen bir şey değil. Senkronizasyon için flip-flop (register) ile output ver.
		-- Eğer böyle yaparsak çıktılar bir look up table ın outputu olacak ve bu timing için doğru değil.
		-- Ardışıl yaparsak çıkışlar fpga dışında bir flip-flop un outputu olur 
		-- FPGA dışına çıkması çok sorun değil. FPGA içinde başka bir modüle giriyorsa senkronize olmadığı için timing analizi için sıkıntı olur 	
		
		--led_color_o(5) <= led_color_i(5) and pwm_ld17;		-- LED17 RED
		--led_color_o(4) <= led_color_i(4) and pwm_ld17;		-- LED17 GREEN
		--led_color_o(3) <= led_color_i(3) and pwm_ld17;		-- LED17 BLUE
		
		--led_color_o(2) <= led_color_i(2) and pwm_ld16;		-- LED17 RED
		--led_color_o(1) <= led_color_i(1) and pwm_ld16;		-- LED17 GREEN
		--led_color_o(0) <= led_color_i(0) and pwm_ld16;		-- LED17 BLUE

	--end process;
	
	P_REG_OUT : process (clk) begin
		if (rising_edge (clk)) then
		
			led_color_o(5) <= led_color_i(5) and pwm_ld17;		-- LED17 RED
			led_color_o(4) <= led_color_i(4) and pwm_ld17;		-- LED17 GREEN
			led_color_o(3) <= led_color_i(3) and pwm_ld17;		-- LED17 BLUE
			
			led_color_o(2) <= led_color_i(2) and pwm_ld16;		-- LED17 RED
			led_color_o(1) <= led_color_i(1) and pwm_ld16;		-- LED17 GREEN
			led_color_o(0) <= led_color_i(0) and pwm_ld16;		-- LED17 BLUE
		
		end if;
	end process;
	
-- senkron devrede devredeki tüm değişimler yükselen kenarda olur ama kombinasyonelde her an bir değişim olabilir. 
-- https://chatgpt.com/share/686d3489-56e0-8002-b900-99b1e37e0ddf

end Behavioral;
