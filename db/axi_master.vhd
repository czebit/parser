library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_signed.all;
use IEEE.std_logic_unsigned.all;

entity axi_st_master is 

generic(
	BUS_WIDTH : natural
	);
	
	port(
		TDATA		: out STD_LOGIC_VECTOR(BUS_WIDTH*8-1 downto 0);
		TVALID	: out STD_LOGIC;
		TLAST		: out STD_LOGIC;
		TSTRB		: out STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
		TKEEP		: out STD_LOGIC_VECTOR(BUS_WIDTH-1 downto 0);
		TREADY	: in STD_LOGIC;
		ARESETn	: in STD_LOGIC;
		ACLK		: in STD_LOGIC
		);
		
end axi_st_master;

		