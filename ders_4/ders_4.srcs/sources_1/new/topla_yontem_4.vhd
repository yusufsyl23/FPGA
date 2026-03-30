----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2025 13:20:37
-- Design Name: 
-- Module Name: topla_yontem_4 - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
-- Bu paket std logic vektörler üzerinden matematiksel işlemler yapmayı sağlıyor
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Bu paket std_logic vektör tipleri unsigned mı yoksa signed mı olarak işlem görecek onu belirtir.
-- Bu iki kütüphaneyi birlikte kullanmazsak hata verebilir.


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity topla_yontem_4 is
    Port ( s0_i : in STD_LOGIC_VECTOR (7 downto 0);
           s1_i : in STD_LOGIC_VECTOR (7 downto 0);
           s_o : out STD_LOGIC);
end topla_yontem_4;

architecture Behavioral of topla_yontem_4 is

	signal s0 : integer range 0 to 255 := 0;

begin
	
	-- Bu yöntem, ikilik tabanda yapılan bir işlemi (bit seviyesinde) alır, sonra sayıya dönüştürür. Taçma olmaz
	s0 <= CONV_INTEGER(s0_i + s1_i);
	
	process(s0) begin
        if (s0 > 20) then
            s_o <= '1';
        else
            s_o <= '0';
        end if;
    end process;
	

end Behavioral;
