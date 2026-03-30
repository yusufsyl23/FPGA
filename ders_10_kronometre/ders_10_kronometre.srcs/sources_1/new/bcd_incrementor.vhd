library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity bcd_incrementor is
	generic (
		birlerlim 	: integer := 9;
		onlarlim 	: integer := 5
	);
	
	port (
		clk 		: in STD_LOGIC;
		increment_i : in STD_LOGIC;
		reset_i		: in STD_LOGIC;
		birler_o	: out STD_LOGIC_VECTOR (3 downto 0);
		onlar_o		: out STD_LOGIC_VECTOR (3 downto 0)
	);
end bcd_incrementor;

architecture Behavioral of bcd_incrementor is
	
	-- birler ve onlar aslında output. Output oldukları için bir yerde doğrudan kullanılamaz o yüzden burda bir sinyal (register) oluşturduk.
	-- Daha sonra en sonda bu sinyalleri output ile eşitledik
	signal birler : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');
	signal onlar  : STD_LOGIC_VECTOR (3 downto 0) := (others => '0');

begin

	process (clk) begin
		if (rising_edge(clk)) then
		
			if (increment_i = '1') then
				if (birler = birlerlim) then
					if (onlar = onlarlim) then
						birler <= x"0";
						onlar  <= x"0";
					else
						birler <= x"0";
						onlar  <= onlar + 1;
						
					end if;
				
				else
					birler <= birler + 1;
					
				end if;
			end if;
			
		if (reset_i = '1') then
			birler <= x"0";
			onlar  <= x"0";
		
		end if;
		end if;
	end process;
	
	birler_o <= birler;
	onlar_o  <= onlar;


end Behavioral;
