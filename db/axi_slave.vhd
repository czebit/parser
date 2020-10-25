library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity axi_st_slave is 

generic(	BUS_WIDTH : natural := 8);
	
	port(	TDATA		: in STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
			TVALID	: in STD_LOGIC;
			TLAST		: in STD_LOGIC;
			TSTRB		: in STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			TKEEP		: in STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
			TREADY	: out STD_LOGIC;
			ARESETn	: in STD_LOGIC;
			ACLK		: in STD_LOGIC;
			INT_OUT	: out STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0));
		
end axi_st_slave;


architecture rtl of axi_st_slave is

begin

end rtl;

		