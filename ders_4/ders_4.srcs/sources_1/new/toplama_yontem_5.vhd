----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2025 13:33:14
-- Design Name: 
-- Module Name: topla_yontem_5 - Behavioral
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity topla_yontem_5 is
    Port ( s0_i : in STD_LOGIC_VECTOR (7 downto 0);
           s1_i : in STD_LOGIC_VECTOR (7 downto 0);
           s_o : out STD_LOGIC);
end topla_yontem_5;

architecture Behavioral of topla_yontem_5 is

signal s0 : STD_LOGIC_VECTOR (7 downto 0) := x"00";

begin
	
	-- Toplama ve karşılaştırma işlemleri tamamen ikilik (binary) seviyede ve 8 bit sınırıyla yapılır. Sonuç 8 bittir. Taşma olursa taşma biti kaybolur.
	s0 <= s0_i + s1_i;
	-- Buradaki + işareti ve aşağıdaki karşılaştırma operatörleri STD_LOGIC_ARITH bu paketten geldiği için sorun oluşmaz. 
	
	process(s0) begin
        if (s0 > 20) then
            s_o <= '1';
        else
            s_o <= '0';
        end if;
    end process;


end Behavioral;
