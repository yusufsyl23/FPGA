library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
-- Bu paket bize STD_LOGIC ve STD_LOGIC_VECTOR tiplerini tanımlıyor.
-- Sadece bir bit ifade etmek istiyorsak std_logic birden fazla vektör ifade etmek istiyorsak STD_LOGIC_VECTOR kullanılır.

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity toplama_yontem_2 is
    Port ( s0_i : in STD_LOGIC_VECTOR(7 downto 0);  -- 8 bitlik giriş
           s1_i : in STD_LOGIC_VECTOR(7 downto 0);  -- 8 bitlik giriş
           s_o : out STD_LOGIC);
end toplama_yontem_2;

architecture Behavioral of toplama_yontem_2 is
	
	--s0, tek bitlik bir sinyal olacak şekilde tanımlandı
    signal s0 : Unsigned (7 downto 0) := x"00";   -- 8 bit

begin
	
	--s0_i ve s1_i'nin toplamını s0 sinyaline atıyoruz (bunun yerine AND işlemi yapılabilir)
	-- s0_i ve s1_iyi ikilik tabanda 8 bitlik işlem yapar. Overflow olursa taşma biti tutulmaz. 256+256 = 100000000 olur ama sonuç vektörü 8 bit olduğu için cevap 0000000 olur.
    s0 <= Unsigned(s0_i) + Unsigned(s1_i);

    --s0 değeri 1'den büyükse çıkışı 1 yapıyoruz, aksi takdirde 0
    process(s0) begin
        if (s0 > 20) then
           s_o <= '1';
        else
            s_o <= '0';
        end if;
    end process;

end Behavioral;