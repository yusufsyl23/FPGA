library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity pwm is
	generic (
		c_clkfreq : integer := 100_000_000;	
		c_pwmfreq : integer := 1000		-- 1 kiloherz olarak aldım ama top modülde 10 kiloherz alıcaz
		-- PWM i 1 khz lamamızın sebebi, hocamız internetten bakmış 100 hz altını tac-vsiye etmemişler. Göz ile ilgili bir parametre
	);
	
	port (
		clk 			: in STD_LOGIC;
		duty_cycle_i 	: in STD_LOGIC_VECTOR (6 downto 0);		-- 0-100 arasında olacak 7 bit yeterli
		pwm_o 			: out STD_LOGIC
	);
end pwm;

architecture Behavioral of pwm is

	-- fpga zamanı kaç vuruş yaptığına göre anlar burda fpgaa in her vuruşu 10 ns 100.000 defa vurursa 1 ms geçer ve 1 pwm oluşur.
	constant c_timerlim : integer := c_clkfreq / c_pwmfreq;	-- 100_000 saat darbesinden sonra bir PWM döngüsü tamamlanacak. 1 mili saniye sürecek.
	
	-- %100 pwm e uyumlu yazılmış bir kod. Ama millet diyorki %50 yi aşarsan dünyayı tersten görürsün.
	signal hightime : integer range 0 to c_timerlim := c_timerlim / 2;	-- başlangıçta %50 veriyoruz
	signal timer 	: integer range 0 to c_timerlim := 0;	
	
begin

	-- Aşağıdaki gibi yazınca * operatörünü tanımıyorum diye hata verdi. O yüzden STD_LOGIC_ARITH ekleyip CONV_INTEGER fonksiyonunu kullandım.
	-- hightime <= (c_timerlim / 100) * duty_cycle_i;   --HATALI
	
	-- Bu çarpma iki sabitin bir çarpımı olsaydı normal bir sayı olurdu. 
	-- duty_cycle_i değişken olduğu için bu çarpma işlemini fpga içinde bir tane DSP modül kullanarak yapacak.
	
	-- % oranını clock sayısına çeviriyoruz: (100000 / 100) * 40 = 40000 clock. Yani PWM çıkışı bu durumda 40000 clock boyunca HIGH olacak.
	-- 1 khz lik bir periot başladı (1 ms) periot başladı. PWM %10 olsun. 1 milisaniyenin ne kadarında high olacak. Bu süre hightime
	hightime <= (c_timerlim / 100) * CONV_INTEGER(duty_cycle_i);	
	
	process (clk) begin
		if (rising_edge(clk)) then
		
			if (timer = c_timerlim - 1) then
				-- 1 ms'lik PWM döngüsü tamamlandıysa sayaç sıfırlanır → yeni PWM periyodu başlar.
				timer <= 0;
				
			elsif (timer < hightime) then
			-- Eğer sayaç hâlâ hightime'ın altındaysa, çıkış 1 olur. Yani PWM sinyali HIGH düzeyde gönderilir.Bu süre dolana kadar çıkış HIGH kalır.
				pwm_o <= '1';
				timer <= timer + 1;
			
			else
			-- timer artık hightime'i geçtiyse → kalan süre boyunca çıkış LOW olur. Böylece PWM tamamlanır.
				pwm_o <= '0';
				timer <= timer + 1;
				
			end if;
		end if;
	end process;

end Behavioral;
