library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LFSR_tb is
	
	generic(
		tb_datawidth : integer := 10
	);
end LFSR_tb;

architecture Behavioral of LFSR_tb is

	component LFSR is

	generic (
		c_datawidth : integer := 10	-- Kaç bitlik bir lfsr olacağı generic olsun istediğimiz zaman değiştirelim.
	);
	
	port (
		clk 		: in std_logic;
		load_i 		: in std_logic;		-- Load a basınca bu polinomu yükleyeceğiz
		enable_i 	: in std_logic;		-- 1 olduğunda LFSR adım atar
		poly_i 	 	: in std_logic_vector (c_datawidth - 1 downto 0);	-- Polinomu input olarak alırsak farklı polinomlar deneyebiliriz
		number_o 	: out std_logic_vector (c_datawidth - 1 downto 0)	-- Bu çıkış LFSR’nin o anki durumunu (data_reg) dışarı verir.
																	-- Yani her clock çevriminden sonra üretilen sayı number_o portundan okunabilir.
	);
	end component;
	
	signal tb_clk 			: std_logic := '0';	
	signal tb_load_i 		: std_logic := '0';		
    signal tb_enable_i 		: std_logic := '0';		
	signal tb_poly_i		: std_logic_vector (tb_datawidth - 1 downto 0) := (tb_datawidth - 1 => '1', others => '0');
    signal tb_number_o 		: std_logic_vector (tb_datawidth - 1 downto 0);
	
	-- Binary bir counter olsaydı sistem her clock saydıkça nasıl bir hareket göreceğiz? 1024 te bir overflow olacak çünkü 10 bit 
	signal binary			: std_logic_vector (tb_datawidth - 1 downto 0) := (others => '0');
	
	constant c_clkperiod	: time := 10 ns;
	
begin

	P_CLKGEN : process begin 
		
		tb_clk <= '0';
		wait for c_clkperiod/2;
		
		tb_clk <= '1';
		binary <= binary + '1';
		wait for c_clkperiod/2;

	end process;
	
	DUT : LFSR
		generic map (
			c_datawidth => tb_datawidth
		)
		
		port map (
			clk 	 => tb_clk, 	
			load_i 	 => tb_load_i,	
			enable_i => tb_enable_i,
			poly_i 	 => tb_poly_i, 	
			number_o => tb_number_o
		);
	
	STIMULI : process begin
	
		tb_enable_i <= '0';
		
		wait for c_clkperiod*10; -- 20 clock bekledik

		tb_poly_i <= "1001000000";
		-- tb_poly_i <= "1101100000";
		tb_load_i <= '1';
		
		wait for c_clkperiod; -- 1 clock bekle. Amaç: Load işleminin tamamlanmasını sağlamak
		
		tb_load_i <= '0';
		tb_enable_i <= '1';
		
		wait for c_clkperiod*1100; -- 1100 periyot bekle. 1024 te bir tekrardan başa dönmesi lazım
		--Amaç: LFSR'nin tüm durumlarını test etmek ve döngüsel davranışı kontrol etmek

		--Etkisi:

		-- 10-bit LFSR teorik olarak 1023 unique state üretmeli (2^10 - 1)
		-- 1100 cycle bekleyerek:
		-- LFSR'nin tüm durumları dolaştığından emin olunur
		-- Döngünün 1024. adımda başa dönüp dönmediği kontrol edilir
		-- Eğer polinom doğru seçilmişse, 1023 adımda tüm durumlar görülmeli ve 1024'te başlangıç durumuna dönmeli
		
		assert false
		report "Simulasyon Bitti"
		severity failure;
		
	
	end process;
	
	
end Behavioral;
