----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2025 14:01:01
-- Design Name: 
-- Module Name: topla_yontem_3 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


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

entity topla_yontem_3 is
    Port ( s0_i : in STD_LOGIC_VECTOR(7 downto 0);  -- 8 bitlik giriş
           s1_i : in STD_LOGIC_VECTOR(7 downto 0);  -- 8 bitlik giriş
           s_o : out STD_LOGIC);
end topla_yontem_3;

architecture Behavioral of topla_yontem_3 is

-- s0, tek bitlik bir sinyal olacak şekilde tanımlandı
    signal s0 : integer range 0 to 255 := 0;

begin
	
	-- s0_i ve s1_i'nin toplamını s0 sinyaline atıyoruz (bunun yerine AND işlemi yapılabilir)
	-- s0_i ve s1_i yi 8 bitlik işaretsiz sayı olarak (0,256) toplar(0,256) ve sonucu integer sayıya dönüştürür.
	-- Burda overflow olmaz çünkü sonuç 256 olsa bile bu değeri integer olarak kaydeder.
    s0 <= TO_INTEGER(Unsigned(s0_i) + Unsigned(s1_i));

    -- s0 değeri 1'den büyükse çıkışı 1 yapıyoruz, aksi takdirde 0
    process(s0) begin
        if (s0 > 20) then
            s_o <= '1';
        else
            s_o <= '0';
        end if;
    end process;

end Behavioral;
