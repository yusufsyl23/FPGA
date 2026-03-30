--------------------------------------------------------------------------------
-- YAZAR:            	MEHMET BURAK AYKENAR
-- OLUŞTURULDU:      	09.12.2019
-- REVİZYON TARİHİ:    	09.12.2019
--
--------------------------------------------------------- -----------------------
-- AÇIKLAMA:        
--    Bu modül, SPI iletişim arayüzünün ana kısmını uygular ve herhangi bir SPI slave IC ile kullanılabilir.
 
--    Slave IC'den okuma yapmak için, mosi_data_i giriş sinyali istenen değere atanmalı ve en_i sinyali yüksek olmalıdır. 
--    Slave IC'ye yazmak için en_i giriş sinyali yüksek olmalıdır. 
--    data_ready_o çıkış sinyali, okuma ve/veya yazma işlemi bittiğinde bir saat döngüsü boyunca mantıksal yüksek değere sahiptir. miso_data_o  
-- çıkış sinyali slave IC'den okunan verileri içerir. 
--    Arka arkaya okuma ve/veya yazma yapmak için en_i sinyali yüksek tutulmalıdır. İşlemi sonlandırmak için, data_ready_o çıkış sinyali yüksek 
-- olduğunda en_i giriş sinyali sıfıra atanmalıdır.

---------------------------------------------------------------------- ----------
-- Sınırlama/Varsayım: Bu modülü doğru şekilde kullanmak için,  (c_clkfreq / c_sclkFreq) oranı 8 veya daha fazla olmalıdır. 
--    Daha yüksek SCLK frekansları mümkündür, ancak daha ayrıntılı çalışma gereklidir.
-- Notlar: c_cpol ve c_cpha parametreleri sırasıyla saat polaritesi ve saat fazıdır.
---------------------------------------------------------------------------- ----
-- VHDL DIALECT: VHDL '93
--
---------------------------------------------------------------------------- ----
-- PROJE     : Genel amaçlı
-- KART     : Genel amaçlı
-- VARLIK     : spi_master
-------------------------------------------------------------- ------
-- DOSYA     : spi_master.vhd
------------------------------------------------------------------------------- -
-- REVİZYON GEÇMİŞİ:
-- REVİZYON  TARİH          YAZAR        YORUM
-- --------  ----------  ------------  -----------
-- 1.0         19.12.2019	 M.B.AYKENAR   İLK REVİZYON
--------------------------------------------------------------------------------

--Translated with DeepL.com (free version)
 
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
 
entity spi_master is
generic (
	c_clkfreq 			: integer := 100_000_000;
	c_sclkfreq 			: integer := 1_000_000;
	c_cpol				: std_logic := '0';
	c_cpha				: std_logic := '0'
);
Port ( 
	clk_i 			: in  STD_LOGIC;
	en_i 			: in  STD_LOGIC;						-- SPI transferini başlatmak için
	mosi_data_i 	: in  STD_LOGIC_VECTOR (7 downto 0);	-- Master’ın slave’e göndermek istediği 8 bitlik veri (byte). Kullanıcı bu porta yazdığı veriyi SPI hattı üzerinden slave’e yollar.
	miso_data_o 	: out STD_LOGIC_VECTOR (7 downto 0);	-- Slave’den okunan 8 bitlik veri (byte).
	data_ready_o 	: out STD_LOGIC;						-- Slave’den okunan byte’ın hazır olduğunu gösteren bayrak.
	cs_o 			: out STD_LOGIC;						-- SPI’deki chip select (slave select) hattıdır. Slave’i seçmek için kullanılır.
	sclk_o 			: out STD_LOGIC;						-- Slave’e gönderilecek SPI clock sinyali. Dışarıya verilen SPI clock hattı (slave cihaz bu sinyali görür).
	mosi_o 			: out STD_LOGIC;						-- Master → Slave veri çıkışı. Master, slave’e komut veya veri göndermek için bu hattı kullanır.
	miso_i 			: in  STD_LOGIC							-- Slave → Master veri girişi.
	
	-- sclk_o, mosi_o, miso_i bunlar ise slave arayüzleri
);
end spi_master;
 
architecture Behavioral of spi_master is
 
--------------------------------------------------------------------------------
-- CONSTANTS
constant c_edgecntrlimdiv2	: integer := c_clkfreq/(c_sclkfreq*2); 
-- Burda ikiye bölmesinin sebebi bir clockta 2 defa not deyip clock değerini değiştirecek. İlk nıt dediğinde 1 olacak sonra bir daha not deyince 0 olacak.
-- Böylelikle clock üretmiş olacağız
 
--------------------------------------------------------------------------------
-- INTERNAL SIGNALS
signal write_reg	: std_logic_vector (7 downto 0) 	:= (others => '0');		-- MOSI’ye sırayla çıkarılacak bitler (MSB-first).
signal read_reg		: std_logic_vector (7 downto 0) 	:= (others => '0');		-- MISO’dan toplanan bitler (LSB’ye doğru kaydırıp MSB’yi doldurma tekniği).
 
signal sclk_en		: std_logic := '0';		-- sclk üretilmeye başlasın mı? en_i = 1 olunca sclk_en de 1 olur ve edgecntr işlemeye başlar
signal sclk			: std_logic := '0';		-- İç clock sinyali. P_SCLK_GEN prosesi içinde, sistem saatinden (clk_i) bölünerek toggle edilir.
signal sclk_prev	: std_logic := '0';		-- Bir önceki clk değerini tutabilmek için oluşturulnuş. Bu şekilde kenar değişikliği tespiti yapıcaz.
signal sclk_rise	: std_logic := '0';		
signal sclk_fall	: std_logic := '0';
 
signal pol_phase	: std_logic_vector (1 downto 0) := (others => '0');
signal mosi_en		: std_logic := '0';		-- Ne zaman slave den gelen veriyi örnekleyeceğiz.
signal miso_en		: std_logic := '0';		-- Ne zaman dışarı veri vermem lazım.
signal once         : std_logic := '0';		-- Yani “ben bu byte için data_ready_o’yu sadece 1 clock yüksek yapacağım, kullanıcı da o anda alacak” garantisi veriyor.
 
signal edgecntr		: integer range 0 to c_edgecntrlimdiv2 := 0;
 
signal cntr 		: integer range 0 to 15 := 0;
 
--------------------------------------------------------------------------------
-- STATE DEFINITIONS
type states is (S_IDLE, S_TRANSFER);
signal state : states := S_IDLE;
 

begin
 
pol_phase <= c_cpol & c_cpha;	-- c_cpha 0. bit c_cpol 1. bit. Bu şekilde 4 farklı moddan bir tanesi seçilecek
 
--------------------------------------------------------------------------------
-- SAMPLE_EN işlemi, pol_phase sinyali aracılığıyla c_cpol ve c_cpha genel parametrelerine göre mosi_en ve miso_en iç sinyallerini 
--kombinasyonel mantıkta sclk_fall veya sclk_rise'a atar.
P_SAMPLE_EN : process (pol_phase, sclk_fall, sclk_rise) begin
 
	case pol_phase is
	
		-- CPOL=0 → Idle durumda SCLK=0 (saat düşükte bekler).
		-- CPOL=1 → Idle durumda SCLK=1 (saat yüksekte bekler).
		
		-- CPHA=0 → İlk aktif kenarda örnekleme yapılır.
		-- CPHA=1 → İlk aktif kenarda veri hazırlanır, sonraki kenarda örnekleme yapılır.
 
		when "00" =>     			-- MOSI düşende hazırlanır, MISO yükselende örneklenir.
 
			mosi_en <= sclk_fall;	-- Alçalan kenarda veriyi vermeliyim ki yükselen kenarda slave onu alabilsin
			miso_en	<= sclk_rise;	-- Slave den gelen veriyi yükselen kenarda örneklemeliyim
 
		when "01" =>
 
			mosi_en <= sclk_rise;
			miso_en	<= sclk_fall;		
 
		when "10" =>
 
			mosi_en <= sclk_rise;
			miso_en	<= sclk_fall;			
 
		when "11" =>
 
			mosi_en <= sclk_fall;
			miso_en	<= sclk_rise;	
 
		when others =>
 
	end case;
 
end process P_SAMPLE_EN;
 
--------------------------------------------------------------------------------
--    RISEFALL_DETECT işlemi, kombinasyonel mantıkta sclk_rise ve sclk_fall sinyallerini atar.
P_RISEFALL_DETECT : process (sclk, sclk_prev) begin
 
	if (sclk = '1' and sclk_prev = '0') then
		sclk_rise <= '1';
	else
		sclk_rise <= '0';
	end if;
 
	if (sclk = '0' and sclk_prev = '1') then
		sclk_fall <= '1';
	else
		sclk_fall <= '0';
	end if;	
 
end process P_RISEFALL_DETECT;
 
--------------------------------------------------------------------------------
-- MAIN sürecinde S_IDLE ve S_TRANSFER durumları uygulanır. en_i giriş sinyali mantıksal yüksek değere sahip olduğunda durum S_IDLE'den 
-- S_TRANSFER'e geçer. Bu döngüde, write_reg sinyali mosi_data_i giriş sinyaline atanır. c_cpha genel parametresine göre, işlem işlemi biraz değişir. 
-- Bu işlem farkı, SVN sunucusunda bulunan SPI'nın Belgeler klasöründe bulunan belgede ayrıntılı olarak açıklanmaktadır.

P_MAIN : process (clk_i) begin
if (rising_edge(clk_i)) then
 
    data_ready_o <= '0';
	sclk_prev	<= sclk;
 
	case state is
 
--------------------------------------------------------------------------------	
		when S_IDLE =>	
	
			-- SPI protokolüne göre CS, slave cihazı seçmek için aktif (düşük) olmalıdır. Burada pasif olduğu için hiçbir slave ile haberleşme yapılmadığını gösterir.
			cs_o			<= '1';		
			mosi_o			<= '0';
			data_ready_o	<= '0';			
			sclk_en			<= '0';
			cntr			<= 0; 
 
			if (c_cpol = '0') then
				sclk_o	<= '0';
			else
				sclk_o	<= '1';
			end if;	
 
			if (en_i = '1') then
				state		<= S_TRANSFER;
				sclk_en		<= '1';
				write_reg	<= mosi_data_i;		-- Yazacağım datayı burdan al
				mosi_o		<= mosi_data_i(7);	-- Bunu burda ayarlamamızın sebebi cpha 0 olma durumu için. Çünkü bu durumda ilk yükselen kenarda örnekleme olur. Ondan önce veri hazır olmalıydı.
				read_reg	<= x"00";			--  Slave'den okunacak veriyi tutacak olan kaydırma yazmacını sıfırlar. Bir önceki transferden kalan veriyi temizler.
			end if;
 
--------------------------------------------------------------------------------

-- Transfer durumunda c_cpha durumuna göre tek tek SAMPLE_EN deürettiğimiz miso_en ve mosi_en lara göre veriyi örnekliyor shift ediyor sırayla
			
		when S_TRANSFER =>		
 
			cs_o	<= '0';
			mosi_o	<= write_reg(7); -- Kaydırma yazmacının en anlamlı bitini (MSB) sürekli olarak MOSI hattına bağlar.
 
 
			if (c_cpha = '1') then	 --  (Mode 1 ve Mode 3) için Transfer
 
				if (cntr = 0) then
					sclk_o	<= sclk;			-- Dahili olarak üretilen sclk sinyalini, dış dünyaya çıkış (sclk_o) olarak verir.
					if (miso_en = '1') then		-- Dışarı veri verecez. Okuma yapacaz. Örnekleme yapacaz.MISO hattından veriyi örneklemek için doğru anı (SPI clock'unun düşen kenarı) bekler.
						read_reg(0)				<= miso_i;
						read_reg(7 downto 1) 	<= read_reg(6 downto 0);
						cntr					<= cntr + 1;
						once                    <= '1';		-- data_ready_o sinyalinin sadece bir kere 1 yapılmasını sağlayacak bir bayrak (flag) kurar.
					end if;	
					
				elsif (cntr = 8) then
				    if (once = '1') then
				        data_ready_o	<= '1';
				        once            <= '0';				       
				    end if;	
					
					miso_data_o		<= read_reg;	--  Okuma kaydırmacındaki tamamlanmış 8-bit veriyi, çıkış portuna bağlar.
					sclk_o			<= sclk;  		-- Bunu ben tutarsızlık olabileceği için ekledim.
					
					-- Yukarıdaki if bloğunda slavden gelen 1 byte veriyi okuduk. Eğer 1 byte daha veri okuyacaksak burdaki if bloğuna girer
					if (mosi_en = '1') then				
						if (en_i = '1') then
							write_reg	<= 	mosi_data_i;
							-- Neden? CPHA=0 modu için kritik öneme sahiptir. İlk clock darbesinden önce verinin hatta yerleşmiş ve 
							-- kararlı olması gerekir (setup time). CPHA=1 için de bir sorun oluşturmaz.
							mosi_o		<= mosi_data_i(7);	
							sclk_o		<= sclk;	-- Neden? Transfer durmayacak, devam edecek. Clock sinyalinin kesintisiz üretilmesi gerekir.						
							cntr		<= 0;
						else
							state	<= S_IDLE;	-- Eğer kullanıcı veri transferini bitrimişse S_IDLE durumuna geçer ve bekler
							cs_o	<= '1';								
						end if;	
					end if;
				elsif (cntr = 9) then		-- (Temizlik ve Çıkış):
					sclk_o <= sclk;			--  Bunu ben tutarsızlık olabileceği için ekledim.
					if (miso_en = '1') then
						state	<= S_IDLE;
						cs_o	<= '1';
					end if;						
				
				else		-- 1 <= cntr <= 7 (Ara Bitlerin Transferi):
					sclk_o	<= sclk;
					if (miso_en = '1') then 	-- 1 - 7 bit arasını örneklemeye devam eder.
						read_reg(0)				<= miso_i;
						read_reg(7 downto 1) 	<= read_reg(6 downto 0);
						cntr					<= cntr + 1;
					end if;
					if (mosi_en = '1') then
						mosi_o	<= write_reg(7);
						write_reg(7 downto 1) 	<= write_reg(6 downto 0);
					end if;
				end if;
 
-- Farklı Gecikme Noktaları: CPHA=1, bitiş işlemi için cntr'ı 9'a çıkarıp ekstra bir miso_en bekler. CPHA=0 ise bitiş işlemini cntr=8 iken de yapmaya
-- çalışır, olmazsa o da cntr=9'a geçer.

			else	-- c_cpha = '0'
 
				if (cntr = 0) then
					sclk_o	<= sclk;					
					if (miso_en = '1') then
						read_reg(0)				<= miso_i;
						read_reg(7 downto 1) 	<= read_reg(6 downto 0);
						cntr					<= cntr + 1;
						once                    <= '1';
					end if;
					
				elsif (cntr = 8) then				
                    if (once = '1') then
                        data_ready_o    <= '1';
                        once            <= '0';                       
                    end if;
					miso_data_o		<= read_reg;
					sclk_o			<= sclk;
					if (mosi_en = '1') then
						if (en_i = '1') then
							write_reg	<= mosi_data_i;
							mosi_o		<= mosi_data_i(7);		
							cntr		<= 0;
						else
							cntr	<= cntr + 1;		-- Kullanıcı durmak istiyorsa, sayaç 9 yapılır. Bu bir sonraki aşamaya (temizlik için) geçmeye hazırlıktır.
						end if;
						
-- Bu CPHA=0 için kritik bir kontrol! Kullanıcı durmak istediğinde, durma işlemini (IDLE'a geçme ve CS'yi çekme) bir sonraki örnekleme anında 
--(miso_en='1', yani yükselen kenarda) yapar. Bu, protokolü temiz bir şekilde sonlandırmak içindir.			
			
						if (miso_en = '1') then
							state	<= S_IDLE;
							cs_o	<= '1';							
						end if;
					end if;	
					
				elsif (cntr = 9) then			-- Bu bir güvenlik önlemidir.
					sclk_o <= sclk;			-- Bunu ben tutarsızlık olabileceği için ekledim.
					if (miso_en = '1') then
						state	<= S_IDLE;
						cs_o	<= '1';
					end if;
					
				else
					sclk_o	<= sclk;
					if (miso_en = '1') then
						read_reg(0)				<= miso_i;
						read_reg(7 downto 1) 	<= read_reg(6 downto 0);
						cntr					<= cntr + 1;
					end if;
					if (mosi_en = '1') then
						mosi_o	<= write_reg(7); -- Bunu ben hata olabileceği için ekledim
						write_reg(7 downto 1) 	<= write_reg(6 downto 0);
					end if;
				end if;			
 
			end if;
 
	end case;
 
end if;
end process P_MAIN;
 
--------------------------------------------------------------------------------
--   SCLK_GEN işleminde, sclk_en sinyali ‘1’ ise dahili sclk sinyali üretilir.

P_SCLK_GEN : process (clk_i) begin
if (rising_edge(clk_i)) then
 
	if (sclk_en = '1') then
		if edgecntr = c_edgecntrlimdiv2-1 then
			sclk 		<= not sclk;
			edgecntr	<= 0;
		else
			edgecntr	<= edgecntr + 1;
		end if;	
	else
		edgecntr	<= 0;
		if (c_cpol = '0') then
			sclk	<= '0';
		else
			sclk	<= '1';
		end if;
	end if;
 
end if;
end process P_SCLK_GEN;
 
end Behavioral;