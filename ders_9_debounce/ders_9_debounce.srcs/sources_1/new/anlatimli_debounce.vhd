library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity debounce is
    generic (
        c_clkfreq       : integer := 100_000_000;     -- Saat frekansı (Hz), örneğin 100 MHz
        c_debounce_time : integer := 1000;            -- Debounce süresi (1ms), clock frekansı / debounce_time = sayacın limit değeri
        ilk_deger       : std_logic := '0'               -- Başlangıç değeri, çıkış ilk güç verildiğinde hangi durumda başlasın
    );
    
    port ( 
        clk         : in std_logic;                    -- Saat sinyali (clock)
        signal_i    : in std_logic;                    -- Giriş sinyali (örneğin buton)
        signal_o    : out std_logic                    -- Debounce edilmiş çıkış sinyali
    );
    
end debounce;

architecture Behavioral of debounce is

    -- Sayaç limitini hesaplama (örnek: 100MHz / 1000 = 100.000 sayım = 1ms)
    constant c_timerlim : integer := c_clkfreq / c_debounce_time;

    -- Sayaç sinyali: Bu sayaç, debounce süresince clock sayar
    signal timer       : integer range 0 to c_timerlim := 0;
    
    -- Sayaç etkinleştirme sinyali: Timer'ın çalışıp çalışmayacağını belirler
    signal timer_en    : std_logic := '0';
    
    -- Sayaç tamamlandığında 1 clock süresince '1' olan sinyal
    signal timer_tick  : std_logic := '0';

    -- FSM durumları (state machine) - sinyalin hangi aşamada olduğunu belirtir
    type t_state is (S_INITIAL, S_ZERO, S_ZEROTOONE, S_ONE, S_ONETOZERO);
    
    -- State sinyali, başlangıçta S_INITIAL durumunda
    signal state : t_state := S_INITIAL;

begin

    -------------------------------------------------------------------------
    -- MAIN FSM PROCESS (Saat yükselen kenarında çalışır)
    -- Bu işlem, giriş sinyalinin durumuna göre çıkışı ve timer kontrolünü yapar.
    -------------------------------------------------------------------------
    process (clk) begin
        if (rising_edge(clk)) then

            case state is
            
                ----------------------------------------------------------------------------------
                -- S_INITIAL: Başlangıç durumu, çıkış ilk değere göre ayarlanır.
                -- Amaç: Devre ilk açıldığında çıkışın mantıklı ve kararlı başlamasını sağlamak.
                ----------------------------------------------------------------------------------
                when S_INITIAL =>
                    if (ilk_deger = '0') then
                        state <= S_ZERO;      -- Başlangıç LOW ise S_ZERO durumuna geç
                    else
                        state <= S_ONE;       -- Başlangıç HIGH ise S_ONE durumuna geç
                    end if;
                
                -------------------------------------------------------------------------
                -- S_ZERO: Çıkış LOW durumunda, giriş HIGH olursa geçiş doğrulaması başlar
                -- signal_o '0' olarak atanır.
                -------------------------------------------------------------------------
                when S_ZERO =>     
                    signal_o <= '0';       -- Çıkış hala 0, sinyal LOW durumunda
                    
                    if (signal_i = '1') then
                        state <= S_ZEROTOONE;   -- Giriş 0'dan 1'e geçti, doğrulama için geçiş durumu
                    end if;
                
                -------------------------------------------------------------------------
                -- S_ZEROTOONE: 0'dan 1'e geçişin doğrulanması için bekleme süreci
                -- timer_en '1' yapılır, timer çalışır
                -- Eğer sinyal 1ms boyunca 1 kalırsa çıkış 1 olur.
                -- Eğer sinyal tekrar 0 olursa gürültü olduğu varsayılır ve S_ZERO'ya döner
                -------------------------------------------------------------------------
                when S_ZEROTOONE =>
                    signal_o <= '0';           -- Geçiş doğrulanana kadar çıkış eski değerde kalır (0)
                    timer_en <= '1';           -- Timer'ı başlat, debounce zamanını say
                    
                    if (timer_tick = '1') then  -- Timer tamamlandıysa, sinyal kararlı HIGH
                        state <= S_ONE;          -- Çıkış HIGH durumuna geç
                        timer_en <= '0';        -- Timer'ı durdur
                    end if;
                    
                    if (signal_i = '0') then    -- Sinyal tekrar LOW oldu, geçiş başarısız (gürültü)
                        state <= S_ZERO;         -- Eski duruma dön
                        timer_en <= '0';        -- Timer'ı durdur ve sıfırla
                    end if;
                
                -------------------------------------------------------------------------
                -- S_ONE: Çıkış HIGH durumunda, giriş LOW olursa geçiş doğrulaması başlar
                -- signal_o '1' olarak atanır.
                -------------------------------------------------------------------------
                when S_ONE =>
                    signal_o <= '1';           -- Çıkış HIGH, sinyal HIGH durumunda
                    
                    if (signal_i = '0') then
                        state <= S_ONETOZERO;   -- Giriş HIGH'dan LOW'a geçti, doğrulama için geçiş durumu
                    end if;
                
                -------------------------------------------------------------------------
                -- S_ONETOZERO: 1'den 0'a geçişin doğrulanması için bekleme süreci
                -- timer_en '1' yapılır, timer çalışır
                -- Eğer sinyal 1ms boyunca 0 kalırsa çıkış 0 olur.
                -- Eğer sinyal tekrar 1 olursa gürültü olduğu varsayılır ve S_ONE'a döner
                -------------------------------------------------------------------------
                when S_ONETOZERO =>
                    signal_o <= '1';           -- Geçiş doğrulanana kadar çıkış eski değerde kalır (1)
                    timer_en <= '1';           -- Timer'ı başlat, debounce zamanını say
                    
                    if (timer_tick = '1') then  -- Timer tamamlandıysa, sinyal kararlı LOW
                        state <= S_ZERO;         -- Çıkış LOW durumuna geç
                        timer_en <= '0';        -- Timer'ı durdur
                    end if;
                    
                    if (signal_i = '1') then    -- Sinyal tekrar HIGH oldu, geçiş başarısız (gürültü)
                        state <= S_ONE;          -- Eski duruma dön
                        timer_en <= '0';        -- Timer'ı durdur ve sıfırla
                    end if;
            
            end case;
        end if;
    end process;
    
    -------------------------------------------------------------------------
    -- TIMER PROCESS (Sayaç işlemi)
    -- timer_en = '1' olunca timer artar ve c_timerlim değerine ulaştığında
    -- timer_tick = '1' olur. Bu debounce süresinin dolduğunu belirtir.
    -- timer_en = '0' olunca sayaç sıfırlanır.
    -------------------------------------------------------------------------
    P_TIMER : process(clk) begin
        if (rising_edge(clk)) then
            if (timer_en = '1') then
                if (timer = c_timerlim-1) then
                    timer_tick  <= '1';    -- Debounce zamanı doldu, geçiş gerçek
                    timer       <= 0;      -- Sayaç sıfırla
                    
                else
                    timer_tick  <= '0';    -- Zaman dolmadı, sayaç artır
                    timer       <= timer + 1;
                    
                end if;
                
            else -- timer_en '0' ise timer durur ve sıfırlanır
                timer       <= 0;
                timer_tick  <= '0';
            end if;
        end if;
    end process;

end Behavioral;

-- https://chatgpt.com/share/685bc282-87cc-8002-9be2-2cfaf69b7553