library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity parser_top is
	generic(BUS_WIDTH : natural := 8);
		
	Port(	CLK		: in STD_LOGIC;
			RESETn	: in STD_LOGIC;
			INPUT		: in STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0));
end parser_top;

architecture rtl of parser_top is

begin

end rtl;