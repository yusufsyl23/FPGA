library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_sbram is
end tb_sbram;

architecture behavior of tb_sbram is

    -- RAM bileşenini testbench içinde çağırabilmek için component tanımlanmalı
    component sbram
        Port (
            clk    : in  std_logic;
            wea    : in  std_logic;
            addra  : in  std_logic_vector(3 downto 0);
            dina   : in  std_logic_vector(7 downto 0);
            douta  : out std_logic_vector(7 downto 0)
        );
    end component;

    -- Testbench sinyalleri (RAM'e bağlanacak sinyaller)
    signal clk    : std_logic := '0';
    signal wea    : std_logic := '0';
    signal addra  : std_logic_vector(3 downto 0) := (others => '0');
    signal dina   : std_logic_vector(7 downto 0) := (others => '0');
    signal douta  : std_logic_vector(7 downto 0);

begin

    -- RAM instance'ı
    uut: sbram
        port map (
            clk    => clk,
            wea    => wea,
            addra  => addra,
            dina   => dina,
            douta  => douta
        );

    -- Saat sinyali üretimi: 10 ns periyotlu clock (5ns yüksek, 5ns düşük)
    clk_process : process
    begin
        while true loop
            clk <= '0';
            wait for 5 ns;
            clk <= '1';
            wait for 5 ns;
        end loop;
    end process;

    -- Test senaryosu
    stim_proc : process
    begin
        -- Başlangıç: biraz bekleyelim
        wait for 20 ns;

        -- Adres 3'e 10101010 yazalım
        wea   <= '1';
        addra <= "0011"; -- adres 3
        dina  <= "10101010";
        wait for 10 ns;

        -- Yazma işlemini bitir
        wea <= '0';
        wait for 10 ns;

        -- Aynı adresten oku
        addra <= "0011";
        wait for 10 ns;

        -- Simülasyonu bitir
        wait;
		
    end process;

end behavior;
