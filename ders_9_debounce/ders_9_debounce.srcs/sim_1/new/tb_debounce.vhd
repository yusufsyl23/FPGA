library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity tb_debounce is
end tb_debounce;

architecture Behavioral of tb_debounce is

    -- Sabitler
    constant c_clkfreq       : integer := 100_000_000;
    constant c_debounce_time : integer := 1000;
    constant ilk_deger       : std_logic := '0';
    constant c_clkperiod     : time := 10 ns;

    -- DUT için component tanımlama
    component debounce is
        generic (
            c_clkfreq       : integer := 100_000_000;
            c_debounce_time : integer := 1000;
            ilk_deger       : std_logic := '0'
        );
        port (
            clk         : in std_logic;
            signal_i    : in std_logic;
            signal_o    : out std_logic
        );
    end component;

    -- Sinyaller
    signal clk       : std_logic := '0';
    signal signal_i  : std_logic := '0';
    signal signal_o  : std_logic;

begin

    -- DUT bağlama
    DUT : debounce
    generic map(
        c_clkfreq       => c_clkfreq,
        c_debounce_time => c_debounce_time,
        ilk_deger       => ilk_deger
    )
    port map(
        clk        => clk,
        signal_i   => signal_i,
        signal_o   => signal_o
    );

    -- Clock üretici process
    P_CLKGEN : process
    begin
        clk <= '0';
        wait for c_clkperiod/2;
        clk <= '1';
        wait for c_clkperiod/2;
    end process;

    -- Test senaryosu
    P_STIMULI : process
    begin
        -- Başlangıç LOW
        signal_i <= '0';
        wait for 2 ms;
        
        -- Birkaç gürültülü geçiş
        signal_i <= '1';
        wait for 100 us;
        signal_i <= '0';
        wait for 200 us;
        signal_i <= '1';
        wait for 100 us;
        signal_i <= '0';
        wait for 100 us;
        signal_i <= '1';
        wait for 800 us;
        signal_i <= '0';
        wait for 50 us;
        signal_i <= '1';

        wait for 3 ms;

        -- Daha fazla gürültü
        signal_i <= '0';
        wait for 100 us;
        signal_i <= '1';
        wait for 200 us;
        signal_i <= '0';
        wait for 950 us;
        signal_i <= '1';
        wait for 150 us;
        signal_i <= '0';

        wait for 2 ms;

        assert false report "SIM DONE" severity failure;
    end process;

end Behavioral;