----------------------------------------------------------------------
-- LIBRARY and PACKAGE DECLARATIONS
----------------------------------------------------------------------

-- standard packages
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- user defined packages (kullanıcı tarafından tanımlanan paketler)
-- Bu paketler nerdeyse her kodda kullnılır
use PCK MYPACKAGE.ALL;

---------------------------------------------------------------------------------------------------------------------------
-- ENTITY : Bir VHDL dosyasının yani modülümüzün dış dünya ile olan arayüzlerinin tanımlandığı isim. Buna bir isim verilir.
---------------------------------------------------------------------------------------------------------------------------

entity my_entity_name is
    generic (
        c_clkfreq   : integer                            := 100_000_000;
        c_sclkfreq  : integer                            := 1_000_000;
        c_i2cfreq   : integer                            := 400_000;
        c_bitnum    : integer                            := 8;
        c_is_sim    : boolean                            := false;
        c_cfgr_reg  : std_logic_vector(7 downto 0)       := x"A3"
    );

    ---------------------------------------------------------------------------------------------------------------------------
    -- Portlarda arayüz sinyalleri generic kısmında ise bazı sabit değerler bulunur.
    -- Generic kısım parametrik tasarım için gereklidir. Bu şekilde kodun alt kısmı değişse bile sadece burdaki değer değişir.
    -- İnout hem giriş hem çıkış olabilir
    -- std_logic = 1 bit 
    -- std_logic_vector = çok bit
    ---------------------------------------------------------------------------------------------------------------------------

    port (
        input1_i    : in    std_logic_vector(c_bitnum-1 downto 0);
        input2_i    : in    std_logic;
        output1_o   : out   std_logic;
        output2_o   : out   std_logic_vector(1 downto 0);
        inout1_io   : inout std_logic_vector(15 downto 0);
        inout2_io   : inout std_logic
    );
end my_entity_name;

---------------------------------------------------------------------------------------------------------------------------
-- ARCHITECTURE
-- Modülün iç işleyişini tanımlar.
-- Normalde architecture Behavioral böyle yazar ama Behavioral buraya istediğimiz şeyi yazabiliriz
-- Architecture kısmı ikiye ayrılır: Bildirim bölümü (is ile begin arası) ve İşlevsel bölüm (begin sonrası)
-- architecture ın begin e kadar olan kısmı bildiri kısmıdır. Yani ben bu tasarımda neler kullnacağım
-- Bu kısımda sabitler belirlenebilir
---------------------------------------------------------------------------------------------------------------------------

architecture burak of my_entity_name is

    -- CONSTANTS (Sabitler)
    constant c_constant1    : integer := 30;
    constant c_timer1mslim  : integer := c_clkfreq / 1000;
    constant c_constant2    : std_logic_vector(c_bitnum-1 downto 0) := (others => '0'); -- genişliği yukarıdan geliyor

---------------------------------------------------------------------------------------------------------------------------
-- COMPONENT DECLARATIONS
-- Başka bir VHDL dosyasındaki entity'yi burada kullanmak için bu şekilde tanıtılır.
-- Bu modülümün içinde başka modüller kullanabilirim. Yani hiyerarşik bir model olabilir.
-- my_component de aslında my_component.vhd adında başka bir entity. Bununda başka bir yerde kendi entityi var 
-- Bunu bu şekilde deklare etmiş oluyoruz
---------------------------------------------------------------------------------------------------------------------------

    component my_component is
        generic (
            gen1 : integer     := 10;
            gen2 : std_logic   := '0'
        );
        port (
            in1  : std_logic_vector(c_bitnum-1 downto 0);
            out1 : std_logic
        );
    end component my_component;

---------------------------------------------------------------------------------------------------------------------------
-- TYPES
---------------------------------------------------------------------------------------------------------------------------
	
	--alt tür, kısıtlaması olan bir türdür
    type t_state is (S_START, S_OPE RATION, S_TERMINATE, S_IDLE);  -- Burda 4 şekil state alabiliyor. enumerate gibi.
    -- subtype Var olan bir türü sınırlandırmak için kullanılır.
	subtype t_decimal_digit is integer range 0 to 9;			-- 0 dan 9 a kadar bir integer
    subtype t_byte is bit_vector(7 downto 0);					-- 8 bit 
	
	-- record
	-- c deki struct yapısı gibi altında iki farklı sinyal var
	-- Python’daki bir class ya da dict gibi düşünebilirsin. Birden fazla alan içerir.
	
    type my_record_type is record
        param1 : std_logic;
        param2 : std_logic_vector(3 downto 0);
    end record;

---------------------------------------------------------------------------------------------------------------------------
-- SIGNALS
---------------------------------------------------------------------------------------------------------------------------
	
	-- Bunlar iç sinyaller dış dünya ile ilişkileri yok
	-- İç sinyallerdir, modül içindeki tel bağlantılarını temsil eder.
	-- signal = donanımda bir tel veya flip-flop olabilir.
	-- Başlangıç değeri verilirse FPGA programlanırken o değerle başlar.
	-- Aralık verilirse daha az yer kaplar (örneğin 8-bit yerine 32-bit yer kaplamaz).
	
    signal s0         : std_logic_vector(7 downto 0);				-- signal without initialization (başlatma olmadan sinyal)
    signal s1         : std_logic_vector(7 downto 0) := x"00";		-- signal with initialization	(başlatma ile sinyal)
    signal s2         : integer range 0 to 255       := 0;			-- integer signal with range limit, 8-bit HW (aralık limitli tamsayı sinyali, 8 bit HW)
    signal s3         : integer                      := 0;			-- integer signal without range limit, 32-bit HW (aralık sınırı olmayan tamsayı sinyali, 32 bit HW)
    signal s4         : std_logic                    := '0';
	
	-- Bunlar kendi belirlediğimiz tipler
    signal state      : t_state                      := S_START;
    signal bcd        : t_decimal_digit              := 0;
    signal opcode     : t_byte                       := x"BA";
    signal s_record   : my_record_type;

begin

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- COMPONENT INSTANTIATIONS (BİLEŞEN ÖRNEKLERİ)
-- Burda instantiate (örneklendirme) ettik. Yani generic ve portlarına sinyal bağladık
-- Tanımladığın component'i gerçek modül olarak instantiate ettik.
-- Donanımda gerçekten başka bir modülün yerleştirilmesidir.
---------------------------------------------------------------------------------------------------------------------------

    mycomp1 : my_component
        generic map (
            gen1 => c_12cfreq,
            gen2 => '0'
        )
        port map (
            in1  => input1_i,
            out1 => output1_o
        );

---------------------------------------------------------------------------------------------------------------------------
-- CONCURRENT ASSIGNMENTS (EŞ ZAMANLI GÖREVLER)
-- Anda çalışan devre elemanlarını tanımlar. Tıpkı paralel çalışan lojik kapılar gibi.
-- with-select, when-else, if-then hepsi farklı biçimlerde seçim mantığı (MUX) oluşturur.
-- Donanımda bu satırlar genelde mux, kapı devreleri oluşturur.
---------------------------------------------------------------------------------------------------------------------------
	
	--  when else yapısı if else e benzer. s0 < 30 => s0 = 00 , s0 < 400 => s0 = 01 değilse s0 = 02
    s1 <= x"00" when s0 < 30 else
          x"01" when s0 < 40 else
          x"02";
	
	-- c de swich case gibi düşünülebilir. Pythonda ise if-elif-else. 
    with state select
        x"01" when OPERATION,
        x"02" when TERMINATED,
        x"03" when others;

	-- Burda sinyal ataması yaptık. Eş zamanlı görevlerde bir sinyale iki değer bağlamak istersek hata verir
    s3 <= 5 + 2;
    s3 <= input1_i(3) and input1_i(2) xor input2_i;
	
	-- Bu şekilde s_record sinyalinin veri türlerine bu şelilde atama yapabiliriz
    s_record.param1 <= '0';
    s_record.param2 <= "0000";
	
	-- inout daha çok ram yapılarında data hem input hem output olarak kullanılabşliyor
	-- Eğer sda_ena_n aktif (0) ise veri hattına 0 yaz, değilse hattı serbest bırak (yüksek empedans yap).
	-- "Z" sanki bu sinyal fiziksel olarak bağlantıdan ayrılmış (sürücüsüz) gibi davranır.
    inout2_io <= '0' when sda_ena_n = '0' else 'Z';
	
---------------------------------------------------------------------------------------------------------------------------
-- COMBINATIONAL PROCESS
-- Saat (clk) içermediği için combinational (kombinasyonel) devredir.
-- Lookup table'larla ifade edilir.
-- Her sinyal değişiminde tekrar hesaplanır.
-- Donanımda mantık kapıları ağı olarak sentezlenir.
-- clk yoksa lokup tablelarla ve birbirlerine bağlantılar ile bir devre oluşturuyoruz.
---------------------------------------------------------------------------------------------------------------------------

    P_COMBINATIONAL : process (s0, state, input1_i, input2_i)
    begin
		-- Burda bir meory oluşturmuyor. Yani flip flop kullanılmıyor 
        s4 <= '0';
	
		-- if / elsif / else block
		-- if yapısı processin içinde kullanılabilir
		-- Bu ifade yukarıdaki when else yapısı ile aynı
        if (s0 < 30) then
            s1 <= x"01";
        elsif (s0 < 40) then
            s1 <= x"02";
        else
            s1 <= x"03";
        end if;

		-- case block
		-- Bu da yine yukarıdaki with select ile aynı devreyi oluşturuyor
        case state is
            when S_START     => s0 <= x"01";
            when S_OPERATION => s0 <= x"02";
            when S_TERMINATE => s0 <= x"03";
            when others      => s0 <= x"04";
        end case;
		
		-- Burda hata vermez s4 en son ne ise o değerde kalır
        s4 <= input1_i(3) and input1_i(2) xor input2_i;
        s4 <= input1_i(3) or input1_i(2) xnor input2_i; -- NOT multiple driven net error
    end process P_COMBINATIONAL;

---------------------------------------------------------------------------------------------------------------------------
-- SEQUENTIAL ASSIGNMENTS - PROCESS BLOCK (SIRALI ATAMALAR - IŞLEM BLOĞU)
-- NOT: İşlem blokları birbirleriyle eşzamanlı olarak çalışır
-- Araç, bir sinyal birden fazla işlem bloğuna atanmışsa çoklu sürülen ağ hatası verir. Multiple driven net eror
---------------------------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------------------------
-- COMBINATIONAL PROCESS
-- Saat (clk) içermediği için combinational (kombinasyonel) devredir.
-- Lookup table'larla ifade edilir.
-- Her sinyal değişiminde tekrar hesaplanır.
-- Donanımda mantık kapıları ağı olarak sentezlenir.
-- clk yoksa lokup tablelarla ve birbirlerine bağlantılar ile bir devre oluşturuyoruz.
---------------------------------------------------------------------------------------------------------------------------

P_COMBINATIONAL : process (s0, state, input1_i, input2_i) begin

	  -- if / elsif / else block
	  -- if yapısı processin içinde kullanılabilir
	  -- Bu ifade yukarıdaki when else yapısı ile aynı
	  
	  -- Burda bir meory oluşturmuyor. Yani flip flop kullanılmıyor 
	  s4 <= "0";
	  
	  if (s0 < 30) then
		s1 <= x"01";
	  elsif (s0 < 40) then
		s1 <= x"02";
	  else
		s1 <= x"03";
	  end if;

	  -- case block
	  -- Bu da yine yukarıdaki with select ile aynı devreyi oluşturuyor
	  case state is
		when S_START =>
		  s0 <= x"01";
		when S_OPERATION =>
		  s0 <= x"02";
		when S_TERMINATE =>
		  s0 <= x"03";
		when others =>
		  s0 <= x"04";
	  end case;
	
	  -- Burda hata vermez s4 en son ne ise o değerde kalır çünkü burda işlemer paralel değil sıralıdır.
	  s4 <= input1_i(3) and input1_i(2) xor input2_i;
	  s4 <= input1_i(3) or input1_i(2) xnor input2_i;  -- NOT multiple driven net error

end process P_COMBINATIONAL;

---------------------------------------------------------------------------------------------------------------------------
-- SEQUENTİAL PROCESS
-- İçerisinde clock (clk) bulunan devrelerde (bir process bir devre oluşturuyor) clk ile drive ediliyorsa o zaman sequantial bir devre oluşmuş oluyor.
-- Yani içerde flip-floplar oluşturup onlar üzerinden bir devre oluşturuyoruz
---------------------------------------------------------------------------------------------------------------------------

    P_SEQUENTIAL : process(clk)
    begin
        if rising_edge(clk) then
            -- Buraya COMBINATIONAL PROCESS de yazılan şeyler gelir
            -- Burda s4 <= '0'; dediğimizde flip floplar ile memory oluşturulur
        end if;
    end process P_SEQUENTIAL;

end burak;
	

	


