----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.04.2025 11:36:18
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


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity and2 is
-- Giriş çıkış sinyalleri entity in port tanımı içine yazılır
    Port ( in1_i : in STD_LOGIC;
           in2_i : in STD_LOGIC;
           and_out_o : out STD_LOGIC);
end and2;

architecture Behavioral of and2 is
-- Buraya sinyal tanımları vs yazılıyor

begin
-- Begin ve end arasına fonksiyonlarımız yazacağız
and_out_o	<= in1_i and in2_i;


end Behavioral;
