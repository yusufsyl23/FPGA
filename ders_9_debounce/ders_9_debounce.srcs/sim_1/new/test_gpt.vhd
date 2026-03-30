library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity test_gpt is
end test_gpt;

architecture Behavioral of test_gpt is

    -- Clock parametreleri
    constant c_clk_period : time := 10 ns;   -- 100 MHz clock

    -- Sinyaller
    signal clk       : std_logic := '0';
    signal signal_i  : std_logic := '0';
    signal signal_o  : std_logic;

    -- Debounce bileşeni
    component debounce
        generic (
            c_clkfreq       : integer := 100_000_000;
            c_debounce_time : integer := 1000;
            ilk_deger       : std_logic := '0'
        );
        port (
            clk       : in  std_logic;
            signal_i  : in  std_logic;
            signal_o  : out std_logic
        );
    end component;

begin

    -- Clock üretimi
    clk_process : process
    begin
        clk <= '0';
        wait for c_clk_period/2;
        clk <= '1';
        wait for c_clk_period/2;
    end process;


    -- DUT: debounce instance
    uut: debounce
        generic map (
            c_clkfreq       => 100_000_000,
            c_debounce_time => 1000, -- 1ms debounce
            ilk_deger       => '0'
        )
        port map (
            clk      => clk,
            signal_i => signal_i,
            signal_o => signal_o
        );

    -- Test süreci
    stim_proc: process
    begin

        -- Başlangıç LOW
        signal_i <= '0';
        wait for 5 ms;

        -- Gürültü: 1-0-1-0 hızlı değişimler (debounce yakalamaz)
        signal_i <= '1';
        wait for 200 us;
        signal_i <= '0';
        wait for 200 us;
        signal_i <= '1';
        wait for 200 us;
        signal_i <= '0';
        wait for 200 us;

        -- Gerçek HIGH geçişi (1ms sabit)
        signal_i <= '1';
        wait for 2 ms;

        -- Tekrar gürültü
        signal_i <= '0';
        wait for 300 us;
        signal_i <= '1';
        wait for 300 us;
        signal_i <= '0';
        wait for 300 us;

        -- Gerçek LOW geçişi (1ms sabit)
        signal_i <= '0';
        wait for 2 ms;

        -- Test sonu
        wait;
    end process;

end Behavioral;