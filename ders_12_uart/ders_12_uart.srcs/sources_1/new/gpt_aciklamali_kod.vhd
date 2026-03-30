library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity gpt_aciklamali_kod is
    generic (
        c_clfreq      : integer := 100_000_000;    -- Sistem saat frekansı (örn. 100 MHz)
        c_bauderrate  : integer := 115_200;        -- UART baud rate (bit/s)
        c_stopbit     : integer := 2               -- 2 olduğunda: 1 bit start, 8 bit veri, 2 bit stop --> toplam 11 bit
                                             -- 2 stop bit, hata payını azaltmak için tercih edilir.
    );
    
    port (
        clk             : in std_logic;              -- Sistem clock sinyali
        din_i           : in std_logic_vector (7 downto 0);  -- Dışarıdan gelen 8-bit veri
        tx_start_i      : in std_logic;              -- Veri gönderme başlatma sinyali
        tx_done_tick_o  : out std_logic;             -- Gönderim tamamlandı sinyali (tick)
        tx_o            : out std_logic              -- UART çıkış sinyali (seri veri çıkışı)
    );
    
end gpt_aciklamali_kod;

architecture Behavioral of gpt_aciklamali_kod is
    
    -- Her bitin ne kadar süre boyunca gönderileceğini belirler:
    constant bittimer_lim : integer := c_clfreq / c_bauderrate;
    -- Stop bit süresi, 2 stop biti olduğundan, bittimer_lim'in 2 katıdır:
    constant stopbit_lim  : integer := (c_clfreq / c_bauderrate) * c_stopbit;
    
    -- FSM (finite state machine) durumları: 
    type states is (S_BOSTA, S_BASLA, S_VERI, S_DUR);
    
    -- FSM'in geçerli durumunu tutar. S_BOSTA: boşta (idle) durumu.
    signal state       : states := S_BOSTA;
    
    -- Bit gönderim süresini sayan sayaç. Stop bit süresi en uzun olduğundan aralık stopbit_lim'tir.
    signal bittimer    : integer range 0 to stopbit_lim;
    
    -- Shift register: din_i'den gelen veriyi kopyalar ve her bit gönderiminde kaydırma yapmamızı sağlar.
    -- Not: dış input (din_i) VHDL'de değiştirilemez. Bu yüzden kaydırma işlemi için shreg kullanılır.
    signal shreg       : std_logic_vector (7 downto 0) := (others => '0');
    
    -- Gönderilen bit sayısını tutan sayaç (8 bit veri olduğundan 0 ile 7 arasında).
    signal bitcounter  : integer range 0 to 7 := 0;

begin

    -- Ana süreç: Tüm işlem clock'un yükselen kenarında gerçekleşir.
    P_MAIN : process (clk) 
    begin
        if (rising_edge(clk)) then
        
            -- FSM: Durum kontrolü
            case state is
                
                -- -------------------------------------------------------------------
                -- S_BOSTA durumu: Idle (boşta) mod, TX hattı '1' seviyesinde bekler.
                when S_BOSTA =>
                    tx_o           <= '1';            -- TX çıkışı boşta '1' kalır.
                    tx_done_tick_o <= '0';            -- Gönderim tamamlanmadı.
                    bitcounter     <= 0;              -- Bit sayacını sıfırla. (Başlangıçta zaten 0 olsa da, güvenlik için resetlenir.)
                    
                    -- Eğer dışarıdan gönderim başlatma sinyali gelirse:
                    if (tx_start_i = '1') then
                        state   <= S_BASLA;        -- FSM, S_BASLA durumuna geçer.
                        tx_o    <= '0';            -- Start bit: TX çıkış '0' yapılır.
                        shreg   <= din_i;          -- Gelen veri, shreg'e kopyalanır.
                        -- Yorum: "tx_o'yu burada da '0' yapabiliriz ama start bitin hemen verilmesi için bu atama, bir sonraki clock'a kadar etkili olacaktır.
                        -- Böylece, gecikme yaşamadan start biti gönderilmiş olur."
                    end if;
                    
                -- -------------------------------------------------------------------
                -- S_BASLA durumu: Başlangıç (start) bitinin gönderildiği durum.
                when S_BASLA =>
                    -- Bit süresi bittiyse (bittimer bit süresi dolduysa)
                    if (bittimer = bittimer_lim - 1) then
                        state    <= S_VERI;       -- Sonraki duruma geç: Veri gönderimi başlasın.
                        tx_o     <= shreg(0);     -- İlk veri biti çıkışa atanır.
                        -- Aşağıdaki kod, veri kaydırma işlemini gerçekleştirir.
                        -- VHDL'de signal atamaları aynı clock döngüsünde paralel olarak değerlendirilir.
                        shreg(7 downto 1) <= shreg(6 downto 0);  -- shreg'in bitleri sağa kaydırılır.
                        shreg(0)          <= shreg(7);            -- Dairesel kaydırma: en sondaki bit (shreg(7)) en başa alınır.
                        bittimer          <= 0;                    -- Sayaç sıfırlanır.
                    else
                        bittimer <= bittimer + 1;    -- Bit süresi devam ediyorsa, sayaç artırılır.
                    end if;
                    
                -- -------------------------------------------------------------------
                -- S_VERI durumu: Veri bitlerinin gönderildiği durum.
                when S_VERI =>
                    tx_o <= shreg(0);  
                    -- Açıklama: FSM aktifken, çıkış sinyalini her clockta yeniden üretmek gerekir.
                    -- Bu atama, veri bitinin sabit kalmasını ve senkron şekilde gönderilmesini sağlar.
                    
                    if (bitcounter = 7) then         -- Eğer son (8. bit) gönderilecekse:
                        if (bittimer = bittimer_lim - 1) then    -- 1 bitlik süre tamamlandıysa:
                            state      <= S_DUR;   -- Stop bit aşamasına geç.
                            bitcounter <= 0;       -- Bit sayacını sıfırla.
                            tx_o       <= '1';     -- Stop biti: TX çıkışı '1' yapılır.
                            bittimer   <= 0;        -- Sayaç sıfırlansın.
                        else
                            bittimer   <= bittimer + 1;  -- Bit süresi devam ediyorsa, sayaç artır.
                        end if;
                    
                    else    -- Eğer henüz tüm veri bitleri gönderilmediyse:
                        if (bittimer = bittimer_lim - 1) then 
                            -- Burada FSM hâlâ S_VERI durumundadır. Ekstra bir durum ataması gerekmez.
                            -- Yapılan işlem: Her bitin süresi dolduğunda, shift register sağa kaydırılarak
                            -- sıradaki bitin çıkışa verilecek hale gelmesi sağlanır.
                            shreg(7 downto 1) <= shreg(6 downto 0);  -- Bitlerin sağa kaydırılması.
                            shreg(0)          <= shreg(7);            -- Dairesel kaydırma: Son bit en başa alınır.
                            bitcounter        <= bitcounter + 1;       -- Gönderilen bit sayısı artar.
                            bittimer          <= 0;                    -- Sayaç sıfırlanır.
                        else
                            bittimer <= bittimer + 1;   -- Bit süresi devam ediyorsa, sayaç artırılır.
                        end if;
                    end if;
                    
                -- -------------------------------------------------------------------
                -- S_DUR durumu: Stop bitlerinin gönderildiği durum.
                when S_DUR =>
                    if (bittimer = stopbit_lim - 1) then    -- Stop bit süresi dolduysa:
                        state          <= S_BOSTA;    -- FSM tekrar idle (boşta) durumuna geçsin.
                        tx_done_tick_o <= '1';         -- Gönderim tamamlandı sinyali üretilsin.
                    end if;
                    
            end case;
        end if;
    end process;
    
end Behavioral;
