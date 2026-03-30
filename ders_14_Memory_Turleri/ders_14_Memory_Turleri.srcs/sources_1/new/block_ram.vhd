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


-- Asıl RAM entity ve mimari tanımı
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.ram_pkg.all;
use STD.textio.all;

entity block_ram is
    generic (
        RAM_WIDTH       : integer := 16;                 -- RAM veri genişliği (bit cinsinden). Her hücrede 16 bitlik veri var. Her veri 16 bit
        RAM_DEPTH       : integer := 128;                -- RAM derinliği (adreslenebilir giriş sayısı). Yukarıdan aşşağıya 128 tane hücre var.
        RAM_PERFORMANCE : string  := "LOW_LATENCY";       -- RAM performans modu: "HIGH_PERFORMANCE" veya "LOW_LATENCY"
        --RAM_PERFORMANCE2: string  := "HIGH_PERFORMANCE"   -- Alternatif performans modu: "HIGH_PERFORMANCE" veya "LOW_LATENCY"
		C_RAM_TYPE		: string  := "block"
		--C_RAM_TYPE		: string  := "distributed"
    );
    port (
        addra : in  std_logic_vector((clogb2(RAM_DEPTH)-1) downto 0);  -- Adres hattı (RAM_DEPTH'e göre genişlik)
        dina  : in  std_logic_vector(RAM_WIDTH-1 downto 0);            -- RAM giriş verisi
        clka  : in  std_logic;                                         -- Saat (clock)
        wea   : in  std_logic;                                         -- Yazma etkinleştirme (write enable)
        douta : out std_logic_vector(RAM_WIDTH-1 downto 0)             -- RAM çıkış verisi
    );
end block_ram;

architecture Behavioral of block_ram is
    -- Okunabilirliği arttırmak için generic parametreleri constant olarak tanımladık
    constant C_RAM_WIDTH       : integer := RAM_WIDTH;          -- RAM veri genişliği
    constant C_RAM_DEPTH       : integer := RAM_DEPTH;          -- RAM derinliği
    constant C_RAM_PERFORMANCE : string  := RAM_PERFORMANCE;    -- Performans modu

    -- Çıkış registeri (isteğe bağlı)
    signal douta_reg : std_logic_vector(C_RAM_WIDTH-1 downto 0) := (others => '0');

    -- N-1 downto 0 şeklinde azalan da olabilir ama array tipi tanımlarken genellikle to kullanılır çünkü bu daha doğal bir artan yapıdır.
	-- Neden downto? VHDL’de bit dizileri için en yaygın ve standart gösterimdir. downto: Yüksek bitten düşük bite
	-- signal ram : array(0 to 127) of std_logic_vector(15 downto 0); -- Hatalı! Bu direkt sinyal tanımı değil
	-- VHDL buna izin vermez. Çünkü bu dizi yapısını tip olarak tanımlamak gerekir. ram_name: RAM’i temsil eden sinyal
    type ram_type is array (0 to C_RAM_DEPTH-1) of std_logic_vector(C_RAM_WIDTH-1 downto 0);

    -- RAM'den okunan veriyi geçici olarak tutmak için kullanılan sinyaldir.
	-- Özellikle senkron RAM'de, veri bir clock sonra dışa verileceği için ara buffer görevi görür.
	-- Doğrudan DOUTA'ya veri atamak yerine ram_data ile veri güvenli şekilde yönlendirilir.
	-- Kullanılmasa da çalışabilir, ancak sentez uyumluluğu ve tasarım netliği açısından önerilir.
	-- Sen yazma ve okuma işlemini aynı clock’ta aynı adrese yapıyorsan,doğrudan DOUTA’ya RAM’in içinden veri vermek bazı FPGA’larda yazılacak veri mi 
	--okunacak veri mi çıksın? karışıklığına yol açar.
	-- Eğer ram_data gibi bir geçici register olmasa, dout, 2. saat palsinde yazılmak üzere gelen yeni veriyle (0101_0101) hemen değişir. 
	--Bu da 1. saat palsinde yazdığın 1010_1010 verisini artık okuyamayacağın anlamına gelir.
	-- HIGH_PERFORMANCE seçtiğimiz için ram_data kullandık.
    signal ram_data : std_logic_vector(C_RAM_WIDTH-1 downto 0);

    -- Asıl RAM’i temsil eden sinyal. RAM içerikleri burada saklanıyor. Yapılmasa: Veri nerede saklanacak? RAM olmazdı.
    signal ram_name : ram_type := (others => (others => '0'));

    -- Buradan sonra ram_style attribute ve RAM'in davranışsal tanımı yapılacak
	attribute ram_style : string;
	
	-- Bu satır, ram_name adlı sinyale bir öznitelik ataması yapar.
	-- ram_name sinyalinin ram_style özelliği "block" olarak belirlenmiştir.
	attribute ram_style of ram_name : signal is C_RAM_TYPE;
	--attribute ram_style of ram_name : signal is "distributed";
	
begin
    -- İlerleyen aşamada RAM yazma/okuma işlemleri burada tanımlanacak
	    -- Yazma ve okuma işlemi (write process)
    process(clka)
    begin
        if (rising_edge(clka)) then
            -- Yazma etkinleştirme (write enable) aktifse veri yazılır
            if (wea = '1') then
				-- to_integer(unsigned(addra)) → Adres değerini tamsayıya çeviriyor (array index olarak kullanılabilsin diye).
                ram_name(to_integer(unsigned(addra))) <= dina;
            end if;
            -- Adrese göre RAM'den okunan veri ram_data'ya atanır
            ram_data <= ram_name(to_integer(unsigned(addra)));
        end if;
    end process;


    -- LOW_LATENCY modu (çıkış register kullanılmaz)
    -- Bu modda okuma gecikmesi 1 clock cycle'dır ancak clock-to-out süresi daha uzundur
    no_output_register : if C_RAM_PERFORMANCE = "LOW_LATENCY" generate
        douta <= ram_data;
    end generate;


    -- HIGH_PERFORMANCE modu (çıkış register kullanılır)
    -- Bu modda okuma gecikmesi 2 clock cycle'dır fakat clock-to-out süresi daha iyidir
    output_register : if C_RAM_PERFORMANCE = "HIGH_PERFORMANCE" generate
        process(clka)
        begin
            if (rising_edge(clka)) then
                douta_reg <= ram_data;
            end if;
        end process;

        -- Çıkış registerinden dışa aktarım
        douta <= douta_reg;
    end generate;

end Behavioral;

-- https://chatgpt.com/share/6891f2a0-7084-8002-be43-5b1760cbc07e
-- https://chatgpt.com/share/6891f2cd-efc8-8002-b305-669bee0b2e56