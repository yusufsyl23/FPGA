library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity LFSR is

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
end LFSR;

architecture Behavioral of LFSR is

	-- load_i girişinin bir önceki değerini saklamak için. Amaç: edge (yükselen kenar) algılamak. 
	-- Örneğin load_i yi 1 yaptık ama hala içinde bulunduğumuz clock ta load_next = 0 olduğu için burada bir rising_edge algılanır ve input olarak
	-- verilen poly_i  polinom sinyaline yüklenir. Clock sonunda load_next te 1 olmuş olur. Her saat döngüsünde load_i 1 olduğunda bunu rising_edge olarak algolamaz.
	signal load_next : std_logic := '0';	
	signal polinom   : std_logic_vector (c_datawidth - 1 downto 0) := (c_datawidth - 1 => '1', others => '0'); -- 1000000000
	signal data_reg  : std_logic_vector (c_datawidth - 1 downto 0) := (c_datawidth - 1 => '1', others => '0'); -- 1000000000
	
	signal internal_enable : std_logic;
	
begin

	P_MAIN : process (clk) is 
		variable tmp : std_logic; -- Bu kullanım sayesinde beginden hemen sonra kullanılan veriable sadece bu process e özel omuş oluyor.
	begin
		
		if (rising_edge(clk)) then
		
			tmp 		:= '0';		-- tmp değişkeni her cycle'da sıfırlanır (XOR işlemi için)
			load_next 	<= load_i;
			
			-- Load sinyalinin rising_edge ini algılamak için load_next i bir flip-flop a aktarıyorum ve load_i 1 se ve henüz atamadığım değer (load_next)
			-- sıfırsa polinom = poly_i. polinom diye bir sinyal oluşturdum
			
			if (load_i = '1' and load_next = '0') then 
				polinom  <= poly_i;
				internal_enable <= '1';
				
			end if;
			
			if (internal_enable = '1') then	-- Enable olunca sayacak
				
				data_reg(c_datawidth - 1 downto 1) <= data_reg(c_datawidth - 2 downto 0);	-- data_reg sinyali sihft left yapıyor 
				
				-- data_reg(0) <= data_reg(0) xor data_reg(5) xor data_reg(6) xor data_reg(7);
				-- Biz bit sayısını generic tanımladığımız için dinamik bir yapı oldu bunu için aşağıdaki gibi bir for kullanmalıyız.
				-- Eğer generic olamsaydı ve direkt 10 bit olarak tanımlamış olsaydık yukarıdaki gibi yapabilirdik.
				
				-- Bir tane n bitlik std_logic_vector düşünün ve bunun bütün bitlerini birbirleri ile xor lamak istiyorum ama sadece polinom ile 
				-- seçilmiş bitleri xor lamam lazım. Bunun için bu polibom ile bu vektörün çıktısını and lersem sadece polinomun bir olduğu noktalar
				-- aynen aktarılır polinomun 0 olduğu noktalar ise and ile 0 olmuş olacak. Neden böyle bir şey yapıyoruz? 
				-- Çünkü 0 XOR işleminde etkisiz elemandır (1 xor 0 = 1, 0 xor 0 = 0). Dolayısıyla bütün bitleri polinom ile and yapayım . 
				-- Bu şekilde sadece polinomun 1 olduğu noktalar aynen aktarılmış olacak (0 ise 1 and 0 = 0. 1 ise 1 and 1 = 1).
				-- And işleminden sonra hepsini XOR larsam polinomda olmayan FF ler 0 geleceği için zaten 0 xor da etkisiz eleman. Geriye kalan 
				-- değerler istenilen polinom değerleri olmuş olacak
				
				-- Bu for yapısı c deki for gibi. For ne üreteceğinizi bilmiyorsanız kullanılmaması gereken bir aypıdır. Çünkü sıralı bir şey oluşturuyor.
				-- Burda ne oluşturacağına bakıp kullanabiliriz.
				-- En sadesi böyle olurmuş
				
				for i in 0 to c_datawidth - 1 loop		-- 0. bitten atamaya başlıyacağız
					tmp := (data_reg(i) and polinom(i)) xor tmp; 	-- Bu bir sequential(sıralı) bir atama aslında.
				end loop;
				
				data_reg(0) <= tmp;
				
			else
			
				internal_enable <= enable_i;
				
			end if;
		end if;
	end process;
	
	number_o <= data_reg;


end Behavioral;
