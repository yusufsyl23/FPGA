library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tb_pwm is
	generic (
		tb_c_clkfreq 	: integer := 100_000_000;
		tb_c_pwmfreq	: integer := 1000
	);
end tb_pwm;

architecture Behavioral of tb_pwm is

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
	
	-- pwm modülündeki giriş ve çıkşılar ile bu sinyalleri karıştırma. Onlar o modüle ayit. Test bench için bir daha tanımlamalıyız.
	signal tb_clk 			: STD_LOGIC;
	signal tb_duty_cycle_i 	: STD_LOGIC_VECTOR (6 downto 0);
	signal tb_pwm_o			: STD_LOGIC := '0';
	
	constant c_clkperiod 	: time := 10 ns; -- 10 ns = 100 Mhz

begin

	DUT : pwm
	generic map (
		c_clkfreq => tb_c_clkfreq,
		c_pwmfreq => tb_c_pwmfreq
	)
	
	port map (
		clk				=> tb_clk,
		duty_cycle_i	=> tb_duty_cycle_i,
		pwm_o			=> tb_pwm_o
	);

	-- Bu süreç bir saat (clock) üreticidir.Sürekli olarak clk sinyalini 0 → 1 → 0 yapar.wait for c_clkperiod / 2: Yarım periyot bekle → 5 ns
	-- Bir periyot: 10 ns frekans 100 MHz. Bu saat sinyali pwm modülünün clk girişine bağlanmıştı.
	
	P_CLKGEN : process begin
		tb_clk <= '0';
		wait for c_clkperiod / 2;
		
		tb_clk <= '1';
		wait for c_clkperiod / 2;
	
	end process;
	
	P_STIMULI :process begin	-- TEST SİNYALİ ÜRETİCİ
		
		tb_duty_cycle_i 	<= CONV_STD_LOGIC_VECTOR(0,7); 		-- 0 sayısını 7 bit olarak binary gösterir 
		
		wait for 5 ms;
		tb_duty_cycle_i 	<= CONV_STD_LOGIC_VECTOR(10,7); 	-- %10 PWM → her 1 ms'de 0.1 ms HIGH, 0.9 ms LOW
		
		wait for 5 ms;
		tb_duty_cycle_i 	<= CONV_STD_LOGIC_VECTOR(20,7); 
		
		wait for 5 ms;
		tb_duty_cycle_i 	<= CONV_STD_LOGIC_VECTOR(30,7); 
		
		wait for 5 ms;
		tb_duty_cycle_i 	<= CONV_STD_LOGIC_VECTOR(40,7); 
		
		wait for 5 ms;
		tb_duty_cycle_i 	<= CONV_STD_LOGIC_VECTOR(50,7); 
		
		wait for 5 ms;
		tb_duty_cycle_i 	<= CONV_STD_LOGIC_VECTOR(90,7); 
		
		wait for 5 ms;
		
		assert false
		report "SIMILASYON BITTI"
		severity failure;
		
	end process;

end Behavioral;
