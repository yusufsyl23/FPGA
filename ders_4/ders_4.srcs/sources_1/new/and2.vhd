----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2025 12:06:48
-- Design Name: 
-- Module Name: and2 - Behavioral
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
-- Bu paket bize STD_LOGIC ve STD_LOGIC_VECTOR tiplerini tanımlıyor. STD_LOGIC_1164 matematiksel ve mantıksal operatörler yok.
-- Sadece bir bit ifade etmek istiyorsak std_logic birden fazla vektör ifade etmek istiyorsak STD_LOGIC_VECTOR kullanılır.

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity and2 is
    Port ( s0_i : in STD_LOGIC_VECTOR(7 downto 0);  -- 8 bitlik giriş
           s1_i : in STD_LOGIC_VECTOR(7 downto 0);  -- 8 bitlik giriş
           s_o : out STD_LOGIC);
end and2;

architecture Behavioral of and2 is
    -- s0, tek bitlik bir sinyal olacak şekilde tanımlandı
    signal s0 : STD_LOGIC_VECTOR(7 downto 0) := x"00";

begin

    -- s0_i ve s1_i'nin toplamını s0 sinyaline atıyoruz (bunun yerine AND işlemi yapılabilir)
	-- s0_i ve s1_i önce 0-255 arasında bir değere dönüştürülüyor ve işlem yapılıyor daha sonra bu değer 8 bitlik değere dönüştürülüyor.  
    s0 <= STD_LOGIC_VECTOR(Unsigned(s0_i) + Unsigned(s1_i));

    -- s0 değeri 1'den büyükse çıkışı 1 yapıyoruz, aksi takdirde 0
    process(s0) begin
        if (Unsigned(s0) > 20) then
           s_o <= '1';
       else
            s_o <= '0';
        end if;
    end process;

end Behavioral;

